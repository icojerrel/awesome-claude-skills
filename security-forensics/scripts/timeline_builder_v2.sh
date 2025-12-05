#!/bin/bash
# Enhanced Forensic Timeline Builder v2.0
# Now with automatic gap detection and corruption marker scanning

VERSION="2.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
GAP_THRESHOLD=1800  # 30 minutes in seconds
CORRUPTION_KEYWORDS="corrupt|corrupted|missing|deleted|malfunction|unrecoverable|data loss|entries deleted|file not found"

show_usage() {
    cat << EOF
Enhanced Forensic Timeline Builder v${VERSION}

NEW FEATURES:
✓ Automatic gap detection (>30 min)
✓ Corruption marker scanning
✓ Evidence quality scoring
✓ Anomaly highlighting

Usage:
    $0 --files <file1> <file2> ... --output <output>

Options:
    -f, --files <files>         Log files to process
    -o, --output <file>         Output file
    -F, --format <format>       Format: text, csv (default: text)
    -g, --gap-threshold <mins>  Gap threshold in minutes (default: 30)
    --detect-gaps               Enable gap detection (default: ON)
    --detect-corruption         Scan for corruption markers (default: ON)
    --quality-score             Calculate evidence quality score
    --help                      Show this help

Examples:
    $0 --files auth.log syslog --output timeline.txt
    $0 --files *.log --output timeline.txt --quality-score
EOF
}

# Parse arguments
FILES=()
OUTPUT=""
FORMAT="text"
GAP_DETECTION=true
CORRUPTION_DETECTION=true
QUALITY_SCORE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--files)
            shift
            while [[ $# -gt 0 ]] && [[ ! "$1" =~ ^- ]]; do
                FILES+=("$1")
                shift
            done
            ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -F|--format) FORMAT="$2"; shift 2 ;;
        -g|--gap-threshold) GAP_THRESHOLD=$((${2} * 60)); shift 2 ;;
        --detect-gaps) GAP_DETECTION=true; shift ;;
        --detect-corruption) CORRUPTION_DETECTION=true; shift ;;
        --quality-score) QUALITY_SCORE=true; shift ;;
        --help) show_usage; exit 0 ;;
        *) echo "Unknown option: $1"; show_usage; exit 1 ;;
    esac
done

if [ ${#FILES[@]} -eq 0 ] || [ -z "$OUTPUT" ]; then
    echo "Error: --files and --output are required"
    show_usage
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "Enhanced Forensic Timeline Builder v${VERSION}"
echo "═══════════════════════════════════════════════════════"
echo "Files: ${#FILES[@]}"
echo "Output: $OUTPUT"
echo "Gap Detection: $GAP_DETECTION (threshold: $((GAP_THRESHOLD / 60)) minutes)"
echo "Corruption Detection: $CORRUPTION_DETECTION"
echo "═══════════════════════════════════════════════════════"
echo

# Temporary files
TEMP_TIMELINE=$(mktemp)
TEMP_SORTED=$(mktemp)
CORRUPTION_LOG=$(mktemp)
GAP_LOG=$(mktemp)

# Statistics
total_events=0
corruption_count=0
gap_count=0
declare -A source_counts

# Process each file
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}⚠ File not found: $file${NC}"
        continue
    fi

    echo "[*] Processing: $(basename "$file")"

    # Scan for corruption markers
    if [ "$CORRUPTION_DETECTION" = true ]; then
        if grep -i -E "$CORRUPTION_KEYWORDS" "$file" > /dev/null 2>&1; then
            echo -e "${RED}  ⚠ CORRUPTION MARKERS DETECTED${NC}"
            grep -i -n -E "$CORRUPTION_KEYWORDS" "$file" >> "$CORRUPTION_LOG"
            corruption_count=$((corruption_count + 1))
        fi
    fi

    # Extract events with timestamps
    local count=0
    while IFS= read -r line; do
        # Try to extract timestamp (multiple formats)
        if [[ "$line" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
            timestamp="${BASH_REMATCH[1]}"
            timestamp=$(echo "$timestamp" | tr 'T' ' ')
            echo "$timestamp|$(basename "$file")|$line" >> "$TEMP_TIMELINE"
            count=$((count + 1))
            total_events=$((total_events + 1))
        fi
    done < "$file"

    source_counts["$(basename "$file")"]=$count
    echo "  Events extracted: $count"
done

echo

# Sort timeline chronologically
sort "$TEMP_TIMELINE" > "$TEMP_SORTED"

# Detect gaps
if [ "$GAP_DETECTION" = true ] && [ -s "$TEMP_SORTED" ]; then
    echo "[*] Analyzing timeline for gaps..."

    prev_timestamp=""
    prev_line=""

    while IFS='|' read -r timestamp source line; do
        if [ -n "$prev_timestamp" ]; then
            # Calculate time difference
            prev_epoch=$(date -d "$prev_timestamp" +%s 2>/dev/null || echo 0)
            curr_epoch=$(date -d "$timestamp" +%s 2>/dev/null || echo 0)

            if [ $prev_epoch -gt 0 ] && [ $curr_epoch -gt 0 ]; then
                diff=$((curr_epoch - prev_epoch))

                if [ $diff -gt $GAP_THRESHOLD ]; then
                    gap_minutes=$((diff / 60))
                    echo "GAP|$prev_timestamp|$timestamp|$gap_minutes minutes" >> "$GAP_LOG"
                    gap_count=$((gap_count + 1))
                fi
            fi
        fi

        prev_timestamp="$timestamp"
        prev_line="$line"
    done < "$TEMP_SORTED"

    if [ $gap_count -gt 0 ]; then
        echo -e "${YELLOW}  ⚠ $gap_count timeline gap(s) detected (>${GAP_THRESHOLD}s)${NC}"
    else
        echo -e "${GREEN}  ✓ No significant gaps detected${NC}"
    fi
fi

echo

# Generate output
echo "[*] Generating timeline..."

{
    echo "═══════════════════════════════════════════════════════"
    echo "FORENSIC TIMELINE - ENHANCED"
    echo "═══════════════════════════════════════════════════════"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Events: $total_events"
    echo "Sources: ${#source_counts[@]}"
    echo "═══════════════════════════════════════════════════════"
    echo

    # Show corruption warnings if any
    if [ $corruption_count -gt 0 ]; then
        echo -e "${RED}⚠ CORRUPTION WARNINGS: $corruption_count file(s)${NC}"
        echo "═══════════════════════════════════════════════════════"
        while IFS= read -r line; do
            echo "⚠ $line"
        done < "$CORRUPTION_LOG"
        echo "═══════════════════════════════════════════════════════"
        echo
    fi

    # Show gaps if any
    if [ $gap_count -gt 0 ]; then
        echo -e "${YELLOW}⚠ TIMELINE GAPS DETECTED: $gap_count${NC}"
        echo "═══════════════════════════════════════════════════════"
        while IFS='|' read -r type start end duration; do
            echo "⚠ GAP: $start → $end ($duration)"
        done < "$GAP_LOG"
        echo "═══════════════════════════════════════════════════════"
        echo
    fi

    # Timeline events
    prev_timestamp=""
    while IFS='|' read -r timestamp source line; do
        # Check if there's a gap before this event
        if [ -n "$prev_timestamp" ] && [ $gap_count -gt 0 ]; then
            prev_epoch=$(date -d "$prev_timestamp" +%s 2>/dev/null || echo 0)
            curr_epoch=$(date -d "$timestamp" +%s 2>/dev/null || echo 0)
            diff=$((curr_epoch - prev_epoch))

            if [ $diff -gt $GAP_THRESHOLD ]; then
                gap_minutes=$((diff / 60))
                echo -e "${RED}         ❌ TIMELINE GAP: $gap_minutes minutes${NC}"
            fi
        fi

        echo "[$timestamp] [$source] $line"
        prev_timestamp="$timestamp"
    done < "$TEMP_SORTED"

    echo
    echo "═══════════════════════════════════════════════════════"
    echo "Event breakdown by source:"
    for source in "${!source_counts[@]}"; do
        printf "  %-30s %d events\n" "$source:" "${source_counts[$source]}"
    done
    echo "═══════════════════════════════════════════════════════"

    # Quality score
    if [ "$QUALITY_SCORE" = true ]; then
        echo
        echo "EVIDENCE QUALITY ASSESSMENT"
        echo "═══════════════════════════════════════════════════════"

        # Calculate score
        score=100

        # Deduct for gaps (10 points per gap, max 50)
        gap_penalty=$((gap_count * 10))
        [ $gap_penalty -gt 50 ] && gap_penalty=50
        score=$((score - gap_penalty))

        # Deduct for corruption (20 points per file, max 40)
        corruption_penalty=$((corruption_count * 20))
        [ $corruption_penalty -gt 40 ] && corruption_penalty=40
        score=$((score - corruption_penalty))

        # Minimum score
        [ $score -lt 0 ] && score=0

        echo "Timeline Gaps:        $gap_count (penalty: -$gap_penalty points)"
        echo "Corruption Markers:   $corruption_count (penalty: -$corruption_penalty points)"
        echo
        echo -n "QUALITY SCORE: $score/100 - "

        if [ $score -ge 90 ]; then
            echo -e "${GREEN}EXCELLENT${NC}"
            echo "Assessment: Evidence is complete and reliable"
        elif [ $score -ge 70 ]; then
            echo -e "${GREEN}GOOD${NC}"
            echo "Assessment: Evidence is acceptable with minor caveats"
        elif [ $score -ge 50 ]; then
            echo -e "${YELLOW}FAIR${NC}"
            echo "Assessment: Evidence has gaps but may be usable"
        elif [ $score -ge 30 ]; then
            echo -e "${YELLOW}POOR${NC}"
            echo "Assessment: Evidence has significant issues"
        else
            echo -e "${RED}CRITICAL${NC}"
            echo "Assessment: Evidence severely compromised"
        fi

        echo
        echo "Court Admissibility: "
        if [ $score -ge 70 ]; then
            echo -e "  ${GREEN}LIKELY - Evidence appears sound${NC}"
        elif [ $score -ge 50 ]; then
            echo -e "  ${YELLOW}POSSIBLE - Note limitations in report${NC}"
        else
            echo -e "  ${RED}QUESTIONABLE - Seek additional evidence${NC}"
        fi
        echo "═══════════════════════════════════════════════════════"
    fi

    echo
    echo "End of Timeline"
    echo "═══════════════════════════════════════════════════════"

} > "$OUTPUT"

# Cleanup
rm -f "$TEMP_TIMELINE" "$TEMP_SORTED" "$CORRUPTION_LOG" "$GAP_LOG"

echo -e "${GREEN}✓ Timeline created successfully${NC}"
echo "Output file: $OUTPUT"
echo "Total events: $total_events"
echo "Sources processed: ${#source_counts[@]}"

if [ $gap_count -gt 0 ] || [ $corruption_count -gt 0 ]; then
    echo
    echo -e "${YELLOW}⚠ QUALITY ISSUES DETECTED:${NC}"
    [ $gap_count -gt 0 ] && echo "  - Timeline gaps: $gap_count"
    [ $corruption_count -gt 0 ] && echo "  - Corruption markers: $corruption_count"
    echo
    echo "Review output file for details and consider:"
    echo "  1. Searching for backup/alternative log sources"
    echo "  2. Attempting data recovery if corruption is present"
    echo "  3. Documenting gaps in legal proceedings"
fi

echo
