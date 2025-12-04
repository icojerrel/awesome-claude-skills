#!/bin/bash
# VirusTotal API Lookup Script
# Checks file hashes against VirusTotal database

VERSION="1.0"
VT_API_URL="https://www.virustotal.com/api/v3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_usage() {
    cat << EOF
VirusTotal Lookup Script v${VERSION}

Usage:
    $0 --hash <hash>              # Lookup single hash
    $0 --file <file>              # Calculate hash and lookup file
    $0 --batch <hash_file>        # Lookup multiple hashes from file
    $0 --api-key <key>            # Set API key (saved to ~/.vt_api_key)

Options:
    -h, --hash      File hash (MD5, SHA1, or SHA256)
    -f, --file      File to analyze (hash calculated automatically)
    -b, --batch     File containing list of hashes (one per line)
    -k, --api-key   VirusTotal API key
    -o, --output    Output file (JSON format)
    -v, --verbose   Verbose output
    --help          Show this help message

Examples:
    # Lookup single hash
    $0 --hash d41d8cd98f00b204e9800998ecf8427e

    # Analyze file
    $0 --file suspicious.exe

    # Batch lookup
    $0 --batch hashes.txt

    # Set API key
    $0 --api-key YOUR_API_KEY_HERE

Note: Get free API key at https://www.virustotal.com/gui/join-us
      Free tier: 4 requests/minute, 500 requests/day
EOF
}

get_api_key() {
    if [ -n "$VT_API_KEY" ]; then
        echo "$VT_API_KEY"
    elif [ -f ~/.vt_api_key ]; then
        cat ~/.vt_api_key
    else
        echo ""
    fi
}

save_api_key() {
    echo "$1" > ~/.vt_api_key
    chmod 600 ~/.vt_api_key
    echo -e "${GREEN}✓ API key saved to ~/.vt_api_key${NC}"
}

calculate_hash() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File not found: $file${NC}" >&2
        return 1
    fi
    sha256sum "$file" | cut -d' ' -f1
}

vt_lookup() {
    local hash="$1"
    local api_key="$2"
    local output_file="$3"
    local verbose="$4"

    if [ -z "$api_key" ]; then
        echo -e "${RED}Error: No API key found${NC}" >&2
        echo "Set API key with: $0 --api-key YOUR_KEY" >&2
        return 1
    fi

    if [ "$verbose" = "true" ]; then
        echo -e "${BLUE}[*] Querying VirusTotal for hash: $hash${NC}"
    fi

    # Query VirusTotal API
    local response=$(curl -s --request GET \
        --url "${VT_API_URL}/files/${hash}" \
        --header "x-apikey: ${api_key}")

    # Check for errors
    if echo "$response" | grep -q '"error"'; then
        local error_code=$(echo "$response" | grep -o '"code":"[^"]*"' | cut -d'"' -f4)
        if [ "$error_code" = "NotFoundError" ]; then
            echo -e "${YELLOW}⚠ Hash not found in VirusTotal database${NC}"
            echo "Hash: $hash"
            echo "Status: Unknown (not previously scanned)"
            return 0
        else
            echo -e "${RED}Error: API request failed${NC}" >&2
            echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4 >&2
            return 1
        fi
    fi

    # Parse response
    local malicious=$(echo "$response" | grep -o '"malicious":[0-9]*' | cut -d':' -f2)
    local suspicious=$(echo "$response" | grep -o '"suspicious":[0-9]*' | cut -d':' -f2)
    local undetected=$(echo "$response" | grep -o '"undetected":[0-9]*' | cut -d':' -f2)
    local total=$((malicious + suspicious + undetected))

    local first_seen=$(echo "$response" | grep -o '"first_submission_date":[0-9]*' | cut -d':' -f2)
    local last_seen=$(echo "$response" | grep -o '"last_analysis_date":[0-9]*' | cut -d':' -f2)
    local reputation=$(echo "$response" | grep -o '"reputation":-?[0-9]*' | cut -d':' -f2)

    # Popular names
    local popular_name=$(echo "$response" | grep -o '"popular_threat_classification":{"suggested_threat_label":"[^"]*"' | cut -d'"' -f4)

    # Save JSON if output file specified
    if [ -n "$output_file" ]; then
        echo "$response" > "$output_file"
        echo -e "${GREEN}✓ Full JSON saved to: $output_file${NC}"
    fi

    # Display results
    echo "═══════════════════════════════════════════════════════"
    echo "VirusTotal Analysis Report"
    echo "═══════════════════════════════════════════════════════"
    echo "Hash: $hash"
    echo

    # Detection ratio
    if [ "$malicious" -gt 0 ]; then
        echo -e "${RED}⚠ MALICIOUS DETECTED${NC}"
        echo -e "Detection: ${RED}${malicious}/${total}${NC} engines flagged as malicious"
    elif [ "$suspicious" -gt 0 ]; then
        echo -e "${YELLOW}⚠ SUSPICIOUS${NC}"
        echo -e "Detection: ${YELLOW}${suspicious}/${total}${NC} engines flagged as suspicious"
    else
        echo -e "${GREEN}✓ CLEAN${NC}"
        echo -e "Detection: ${GREEN}0/${total}${NC} engines detected threats"
    fi

    if [ "$suspicious" -gt 0 ]; then
        echo "Suspicious: ${suspicious}/${total} engines"
    fi
    echo "Undetected: ${undetected}/${total} engines"
    echo

    # Threat classification
    if [ -n "$popular_name" ] && [ "$popular_name" != "null" ]; then
        echo "Classification: $popular_name"
        echo
    fi

    # Timestamps
    if [ -n "$first_seen" ] && [ "$first_seen" != "null" ]; then
        echo "First seen: $(date -d @${first_seen} 2>/dev/null || date -r ${first_seen} 2>/dev/null || echo $first_seen)"
    fi
    if [ -n "$last_seen" ] && [ "$last_seen" != "null" ]; then
        echo "Last analysis: $(date -d @${last_seen} 2>/dev/null || date -r ${last_seen} 2>/dev/null || echo $last_seen)"
    fi

    # Community reputation
    if [ -n "$reputation" ] && [ "$reputation" != "null" ]; then
        echo "Community reputation: $reputation"
    fi

    echo "═══════════════════════════════════════════════════════"
    echo
    echo "View full report: https://www.virustotal.com/gui/file/${hash}"
    echo

    # Return non-zero if malicious
    if [ "$malicious" -gt 0 ]; then
        return 2
    fi
    return 0
}

# Parse arguments
HASH=""
FILE=""
BATCH_FILE=""
API_KEY_SET=""
OUTPUT_FILE=""
VERBOSE="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--hash)
            HASH="$2"
            shift 2
            ;;
        -f|--file)
            FILE="$2"
            shift 2
            ;;
        -b|--batch)
            BATCH_FILE="$2"
            shift 2
            ;;
        -k|--api-key)
            API_KEY_SET="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="true"
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

# Handle API key setting
if [ -n "$API_KEY_SET" ]; then
    save_api_key "$API_KEY_SET"
    exit 0
fi

# Get API key
VT_API_KEY=$(get_api_key)

if [ -z "$VT_API_KEY" ]; then
    echo -e "${RED}Error: No VirusTotal API key found${NC}" >&2
    echo "Get a free API key at: https://www.virustotal.com/gui/join-us" >&2
    echo "Then set it with: $0 --api-key YOUR_KEY" >&2
    exit 1
fi

# Process based on mode
if [ -n "$FILE" ]; then
    # Single file mode
    echo "Calculating hash for: $FILE"
    HASH=$(calculate_hash "$FILE") || exit 1
    echo "SHA256: $HASH"
    echo
    vt_lookup "$HASH" "$VT_API_KEY" "$OUTPUT_FILE" "$VERBOSE"

elif [ -n "$BATCH_FILE" ]; then
    # Batch mode
    if [ ! -f "$BATCH_FILE" ]; then
        echo -e "${RED}Error: Batch file not found: $BATCH_FILE${NC}" >&2
        exit 1
    fi

    echo "Processing batch file: $BATCH_FILE"
    echo

    MALICIOUS_COUNT=0
    CLEAN_COUNT=0
    UNKNOWN_COUNT=0
    LINE_NUM=0

    while IFS= read -r hash; do
        # Skip empty lines and comments
        [[ -z "$hash" || "$hash" =~ ^# ]] && continue

        LINE_NUM=$((LINE_NUM + 1))
        echo "─────────────────────────────────────────────────────"
        echo "[$LINE_NUM] Processing hash: $hash"
        echo

        vt_lookup "$hash" "$VT_API_KEY" "" "$VERBOSE"
        EXIT_CODE=$?

        if [ $EXIT_CODE -eq 2 ]; then
            MALICIOUS_COUNT=$((MALICIOUS_COUNT + 1))
        elif [ $EXIT_CODE -eq 0 ]; then
            if grep -q "not found" <<< "$(vt_lookup "$hash" "$VT_API_KEY" "" "false" 2>&1)"; then
                UNKNOWN_COUNT=$((UNKNOWN_COUNT + 1))
            else
                CLEAN_COUNT=$((CLEAN_COUNT + 1))
            fi
        fi

        # Rate limiting: 4 requests per minute for free tier
        if [ $LINE_NUM -lt $(wc -l < "$BATCH_FILE") ]; then
            echo "Waiting 15 seconds (API rate limit)..."
            sleep 15
        fi
    done < "$BATCH_FILE"

    echo "═══════════════════════════════════════════════════════"
    echo "Batch Scan Summary"
    echo "═══════════════════════════════════════════════════════"
    echo -e "${RED}Malicious: $MALICIOUS_COUNT${NC}"
    echo -e "${GREEN}Clean: $CLEAN_COUNT${NC}"
    echo -e "${YELLOW}Unknown: $UNKNOWN_COUNT${NC}"
    echo "Total scanned: $LINE_NUM"
    echo "═══════════════════════════════════════════════════════"

elif [ -n "$HASH" ]; then
    # Single hash mode
    vt_lookup "$HASH" "$VT_API_KEY" "$OUTPUT_FILE" "$VERBOSE"

else
    echo -e "${RED}Error: No hash, file, or batch file specified${NC}" >&2
    show_usage
    exit 1
fi
