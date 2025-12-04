#!/bin/bash
# Forensic Timeline Builder
# Creates unified timeline from multiple log sources

VERSION="1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_usage() {
    cat << EOF
Forensic Timeline Builder v${VERSION}

Creates unified timelines from multiple log sources for incident investigation.

Usage:
    $0 --start "YYYY-MM-DD HH:MM" --end "YYYY-MM-DD HH:MM"
    $0 --last-hours <hours>
    $0 --files <file1> <file2> ...

Options:
    -s, --start <datetime>      Start time (YYYY-MM-DD HH:MM:SS)
    -e, --end <datetime>        End time (YYYY-MM-DD HH:MM:SS)
    -l, --last-hours <hours>    Last N hours
    -f, --files <files>         Additional log files to include
    -o, --output <file>         Output file (default: timeline_YYYYMMDD_HHMMSS.txt)
    -F, --format <format>       Output format: text, csv, json (default: text)
    -v, --verbose               Verbose output
    --include-system            Include system logs
    --include-auth              Include authentication logs
    --include-web               Include web server logs
    --include-network           Include network logs
    --all                       Include all available logs
    --help                      Show this help

Examples:
    # Last 24 hours, all logs
    $0 --last-hours 24 --all

    # Specific time range
    $0 --start "2025-12-04 00:00" --end "2025-12-04 23:59" --all

    # Custom files only
    $0 --files /var/log/custom.log /tmp/app.log

    # Export to CSV
    $0 --last-hours 12 --all --format csv

Output: Unified timeline sorted chronologically with source attribution
EOF
}

# Parse timestamp from different log formats
parse_timestamp() {
    local line="$1"
    local source="$2"

    # Try different date formats
    case "$source" in
        auth|syslog)
            # Format: Dec  4 05:42:52
            echo "$line" | grep -oE '[A-Z][a-z]{2}\s+[0-9]{1,2}\s+[0-9]{2}:[0-9]{2}:[0-9]{2}'
            ;;
        apache|nginx)
            # Format: [04/Dec/2025:05:42:52 +0000]
            echo "$line" | grep -oE '\[[0-9]{2}/[A-Z][a-z]{2}/[0-9]{4}:[0-9]{2}:[0-9]{2}:[0-9]{2}[^\]]*\]' | tr -d '[]'
            ;;
        iso)
            # Format: 2025-12-04T05:42:52
            echo "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}:[0-9]{2}'
            ;;
        *)
            # Try to extract any timestamp
            echo "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}:[0-9]{2}|[A-Z][a-z]{2}\s+[0-9]{1,2}\s+[0-9]{2}:[0-9]{2}:[0-9]{2}'
            ;;
    esac
}

# Normalize timestamp to sortable format
normalize_timestamp() {
    local ts="$1"
    local year=$(date +%Y)

    # Convert various formats to ISO format for sorting
    if [[ "$ts" =~ ^[A-Z][a-z]{2} ]]; then
        # Syslog format: Dec 4 05:42:52
        date -d "$year $ts" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -j -f "%Y %b %d %H:%M:%S" "$year $ts" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$ts"
    elif [[ "$ts" =~ / ]]; then
        # Apache format: 04/Dec/2025:05:42:52 +0000
        local clean_ts=$(echo "$ts" | sed 's/\// /g' | sed 's/:/ /' | awk '{print $3"-"$2"-"$1" "$4}')
        date -d "$clean_ts" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$ts"
    else
        # ISO format: 2025-12-04T05:42:52 or 2025-12-04 05:42:52
        echo "$ts" | tr 'T' ' '
    fi
}

# Process log file
process_log_file() {
    local file="$1"
    local source="$2"
    local start_ts="$3"
    local end_ts="$4"
    local temp_file="$5"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local line_count=0

    while IFS= read -r line; do
        # Skip empty lines
        [ -z "$line" ] && continue

        # Extract timestamp
        local ts=$(parse_timestamp "$line" "$source")
        [ -z "$ts" ] && continue

        # Normalize timestamp
        local norm_ts=$(normalize_timestamp "$ts")
        [ -z "$norm_ts" ] && continue

        # Filter by time range if specified
        if [ -n "$start_ts" ] && [[ "$norm_ts" < "$start_ts" ]]; then
            continue
        fi
        if [ -n "$end_ts" ] && [[ "$norm_ts" > "$end_ts" ]]; then
            continue
        fi

        # Write to temp file: timestamp|source|original_line
        echo "$norm_ts|$source|$line" >> "$temp_file"
        line_count=$((line_count + 1))

    done < "$file"

    return 0
}

# Build timeline
build_timeline() {
    local start_time="$1"
    local end_time="$2"
    local output_file="$3"
    local format="$4"
    local include_flags="$5"
    local custom_files="$6"
    local verbose="$7"

    echo "═══════════════════════════════════════════════════════"
    echo "Forensic Timeline Builder"
    echo "═══════════════════════════════════════════════════════"
    if [ -n "$start_time" ]; then
        echo "Start time: $start_time"
    fi
    if [ -n "$end_time" ]; then
        echo "End time: $end_time"
    fi
    echo "Output: $output_file"
    echo "Format: $format"
    echo "═══════════════════════════════════════════════════════"
    echo

    # Create temporary file for collecting events
    local temp_file=$(mktemp)
    trap "rm -f $temp_file" EXIT

    local sources_processed=0

    # Process system logs
    if [[ "$include_flags" =~ "system" ]]; then
        if [ "$verbose" = "true" ]; then
            echo "[*] Processing system logs..."
        fi
        if [ -f /var/log/syslog ]; then
            process_log_file "/var/log/syslog" "syslog" "$start_time" "$end_time" "$temp_file"
            sources_processed=$((sources_processed + 1))
        fi
        if [ -f /var/log/messages ]; then
            process_log_file "/var/log/messages" "messages" "$start_time" "$end_time" "$temp_file"
            sources_processed=$((sources_processed + 1))
        fi
    fi

    # Process auth logs
    if [[ "$include_flags" =~ "auth" ]]; then
        if [ "$verbose" = "true" ]; then
            echo "[*] Processing authentication logs..."
        fi
        if [ -f /var/log/auth.log ]; then
            process_log_file "/var/log/auth.log" "auth" "$start_time" "$end_time" "$temp_file"
            sources_processed=$((sources_processed + 1))
        fi
        if [ -f /var/log/secure ]; then
            process_log_file "/var/log/secure" "secure" "$start_time" "$end_time" "$temp_file"
            sources_processed=$((sources_processed + 1))
        fi
    fi

    # Process web logs
    if [[ "$include_flags" =~ "web" ]]; then
        if [ "$verbose" = "true" ]; then
            echo "[*] Processing web server logs..."
        fi
        for log in /var/log/apache2/*.log /var/log/httpd/*.log /var/log/nginx/*.log; do
            if [ -f "$log" ]; then
                process_log_file "$log" "web" "$start_time" "$end_time" "$temp_file"
                sources_processed=$((sources_processed + 1))
            fi
        done
    fi

    # Process network logs
    if [[ "$include_flags" =~ "network" ]]; then
        if [ "$verbose" = "true" ]; then
            echo "[*] Processing network logs..."
        fi
        if [ -f /var/log/firewall.log ]; then
            process_log_file "/var/log/firewall.log" "firewall" "$start_time" "$end_time" "$temp_file"
            sources_processed=$((sources_processed + 1))
        fi
    fi

    # Process custom files
    if [ -n "$custom_files" ]; then
        if [ "$verbose" = "true" ]; then
            echo "[*] Processing custom log files..."
        fi
        for file in $custom_files; do
            if [ -f "$file" ]; then
                local source_name=$(basename "$file")
                process_log_file "$file" "$source_name" "$start_time" "$end_time" "$temp_file"
                sources_processed=$((sources_processed + 1))
            fi
        done
    fi

    if [ "$sources_processed" -eq 0 ]; then
        echo -e "${RED}Error: No log sources could be processed${NC}" >&2
        return 1
    fi

    # Sort timeline by timestamp
    if [ "$verbose" = "true" ]; then
        echo "[*] Sorting timeline chronologically..."
    fi

    local event_count=$(wc -l < "$temp_file")

    # Generate output based on format
    case "$format" in
        csv)
            echo "Timestamp,Source,Event" > "$output_file"
            sort "$temp_file" | while IFS='|' read -r ts source event; do
                # Escape commas in event
                event_escaped=$(echo "$event" | sed 's/"/""/g')
                echo "\"$ts\",\"$source\",\"$event_escaped\"" >> "$output_file"
            done
            ;;

        json)
            echo "[" > "$output_file"
            local first=true
            sort "$temp_file" | while IFS='|' read -r ts source event; do
                if [ "$first" = true ]; then
                    first=false
                else
                    echo "," >> "$output_file"
                fi
                # Escape JSON special characters
                event_escaped=$(echo "$event" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
                echo "  {\"timestamp\":\"$ts\",\"source\":\"$source\",\"event\":\"$event_escaped\"}" >> "$output_file"
            done
            echo "]" >> "$output_file"
            ;;

        text|*)
            {
                echo "═══════════════════════════════════════════════════════"
                echo "FORENSIC TIMELINE"
                echo "═══════════════════════════════════════════════════════"
                echo "Generated: $(date)"
                echo "Events: $event_count"
                echo "Sources: $sources_processed"
                if [ -n "$start_time" ]; then
                    echo "Time range: $start_time to $end_time"
                fi
                echo "═══════════════════════════════════════════════════════"
                echo

                sort "$temp_file" | while IFS='|' read -r ts source event; do
                    printf "[%s] %-12s %s\n" "$ts" "[$source]" "$event"
                done

                echo
                echo "═══════════════════════════════════════════════════════"
                echo "End of Timeline"
                echo "═══════════════════════════════════════════════════════"
            } > "$output_file"
            ;;
    esac

    echo
    echo -e "${GREEN}✓ Timeline created successfully${NC}"
    echo "Output file: $output_file"
    echo "Total events: $event_count"
    echo "Sources processed: $sources_processed"
    echo

    # Show statistics
    echo "Event breakdown by source:"
    sort "$temp_file" | cut -d'|' -f2 | sort | uniq -c | while read count source; do
        printf "  %-15s %d events\n" "$source:" "$count"
    done

    return 0
}

# Parse arguments
START_TIME=""
END_TIME=""
LAST_HOURS=""
CUSTOM_FILES=""
OUTPUT_FILE=""
FORMAT="text"
VERBOSE="false"
INCLUDE_FLAGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--start)
            START_TIME="$2"
            shift 2
            ;;
        -e|--end)
            END_TIME="$2"
            shift 2
            ;;
        -l|--last-hours)
            LAST_HOURS="$2"
            shift 2
            ;;
        -f|--files)
            shift
            while [[ $# -gt 0 ]] && [[ ! "$1" =~ ^- ]]; do
                CUSTOM_FILES="$CUSTOM_FILES $1"
                shift
            done
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -F|--format)
            FORMAT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        --include-system)
            INCLUDE_FLAGS="${INCLUDE_FLAGS}system "
            shift
            ;;
        --include-auth)
            INCLUDE_FLAGS="${INCLUDE_FLAGS}auth "
            shift
            ;;
        --include-web)
            INCLUDE_FLAGS="${INCLUDE_FLAGS}web "
            shift
            ;;
        --include-network)
            INCLUDE_FLAGS="${INCLUDE_FLAGS}network "
            shift
            ;;
        --all)
            INCLUDE_FLAGS="system auth web network"
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Calculate time range from --last-hours
if [ -n "$LAST_HOURS" ]; then
    END_TIME=$(date "+%Y-%m-%d %H:%M:%S")
    START_TIME=$(date -d "$LAST_HOURS hours ago" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -v-${LAST_HOURS}H "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
fi

# Default output file
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="timeline_$(date +%Y%m%d_%H%M%S).$FORMAT"
    if [ "$FORMAT" = "text" ]; then
        OUTPUT_FILE="timeline_$(date +%Y%m%d_%H%M%S).txt"
    fi
fi

# Default to all logs if nothing specified
if [ -z "$INCLUDE_FLAGS" ] && [ -z "$CUSTOM_FILES" ]; then
    INCLUDE_FLAGS="system auth"
fi

# Build timeline
build_timeline "$START_TIME" "$END_TIME" "$OUTPUT_FILE" "$FORMAT" "$INCLUDE_FLAGS" "$CUSTOM_FILES" "$VERBOSE"
