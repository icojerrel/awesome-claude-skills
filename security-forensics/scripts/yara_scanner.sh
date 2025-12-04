#!/bin/bash
# YARA Rules Scanner
# Scans files for malware patterns using YARA rules

VERSION="1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_usage() {
    cat << EOF
YARA Scanner v${VERSION}

Usage:
    $0 --file <file> --rules <rule_file>          # Scan single file
    $0 --dir <directory> --rules <rule_file>      # Scan directory
    $0 --rules <rule_file>                        # Scan current directory
    $0 --install-rules                            # Download common rule sets

Options:
    -f, --file <file>           File to scan
    -d, --dir <directory>       Directory to scan (recursive)
    -r, --rules <rule_file>     YARA rules file or directory
    -o, --output <file>         Output file for matches
    -v, --verbose               Verbose output
    --fast                      Fast scan (skip large files)
    --install-rules             Download popular YARA rule sets
    --list-rules                List available rules
    --help                      Show this help

Examples:
    # Scan single file
    $0 --file suspicious.exe --rules malware.yar

    # Scan directory
    $0 --dir /tmp --rules ~/.yara/rules/

    # Install common rules
    $0 --install-rules

    # Scan with verbose output
    $0 --file malware.bin --rules all_rules.yar --verbose

Note: YARA must be installed: apt-get install yara / brew install yara
EOF
}

check_yara() {
    if ! command -v yara &> /dev/null; then
        echo -e "${RED}Error: YARA is not installed${NC}" >&2
        echo "Install with:" >&2
        echo "  Ubuntu/Debian: sudo apt-get install yara" >&2
        echo "  macOS: brew install yara" >&2
        echo "  From source: https://github.com/VirusTotal/yara" >&2
        return 1
    fi
    return 0
}

install_rules() {
    local rules_dir="$HOME/.yara/rules"

    echo "═══════════════════════════════════════════════════════"
    echo "YARA Rules Installation"
    echo "═══════════════════════════════════════════════════════"
    echo

    mkdir -p "$rules_dir"
    cd "$rules_dir" || exit 1

    echo "Installing popular YARA rule sets..."
    echo

    # 1. YARA-Rules (community collection)
    echo "[1/3] Downloading YARA-Rules repository..."
    if [ -d "yara-rules" ]; then
        echo "  → Updating existing repository..."
        cd yara-rules && git pull && cd ..
    else
        git clone --depth 1 https://github.com/Yara-Rules/rules.git yara-rules
    fi
    echo -e "${GREEN}✓ YARA-Rules installed${NC}"
    echo

    # 2. Awesome YARA
    echo "[2/3] Downloading Awesome YARA collection..."
    if [ -d "awesome-yara" ]; then
        echo "  → Updating existing repository..."
        cd awesome-yara && git pull && cd ..
    else
        git clone --depth 1 https://github.com/InQuest/awesome-yara.git awesome-yara
    fi
    echo -e "${GREEN}✓ Awesome YARA installed${NC}"
    echo

    # 3. Signature-Base (Florian Roth)
    echo "[3/3] Downloading Signature-Base (APT rules)..."
    if [ -d "signature-base" ]; then
        echo "  → Updating existing repository..."
        cd signature-base && git pull && cd ..
    else
        git clone --depth 1 https://github.com/Neo23x0/signature-base.git signature-base
    fi
    echo -e "${GREEN}✓ Signature-Base installed${NC}"
    echo

    echo "═══════════════════════════════════════════════════════"
    echo "Installation Complete!"
    echo "═══════════════════════════════════════════════════════"
    echo "Rules installed to: $rules_dir"
    echo
    echo "Usage examples:"
    echo "  # Scan with all rules"
    echo "  $0 --file malware.exe --rules $rules_dir"
    echo
    echo "  # Scan with specific ruleset"
    echo "  $0 --file suspicious.bin --rules $rules_dir/yara-rules/malware"
    echo
    echo "Rule categories available:"
    echo "  - malware/ (generic malware detection)"
    echo "  - apt/ (Advanced Persistent Threats)"
    echo "  - ransomware/ (ransomware families)"
    echo "  - webshells/ (web shells)"
    echo "  - crypto/ (cryptocurrency miners)"
    echo "═══════════════════════════════════════════════════════"
}

list_rules() {
    local rules_dir="$HOME/.yara/rules"

    if [ ! -d "$rules_dir" ]; then
        echo -e "${YELLOW}No rules installed. Run: $0 --install-rules${NC}"
        return 1
    fi

    echo "═══════════════════════════════════════════════════════"
    echo "Installed YARA Rules"
    echo "═══════════════════════════════════════════════════════"
    echo

    find "$rules_dir" -name "*.yar" -o -name "*.yara" | while read -r rule; do
        local rule_name=$(basename "$rule")
        local rule_count=$(grep -c "^rule " "$rule" 2>/dev/null || echo "0")
        echo "  $rule_name ($rule_count rules)"
    done

    echo
    echo "Total rule files: $(find "$rules_dir" -name "*.yar" -o -name "*.yara" | wc -l)"
    echo "═══════════════════════════════════════════════════════"
}

scan_file() {
    local file="$1"
    local rules="$2"
    local verbose="$3"
    local output_file="$4"

    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File not found: $file${NC}" >&2
        return 1
    fi

    if [ ! -e "$rules" ]; then
        echo -e "${RED}Error: Rules not found: $rules${NC}" >&2
        return 1
    fi

    local file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    local file_type=$(file -b "$file")

    if [ "$verbose" = "true" ]; then
        echo -e "${BLUE}[*] Scanning: $file${NC}"
        echo "    Size: $(numfmt --to=iec-i --suffix=B $file_size 2>/dev/null || echo $file_size bytes)"
        echo "    Type: $file_type"
    fi

    # Run YARA scan
    local matches=$(yara -r -w "$rules" "$file" 2>/dev/null)

    if [ -n "$matches" ]; then
        echo -e "${RED}⚠ YARA MATCH DETECTED${NC}"
        echo "File: $file"
        echo "───────────────────────────────────────────"
        echo "$matches"
        echo "───────────────────────────────────────────"

        if [ -n "$output_file" ]; then
            echo "File: $file" >> "$output_file"
            echo "$matches" >> "$output_file"
            echo "" >> "$output_file"
        fi

        return 2
    else
        if [ "$verbose" = "true" ]; then
            echo -e "${GREEN}✓ Clean - no matches${NC}"
        fi
        return 0
    fi
}

scan_directory() {
    local dir="$1"
    local rules="$2"
    local verbose="$3"
    local output_file="$4"
    local fast="$5"

    if [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Directory not found: $dir${NC}" >&2
        return 1
    fi

    echo "═══════════════════════════════════════════════════════"
    echo "YARA Directory Scan"
    echo "═══════════════════════════════════════════════════════"
    echo "Directory: $dir"
    echo "Rules: $rules"
    echo "Started: $(date)"
    echo "═══════════════════════════════════════════════════════"
    echo

    local total_files=0
    local matched_files=0
    local skipped_files=0

    # Find files to scan
    while IFS= read -r -d '' file; do
        total_files=$((total_files + 1))

        # Fast mode: skip large files (>10MB)
        if [ "$fast" = "true" ]; then
            local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
            if [ "$size" -gt 10485760 ]; then
                if [ "$verbose" = "true" ]; then
                    echo -e "${YELLOW}[SKIP] Large file: $file${NC}"
                fi
                skipped_files=$((skipped_files + 1))
                continue
            fi
        fi

        scan_file "$file" "$rules" "$verbose" "$output_file"
        if [ $? -eq 2 ]; then
            matched_files=$((matched_files + 1))
            echo
        fi

    done < <(find "$dir" -type f -print0)

    echo
    echo "═══════════════════════════════════════════════════════"
    echo "Scan Summary"
    echo "═══════════════════════════════════════════════════════"
    echo "Total files scanned: $total_files"
    echo -e "${RED}Files with matches: $matched_files${NC}"
    if [ "$fast" = "true" ]; then
        echo "Files skipped (large): $skipped_files"
    fi
    echo "Completed: $(date)"
    echo "═══════════════════════════════════════════════════════"

    if [ -n "$output_file" ]; then
        echo
        echo -e "${GREEN}✓ Results saved to: $output_file${NC}"
    fi

    return $matched_files
}

# Parse arguments
FILE=""
DIR=""
RULES=""
OUTPUT_FILE=""
VERBOSE="false"
FAST="false"
INSTALL="false"
LIST="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            FILE="$2"
            shift 2
            ;;
        -d|--dir)
            DIR="$2"
            shift 2
            ;;
        -r|--rules)
            RULES="$2"
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
        --fast)
            FAST="true"
            shift
            ;;
        --install-rules)
            INSTALL="true"
            shift
            ;;
        --list-rules)
            LIST="true"
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

# Check YARA installation
if ! check_yara; then
    exit 1
fi

# Handle special modes
if [ "$INSTALL" = "true" ]; then
    install_rules
    exit 0
fi

if [ "$LIST" = "true" ]; then
    list_rules
    exit 0
fi

# Validate rules parameter
if [ -z "$RULES" ]; then
    # Try default location
    RULES="$HOME/.yara/rules"
    if [ ! -d "$RULES" ]; then
        echo -e "${RED}Error: No rules specified and no rules installed${NC}" >&2
        echo "Install rules with: $0 --install-rules" >&2
        echo "Or specify rules with: --rules <rule_file>" >&2
        exit 1
    fi
    echo "Using installed rules: $RULES"
    echo
fi

# Execute scan
if [ -n "$FILE" ]; then
    # Single file scan
    scan_file "$FILE" "$RULES" "$VERBOSE" "$OUTPUT_FILE"
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 2 ]; then
        echo
        echo -e "${RED}⚠ THREAT DETECTED - Investigate immediately${NC}"
        exit 2
    else
        echo -e "${GREEN}✓ Scan complete - No threats detected${NC}"
        exit 0
    fi

elif [ -n "$DIR" ]; then
    # Directory scan
    scan_directory "$DIR" "$RULES" "$VERBOSE" "$OUTPUT_FILE" "$FAST"
    exit $?

else
    # Scan current directory if no target specified
    DIR="."
    echo "No target specified, scanning current directory..."
    echo
    scan_directory "$DIR" "$RULES" "$VERBOSE" "$OUTPUT_FILE" "$FAST"
    exit $?
fi
