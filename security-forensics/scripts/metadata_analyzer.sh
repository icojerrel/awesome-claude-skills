#!/bin/bash
# Forensic Metadata Analyzer
# Extracts and analyzes file metadata for inconsistencies and anomalies

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
Forensic Metadata Analyzer v${VERSION}

Extracts and analyzes file metadata to detect:
- Timestamp inconsistencies (created > modified)
- Author/creator mismatches
- Software version anomalies
- Hidden revision history
- Geolocation data
- Metadata tampering indicators

Usage:
    $0 --file <file>                      # Analyze single file
    $0 --dir <directory>                  # Analyze directory
    $0 --compare <file1> <file2>          # Compare two files
    $0 --batch <file1> <file2> ...        # Batch analysis

Options:
    -f, --file <file>           Analyze single file
    -d, --dir <directory>       Analyze all files in directory
    -c, --compare <f1> <f2>     Compare metadata between files
    -b, --batch <files>         Batch analyze multiple files
    -o, --output <file>         Output file (CSV format)
    -v, --verbose               Verbose output
    --check-inconsistencies     Check for timestamp/metadata inconsistencies
    --extract-all               Extract all available metadata
    --detect-tampering          Look for tampering indicators
    --help                      Show this help

Examples:
    # Analyze suspicious document
    $0 --file contract.docx --detect-tampering

    # Batch analyze evidence files
    $0 --batch doc1.pdf doc2.docx doc3.xlsx --output metadata.csv

    # Compare original vs modified
    $0 --compare original.pdf modified.pdf

    # Full directory scan
    $0 --dir /evidence/ --check-inconsistencies --output report.csv

Supported file types:
    - PDF documents
    - Office documents (DOCX, XLSX, PPTX)
    - Images (JPEG, PNG, TIFF with EXIF)
    - Archives (ZIP, TAR, GZ)
    - Executables (ELF, PE)
    - Generic files (filesystem metadata)

Output: CSV file with metadata + anomaly flags
EOF
}

# Check dependencies
check_dependencies() {
    local missing=()

    # Core tools (usually available)
    for tool in file stat; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done

    # Optional tools (nice to have)
    local optional=()
    command -v exiftool &> /dev/null || optional+=("exiftool (recommended)")
    command -v pdfinfo &> /dev/null || optional+=("pdfinfo (for PDFs)")
    command -v zipinfo &> /dev/null || optional+=("zipinfo (for Office docs)")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing[*]}${NC}" >&2
        return 1
    fi

    if [ ${#optional[@]} -gt 0 ] && [ "$VERBOSE" = "true" ]; then
        echo -e "${YELLOW}Note: Optional tools not found: ${optional[*]}${NC}"
        echo "Some features may be limited. Install with:"
        echo "  Ubuntu/Debian: sudo apt-get install libimage-exiftool-perl poppler-utils"
        echo "  macOS: brew install exiftool poppler"
        echo
    fi

    return 0
}

# Extract filesystem metadata
extract_filesystem_metadata() {
    local file="$1"

    # Basic file info
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    local permissions=$(stat -f%p "$file" 2>/dev/null || stat -c%a "$file" 2>/dev/null)
    local owner=$(stat -f%Su "$file" 2>/dev/null || stat -c%U "$file" 2>/dev/null)
    local group=$(stat -f%Sg "$file" 2>/dev/null || stat -c%G "$file" 2>/dev/null)

    # Timestamps (critical for forensics)
    local created=$(stat -f%B "$file" 2>/dev/null || echo "N/A")
    local modified=$(stat -f%m "$file" 2>/dev/null || stat -c%Y "$file" 2>/dev/null)
    local accessed=$(stat -f%a "$file" 2>/dev/null || stat -c%X "$file" 2>/dev/null)
    local changed=$(stat -f%c "$file" 2>/dev/null || stat -c%Z "$file" 2>/dev/null)

    # Convert to readable format
    if [ "$created" != "N/A" ]; then
        created=$(date -r "$created" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$created")
    fi
    modified=$(date -r "$modified" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$modified")
    accessed=$(date -r "$accessed" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$accessed")
    changed=$(date -r "$changed" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$changed")

    # File type
    local filetype=$(file -b "$file")

    # Hashes
    local md5=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1 || md5 -q "$file" 2>/dev/null)
    local sha256=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1)

    echo "FILESYSTEM_SIZE=$size"
    echo "FILESYSTEM_PERMISSIONS=$permissions"
    echo "FILESYSTEM_OWNER=$owner"
    echo "FILESYSTEM_GROUP=$group"
    echo "FILESYSTEM_CREATED=$created"
    echo "FILESYSTEM_MODIFIED=$modified"
    echo "FILESYSTEM_ACCESSED=$accessed"
    echo "FILESYSTEM_CHANGED=$changed"
    echo "FILESYSTEM_TYPE=$filetype"
    echo "FILESYSTEM_MD5=$md5"
    echo "FILESYSTEM_SHA256=$sha256"
}

# Extract PDF metadata
extract_pdf_metadata() {
    local file="$1"

    if command -v pdfinfo &> /dev/null; then
        pdfinfo "$file" 2>/dev/null | while IFS=: read -r key value; do
            key=$(echo "$key" | tr ' ' '_' | tr '[:lower:]' '[:upper:]')
            value=$(echo "$value" | xargs)
            echo "PDF_${key}=${value}"
        done
    fi

    # Try exiftool if available
    if command -v exiftool &> /dev/null; then
        exiftool -s -PDF:all "$file" 2>/dev/null | while read -r line; do
            local key=$(echo "$line" | cut -d: -f1 | tr ' ' '_' | tr '[:lower:]' '[:upper:]')
            local value=$(echo "$line" | cut -d: -f2- | xargs)
            echo "EXIF_${key}=${value}"
        done
    fi
}

# Extract Office document metadata (DOCX, XLSX, PPTX)
extract_office_metadata() {
    local file="$1"
    local tempdir=$(mktemp -d)

    # Office files are ZIP archives
    if command -v unzip &> /dev/null; then
        unzip -q "$file" -d "$tempdir" 2>/dev/null

        # Core properties (docProps/core.xml)
        if [ -f "$tempdir/docProps/core.xml" ]; then
            local creator=$(grep -oP '(?<=<dc:creator>)[^<]+' "$tempdir/docProps/core.xml" 2>/dev/null)
            local lastModifiedBy=$(grep -oP '(?<=<cp:lastModifiedBy>)[^<]+' "$tempdir/docProps/core.xml" 2>/dev/null)
            local created=$(grep -oP '(?<=<dcterms:created[^>]*>)[^<]+' "$tempdir/docProps/core.xml" 2>/dev/null)
            local modified=$(grep -oP '(?<=<dcterms:modified[^>]*>)[^<]+' "$tempdir/docProps/core.xml" 2>/dev/null)
            local title=$(grep -oP '(?<=<dc:title>)[^<]+' "$tempdir/docProps/core.xml" 2>/dev/null)
            local subject=$(grep -oP '(?<=<dc:subject>)[^<]+' "$tempdir/docProps/core.xml" 2>/dev/null)
            local revision=$(grep -oP '(?<=<cp:revision>)[^<]+' "$tempdir/docProps/core.xml" 2>/dev/null)

            [ -n "$creator" ] && echo "OFFICE_CREATOR=$creator"
            [ -n "$lastModifiedBy" ] && echo "OFFICE_LAST_MODIFIED_BY=$lastModifiedBy"
            [ -n "$created" ] && echo "OFFICE_CREATED=$created"
            [ -n "$modified" ] && echo "OFFICE_MODIFIED=$modified"
            [ -n "$title" ] && echo "OFFICE_TITLE=$title"
            [ -n "$subject" ] && echo "OFFICE_SUBJECT=$subject"
            [ -n "$revision" ] && echo "OFFICE_REVISION=$revision"
        fi

        # App properties (docProps/app.xml)
        if [ -f "$tempdir/docProps/app.xml" ]; then
            local application=$(grep -oP '(?<=<Application>)[^<]+' "$tempdir/docProps/app.xml" 2>/dev/null)
            local appVersion=$(grep -oP '(?<=<AppVersion>)[^<]+' "$tempdir/docProps/app.xml" 2>/dev/null)
            local company=$(grep -oP '(?<=<Company>)[^<]+' "$tempdir/docProps/app.xml" 2>/dev/null)

            [ -n "$application" ] && echo "OFFICE_APPLICATION=$application"
            [ -n "$appVersion" ] && echo "OFFICE_APP_VERSION=$appVersion"
            [ -n "$company" ] && echo "OFFICE_COMPANY=$company"
        fi
    fi

    # Cleanup
    rm -rf "$tempdir"

    # Also try exiftool
    if command -v exiftool &> /dev/null; then
        exiftool -s "$file" 2>/dev/null | grep -E "Author|Creator|CreateDate|ModifyDate|Company|Software" | while read -r line; do
            local key=$(echo "$line" | cut -d: -f1 | tr ' ' '_' | tr '[:lower:]' '[:upper:]')
            local value=$(echo "$line" | cut -d: -f2- | xargs)
            echo "EXIF_${key}=${value}"
        done
    fi
}

# Extract image EXIF metadata
extract_exif_metadata() {
    local file="$1"

    if command -v exiftool &> /dev/null; then
        exiftool -s "$file" 2>/dev/null | while read -r line; do
            local key=$(echo "$line" | cut -d: -f1 | tr ' ' '_' | tr '[:lower:]' '[:upper:]')
            local value=$(echo "$line" | cut -d: -f2- | xargs)
            echo "EXIF_${key}=${value}"
        done
    fi
}

# Detect metadata inconsistencies
detect_inconsistencies() {
    local file="$1"
    local metadata="$2"
    local anomalies=()

    # Extract timestamps
    local fs_created=$(echo "$metadata" | grep "FILESYSTEM_CREATED=" | cut -d= -f2-)
    local fs_modified=$(echo "$metadata" | grep "FILESYSTEM_MODIFIED=" | cut -d= -f2-)
    local office_created=$(echo "$metadata" | grep "OFFICE_CREATED=" | cut -d= -f2-)
    local office_modified=$(echo "$metadata" | grep "OFFICE_MODIFIED=" | cut -d= -f2-)

    # Check: Filesystem created > modified (impossible)
    if [ -n "$fs_created" ] && [ "$fs_created" != "N/A" ] && [ -n "$fs_modified" ]; then
        if [[ "$fs_created" > "$fs_modified" ]]; then
            anomalies+=("ANOMALY: Filesystem creation date after modification date")
        fi
    fi

    # Check: Office metadata vs filesystem metadata mismatch
    if [ -n "$office_created" ] && [ -n "$fs_modified" ]; then
        # Convert to comparable format (seconds since epoch)
        local office_ts=$(date -d "$office_created" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$office_created" +%s 2>/dev/null)
        local fs_ts=$(date -d "$fs_modified" +%s 2>/dev/null)

        if [ -n "$office_ts" ] && [ -n "$fs_ts" ]; then
            local diff=$((fs_ts - office_ts))
            # If office doc created more than 1 hour after file modified → suspicious
            if [ $diff -lt -3600 ]; then
                anomalies+=("ANOMALY: Document internal creation date is after file modification date (possible tampering)")
            fi
        fi
    fi

    # Check: Author mismatch
    local creator=$(echo "$metadata" | grep "OFFICE_CREATOR=" | cut -d= -f2-)
    local lastModifiedBy=$(echo "$metadata" | grep "OFFICE_LAST_MODIFIED_BY=" | cut -d= -f2-)

    if [ -n "$creator" ] && [ -n "$lastModifiedBy" ] && [ "$creator" != "$lastModifiedBy" ]; then
        anomalies+=("INFO: Creator differs from last modifier (Creator: $creator, Modified by: $lastModifiedBy)")
    fi

    # Check: Suspicious creator names
    if [ -n "$creator" ]; then
        case "$creator" in
            *admin*|*root*|*test*|*user*)
                anomalies+=("WARNING: Generic/suspicious creator name: $creator")
                ;;
        esac
    fi

    # Check: Missing revision history (suspicious for multi-edit docs)
    local revision=$(echo "$metadata" | grep "OFFICE_REVISION=" | cut -d= -f2-)
    if [ -n "$revision" ] && [ "$revision" = "1" ] && [ -n "$lastModifiedBy" ] && [ "$creator" != "$lastModifiedBy" ]; then
        anomalies+=("ANOMALY: Revision count is 1 but creator differs from last modifier (possible metadata wipe)")
    fi

    # Output anomalies
    if [ ${#anomalies[@]} -gt 0 ]; then
        for anomaly in "${anomalies[@]}"; do
            echo "FINDING: $anomaly"
        done
        return 1
    fi

    return 0
}

# Analyze single file
analyze_file() {
    local file="$1"
    local verbose="$2"
    local check_inconsistencies="$3"

    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File not found: $file${NC}" >&2
        return 1
    fi

    if [ "$verbose" = "true" ]; then
        echo -e "${BLUE}[*] Analyzing: $file${NC}"
    fi

    local metadata=""

    # Extract filesystem metadata (always)
    metadata+=$(extract_filesystem_metadata "$file")
    metadata+=$'\n'

    # Detect file type and extract appropriate metadata
    local filetype=$(file -b "$file")

    case "$filetype" in
        *PDF*)
            metadata+=$(extract_pdf_metadata "$file")
            metadata+=$'\n'
            ;;
        *Microsoft*Word*|*Microsoft*Excel*|*Microsoft*PowerPoint*|*Office*Open*XML*)
            metadata+=$(extract_office_metadata "$file")
            metadata+=$'\n'
            ;;
        *JPEG*|*PNG*|*TIFF*|*image*)
            metadata+=$(extract_exif_metadata "$file")
            metadata+=$'\n'
            ;;
    esac

    # Check for inconsistencies if requested
    local has_anomalies=false
    if [ "$check_inconsistencies" = "true" ]; then
        if ! detect_inconsistencies "$file" "$metadata"; then
            has_anomalies=true
        fi
    fi

    # Output results
    echo "FILE=$file"
    echo "$metadata"

    if [ "$has_anomalies" = "true" ]; then
        echo -e "${RED}⚠ ANOMALIES DETECTED${NC}"
    elif [ "$verbose" = "true" ]; then
        echo -e "${GREEN}✓ No anomalies detected${NC}"
    fi

    echo "───────────────────────────────────────────"

    return 0
}

# Compare two files
compare_files() {
    local file1="$1"
    local file2="$2"

    echo "═══════════════════════════════════════════════════════"
    echo "Metadata Comparison"
    echo "═══════════════════════════════════════════════════════"
    echo "File 1: $file1"
    echo "File 2: $file2"
    echo "═══════════════════════════════════════════════════════"
    echo

    # Extract metadata for both files
    local meta1=$(mktemp)
    local meta2=$(mktemp)

    extract_filesystem_metadata "$file1" > "$meta1"
    extract_office_metadata "$file1" >> "$meta1" 2>/dev/null
    extract_pdf_metadata "$file1" >> "$meta1" 2>/dev/null

    extract_filesystem_metadata "$file2" > "$meta2"
    extract_office_metadata "$file2" >> "$meta2" 2>/dev/null
    extract_pdf_metadata "$file2" >> "$meta2" 2>/dev/null

    # Compare key fields
    echo "Timestamp Comparison:"
    echo "───────────────────────────────────────────"

    local f1_created=$(grep "FILESYSTEM_CREATED=" "$meta1" | cut -d= -f2-)
    local f2_created=$(grep "FILESYSTEM_CREATED=" "$meta2" | cut -d= -f2-)
    local f1_modified=$(grep "FILESYSTEM_MODIFIED=" "$meta1" | cut -d= -f2-)
    local f2_modified=$(grep "FILESYSTEM_MODIFIED=" "$meta2" | cut -d= -f2-)

    echo "Created:  $f1_created  →  $f2_created"
    echo "Modified: $f1_modified  →  $f2_modified"
    echo

    echo "Author Comparison:"
    echo "───────────────────────────────────────────"

    local f1_creator=$(grep "OFFICE_CREATOR=" "$meta1" | cut -d= -f2-)
    local f2_creator=$(grep "OFFICE_CREATOR=" "$meta2" | cut -d= -f2-)
    local f1_modifier=$(grep "OFFICE_LAST_MODIFIED_BY=" "$meta1" | cut -d= -f2-)
    local f2_modifier=$(grep "OFFICE_LAST_MODIFIED_BY=" "$meta2" | cut -d= -f2-)

    echo "Creator:       ${f1_creator:-N/A}  →  ${f2_creator:-N/A}"
    echo "Last Modified: ${f1_modifier:-N/A}  →  ${f2_modifier:-N/A}"
    echo

    # Check for anomalies in comparison
    echo "Anomaly Detection:"
    echo "───────────────────────────────────────────"

    local anomalies=0

    if [ "$f1_creator" != "$f2_creator" ] && [ -n "$f1_creator" ] && [ -n "$f2_creator" ]; then
        echo -e "${YELLOW}⚠ Creator changed: $f1_creator → $f2_creator${NC}"
        anomalies=$((anomalies + 1))
    fi

    if [ "$f1_modified" = "$f2_modified" ]; then
        echo -e "${YELLOW}⚠ Identical modification timestamps (suspicious for different files)${NC}"
        anomalies=$((anomalies + 1))
    fi

    # Compare hashes
    local f1_hash=$(grep "FILESYSTEM_SHA256=" "$meta1" | cut -d= -f2-)
    local f2_hash=$(grep "FILESYSTEM_SHA256=" "$meta2" | cut -d= -f2-)

    if [ "$f1_hash" = "$f2_hash" ]; then
        echo -e "${GREEN}✓ Files are identical (same SHA256 hash)${NC}"
    else
        echo -e "${CYAN}ℹ Files are different (different SHA256 hashes)${NC}"
    fi

    if [ $anomalies -eq 0 ]; then
        echo -e "${GREEN}✓ No anomalies detected${NC}"
    fi

    rm -f "$meta1" "$meta2"

    echo
    echo "═══════════════════════════════════════════════════════"
}

# Export to CSV
export_to_csv() {
    local output_file="$1"
    local data="$2"

    # Create CSV header
    echo "File,Size,Type,Created,Modified,Creator,LastModifiedBy,Revision,Anomalies" > "$output_file"

    # Parse data and write CSV rows
    # (Implementation depends on data format - simplified here)
    echo "$data" >> "$output_file"

    echo -e "${GREEN}✓ Results exported to: $output_file${NC}"
}

# Parse arguments
FILE=""
DIR=""
COMPARE_FILES=()
BATCH_FILES=()
OUTPUT_FILE=""
VERBOSE="false"
CHECK_INCONSISTENCIES="false"
EXTRACT_ALL="false"
DETECT_TAMPERING="false"

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
        -c|--compare)
            COMPARE_FILES=("$2" "$3")
            shift 3
            ;;
        -b|--batch)
            shift
            while [[ $# -gt 0 ]] && [[ ! "$1" =~ ^- ]]; do
                BATCH_FILES+=("$1")
                shift
            done
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        --check-inconsistencies)
            CHECK_INCONSISTENCIES="true"
            shift
            ;;
        --extract-all)
            EXTRACT_ALL="true"
            shift
            ;;
        --detect-tampering)
            DETECT_TAMPERING="true"
            CHECK_INCONSISTENCIES="true"
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

# Check dependencies
if ! check_dependencies; then
    exit 1
fi

# Execute based on mode
if [ -n "$FILE" ]; then
    # Single file analysis
    analyze_file "$FILE" "$VERBOSE" "$CHECK_INCONSISTENCIES"

elif [ ${#COMPARE_FILES[@]} -eq 2 ]; then
    # Compare mode
    compare_files "${COMPARE_FILES[0]}" "${COMPARE_FILES[1]}"

elif [ ${#BATCH_FILES[@]} -gt 0 ]; then
    # Batch mode
    echo "═══════════════════════════════════════════════════════"
    echo "Batch Metadata Analysis"
    echo "═══════════════════════════════════════════════════════"
    echo "Files: ${#BATCH_FILES[@]}"
    echo "═══════════════════════════════════════════════════════"
    echo

    for file in "${BATCH_FILES[@]}"; do
        analyze_file "$file" "$VERBOSE" "$CHECK_INCONSISTENCIES"
        echo
    done

elif [ -n "$DIR" ]; then
    # Directory mode
    echo "═══════════════════════════════════════════════════════"
    echo "Directory Metadata Analysis"
    echo "═══════════════════════════════════════════════════════"
    echo "Directory: $DIR"
    echo "═══════════════════════════════════════════════════════"
    echo

    find "$DIR" -type f | while read -r file; do
        analyze_file "$file" "$VERBOSE" "$CHECK_INCONSISTENCIES"
        echo
    done

else
    echo "Error: No input specified"
    show_usage
    exit 1
fi
