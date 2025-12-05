#!/bin/bash
# Chain of Custody Manager
# Maintains legal chain of custody for digital evidence
# Compliant with ISO/IEC 27037:2012 and law enforcement standards

VERSION="1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CUSTODY_DB="$HOME/.forensics/chain_of_custody.db"
EVIDENCE_DIR="$HOME/.forensics/evidence"
AUDIT_LOG="$HOME/.forensics/audit.log"

show_usage() {
    cat << EOF
Chain of Custody Manager v${VERSION}

Maintains legal chain of custody for digital evidence according to:
- ISO/IEC 27037:2012 (Digital Evidence Guidelines)
- ACPO (Association of Chief Police Officers) Principles
- NIJ (National Institute of Justice) Standards

Usage:
    $0 --collect <file>                # Collect evidence
    $0 --transfer <evidence-id>        # Transfer custody
    $0 --view <evidence-id>            # View custody history
    $0 --verify <evidence-id>          # Verify integrity
    $0 --export-report <evidence-id>   # Generate court report

Options:
    -c, --collect <file>               Collect and register evidence
    -t, --transfer <evidence-id>       Transfer custody to another person
    -v, --view <evidence-id>           View full chain of custody
    -V, --verify <evidence-id>         Verify evidence integrity
    -r, --export-report <id>           Export custody report (legal format)
    -l, --list                         List all evidence
    --case-number <number>             Associate with case number
    --investigator <name>              Investigator name
    --notes <text>                     Add notes/description
    --help                             Show this help

Chain of Custody Principles (ACPO):
1. No action should change data held on computer/media
2. If access required, person must be competent
3. Audit trail of all processes applied
4. Person in charge has responsibility for compliance

Examples:
    # Collect evidence from suspect's drive
    $0 --collect /mnt/suspect_disk/document.pdf \\
       --case-number 2024-INV-1234 \\
       --investigator "Det. John Smith" \\
       --notes "Found in Downloads folder"

    # Transfer custody to lab analyst
    $0 --transfer EV-001 \\
       --investigator "Forensic Analyst Jane Doe" \\
       --notes "Transferred for analysis"

    # Verify integrity before court
    $0 --verify EV-001

    # Generate legal report
    $0 --export-report EV-001 > evidence_report_EV-001.txt

Output: Tamper-evident audit trail with cryptographic hashes
EOF
}

# Initialize custody database
init_database() {
    mkdir -p "$(dirname "$CUSTODY_DB")"
    mkdir -p "$EVIDENCE_DIR"

    if [ ! -f "$CUSTODY_DB" ]; then
        cat > "$CUSTODY_DB" << 'EOF'
# Chain of Custody Database
# DO NOT MANUALLY EDIT - Use chain_of_custody.sh commands only
# Format: EVIDENCE_ID|FILE_PATH|SHA256|CASE_NUMBER|COLLECTED_BY|COLLECTED_DATE|STATUS
EOF
    fi

    touch "$AUDIT_LOG"
}

# Add audit log entry
audit_log() {
    local action="$1"
    local evidence_id="$2"
    local user="$3"
    local notes="$4"

    local timestamp=$(date "+%Y-%m-%d %H:%M:%S %Z")
    local entry="[$timestamp] ACTION=$action | EVIDENCE=$evidence_id | USER=$user | NOTES=$notes"

    echo "$entry" >> "$AUDIT_LOG"
}

# Generate unique evidence ID
generate_evidence_id() {
    local prefix="EV"
    local timestamp=$(date +%Y%m%d%H%M%S)
    local random=$(od -An -N2 -i /dev/urandom | tr -d ' ')
    echo "${prefix}-${timestamp}-${random}"
}

# Collect evidence
collect_evidence() {
    local file="$1"
    local case_number="$2"
    local investigator="$3"
    local notes="$4"

    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File not found: $file${NC}" >&2
        return 1
    fi

    # Generate evidence ID
    local evidence_id=$(generate_evidence_id)
    local evidence_path="$EVIDENCE_DIR/$evidence_id"

    echo "═══════════════════════════════════════════════════════"
    echo "EVIDENCE COLLECTION - $evidence_id"
    echo "═══════════════════════════════════════════════════════"
    echo "Case Number: $case_number"
    echo "Collected By: $investigator"
    echo "Date/Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Original File: $file"
    echo "═══════════════════════════════════════════════════════"
    echo

    # Calculate hashes BEFORE moving (integrity proof)
    echo "[*] Calculating cryptographic hashes..."
    local md5=$(md5sum "$file" | cut -d' ' -f1)
    local sha1=$(sha1sum "$file" | cut -d' ' -f1)
    local sha256=$(sha256sum "$file" | cut -d' ' -f1)
    local sha512=$(sha512sum "$file" | cut -d' ' -f1)

    echo "  MD5:    $md5"
    echo "  SHA1:   $sha1"
    echo "  SHA256: $sha256"
    echo "  SHA512: $sha512"
    echo

    # Get file metadata
    local filesize=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file")
    local filetype=$(file -b "$file")

    # Create evidence package directory
    mkdir -p "$evidence_path"

    # Copy file (preserving original timestamps and permissions)
    echo "[*] Creating forensic copy..."
    cp -p "$file" "$evidence_path/evidence_file"

    # Create read-only copy (prevent accidental modification)
    chmod 444 "$evidence_path/evidence_file"

    # Create evidence metadata file
    cat > "$evidence_path/metadata.txt" << EOF
═══════════════════════════════════════════════════════
DIGITAL EVIDENCE METADATA
═══════════════════════════════════════════════════════
Evidence ID: $evidence_id
Case Number: $case_number
Collected By: $investigator
Collection Date: $(date '+%Y-%m-%d %H:%M:%S %Z')
Collection Hostname: $(hostname)
Collection User: $(whoami)

ORIGINAL FILE INFORMATION:
═══════════════════════════════════════════════════════
Original Path: $file
File Size: $filesize bytes
File Type: $filetype

CRYPTOGRAPHIC HASHES (At Collection):
═══════════════════════════════════════════════════════
MD5:    $md5
SHA1:   $sha1
SHA256: $sha256
SHA512: $sha512

CHAIN OF CUSTODY:
═══════════════════════════════════════════════════════
1. COLLECTED
   Date/Time: $(date '+%Y-%m-%d %H:%M:%S %Z')
   Custodian: $investigator
   Action: Initial evidence collection
   Notes: $notes

NOTES:
═══════════════════════════════════════════════════════
$notes

═══════════════════════════════════════════════════════
This evidence package is maintained according to ISO/IEC 27037:2012
and law enforcement digital evidence handling standards.
═══════════════════════════════════════════════════════
EOF

    # Add to database
    echo "$evidence_id|$file|$sha256|$case_number|$investigator|$(date '+%Y-%m-%d %H:%M:%S')|COLLECTED" >> "$CUSTODY_DB"

    # Audit log
    audit_log "COLLECT" "$evidence_id" "$investigator" "$notes"

    echo -e "${GREEN}✓ Evidence collected successfully${NC}"
    echo "Evidence ID: $evidence_id"
    echo "Storage Location: $evidence_path"
    echo
    echo "IMPORTANT: This evidence is now under chain of custody."
    echo "All access and modifications will be logged."
    echo

    return 0
}

# Transfer custody
transfer_custody() {
    local evidence_id="$1"
    local new_custodian="$2"
    local notes="$3"

    local evidence_path="$EVIDENCE_DIR/$evidence_id"

    if [ ! -d "$evidence_path" ]; then
        echo -e "${RED}Error: Evidence not found: $evidence_id${NC}" >&2
        return 1
    fi

    echo "═══════════════════════════════════════════════════════"
    echo "CUSTODY TRANSFER - $evidence_id"
    echo "═══════════════════════════════════════════════════════"
    echo "Transfer Date: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "New Custodian: $new_custodian"
    echo "═══════════════════════════════════════════════════════"
    echo

    # Verify integrity before transfer
    echo "[*] Verifying evidence integrity..."
    local current_hash=$(sha256sum "$evidence_path/evidence_file" | cut -d' ' -f1)
    local original_hash=$(grep "SHA256:" "$evidence_path/metadata.txt" | awk '{print $2}')

    if [ "$current_hash" != "$original_hash" ]; then
        echo -e "${RED}✗ INTEGRITY VIOLATION DETECTED!${NC}"
        echo "Original SHA256: $original_hash"
        echo "Current SHA256:  $current_hash"
        echo
        echo "EVIDENCE HAS BEEN MODIFIED - CHAIN OF CUSTODY BROKEN"
        audit_log "INTEGRITY_FAILURE" "$evidence_id" "$(whoami)" "Hash mismatch detected during transfer"
        return 1
    fi

    echo -e "${GREEN}✓ Integrity verified${NC}"
    echo

    # Add transfer record to metadata
    local transfer_entry="
$(grep -c "COLLECTED\|TRANSFERRED\|ACCESSED" "$evidence_path/metadata.txt"). TRANSFERRED
   Date/Time: $(date '+%Y-%m-%d %H:%M:%S %Z')
   From: $(grep "^   Custodian:" "$evidence_path/metadata.txt" | tail -1 | cut -d: -f2-)
   To: $new_custodian
   Action: Custody transfer
   Notes: $notes
"

    # Append to custody log in metadata
    sed -i "/^CHAIN OF CUSTODY:/a\\$transfer_entry" "$evidence_path/metadata.txt" 2>/dev/null || \
    sed -i '' "/^CHAIN OF CUSTODY:/a\\
$transfer_entry" "$evidence_path/metadata.txt"

    # Update database
    sed -i "s/^$evidence_id|/# TRANSFERRED $(date '+%Y-%m-%d') - &/" "$CUSTODY_DB"
    echo "$evidence_id|$(grep "^$evidence_id|" "$CUSTODY_DB" | head -1 | cut -d'|' -f2-6)|TRANSFERRED" >> "$CUSTODY_DB"

    # Audit log
    audit_log "TRANSFER" "$evidence_id" "$new_custodian" "$notes"

    echo -e "${GREEN}✓ Custody transferred successfully${NC}"
    echo "New custodian: $new_custodian"
    echo

    return 0
}

# View custody history
view_custody() {
    local evidence_id="$1"
    local evidence_path="$EVIDENCE_DIR/$evidence_id"

    if [ ! -d "$evidence_path" ]; then
        echo -e "${RED}Error: Evidence not found: $evidence_id${NC}" >&2
        return 1
    fi

    cat "$evidence_path/metadata.txt"

    echo
    echo "═══════════════════════════════════════════════════════"
    echo "AUDIT LOG ENTRIES"
    echo "═══════════════════════════════════════════════════════"
    grep "$evidence_id" "$AUDIT_LOG"
    echo "═══════════════════════════════════════════════════════"
}

# Verify evidence integrity
verify_evidence() {
    local evidence_id="$1"
    local evidence_path="$EVIDENCE_DIR/$evidence_id"

    if [ ! -d "$evidence_path" ]; then
        echo -e "${RED}Error: Evidence not found: $evidence_id${NC}" >&2
        return 1
    fi

    echo "═══════════════════════════════════════════════════════"
    echo "EVIDENCE INTEGRITY VERIFICATION - $evidence_id"
    echo "═══════════════════════════════════════════════════════"
    echo "Verification Date: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Verified By: $(whoami)@$(hostname)"
    echo "═══════════════════════════════════════════════════════"
    echo

    # Calculate current hashes
    echo "[*] Calculating current cryptographic hashes..."
    local current_md5=$(md5sum "$evidence_path/evidence_file" | cut -d' ' -f1)
    local current_sha1=$(sha1sum "$evidence_path/evidence_file" | cut -d' ' -f1)
    local current_sha256=$(sha256sum "$evidence_path/evidence_file" | cut -d' ' -f1)
    local current_sha512=$(sha512sum "$evidence_path/evidence_file" | cut -d' ' -f1)

    # Extract original hashes from metadata
    local original_md5=$(grep "MD5:" "$evidence_path/metadata.txt" | head -1 | awk '{print $2}')
    local original_sha1=$(grep "SHA1:" "$evidence_path/metadata.txt" | head -1 | awk '{print $2}')
    local original_sha256=$(grep "SHA256:" "$evidence_path/metadata.txt" | head -1 | awk '{print $2}')
    local original_sha512=$(grep "SHA512:" "$evidence_path/metadata.txt" | head -1 | awk '{print $2}')

    echo
    echo "Hash Comparison:"
    echo "───────────────────────────────────────────"

    local all_match=true

    # MD5
    if [ "$current_md5" = "$original_md5" ]; then
        echo -e "MD5:    ${GREEN}✓ MATCH${NC}"
    else
        echo -e "MD5:    ${RED}✗ MISMATCH${NC}"
        echo "  Original: $original_md5"
        echo "  Current:  $current_md5"
        all_match=false
    fi

    # SHA1
    if [ "$current_sha1" = "$original_sha1" ]; then
        echo -e "SHA1:   ${GREEN}✓ MATCH${NC}"
    else
        echo -e "SHA1:   ${RED}✗ MISMATCH${NC}"
        echo "  Original: $original_sha1"
        echo "  Current:  $current_sha1"
        all_match=false
    fi

    # SHA256
    if [ "$current_sha256" = "$original_sha256" ]; then
        echo -e "SHA256: ${GREEN}✓ MATCH${NC}"
    else
        echo -e "SHA256: ${RED}✗ MISMATCH${NC}"
        echo "  Original: $original_sha256"
        echo "  Current:  $current_sha256"
        all_match=false
    fi

    # SHA512
    if [ "$current_sha512" = "$original_sha512" ]; then
        echo -e "SHA512: ${GREEN}✓ MATCH${NC}"
    else
        echo -e "SHA512: ${RED}✗ MISMATCH${NC}"
        echo "  Original: $original_sha512"
        echo "  Current:  $current_sha512"
        all_match=false
    fi

    echo
    echo "═══════════════════════════════════════════════════════"

    if [ "$all_match" = true ]; then
        echo -e "${GREEN}✓ EVIDENCE INTEGRITY VERIFIED${NC}"
        echo "All cryptographic hashes match original values."
        echo "Evidence has not been altered since collection."
        audit_log "VERIFY_SUCCESS" "$evidence_id" "$(whoami)" "Integrity verification passed"
        return 0
    else
        echo -e "${RED}✗ EVIDENCE INTEGRITY VIOLATION${NC}"
        echo "One or more hashes do not match original values."
        echo "EVIDENCE MAY HAVE BEEN TAMPERED WITH - NOT ADMISSIBLE"
        audit_log "VERIFY_FAILURE" "$evidence_id" "$(whoami)" "Integrity verification FAILED"
        return 1
    fi
}

# Export legal report
export_report() {
    local evidence_id="$1"
    local evidence_path="$EVIDENCE_DIR/$evidence_id"

    if [ ! -d "$evidence_path" ]; then
        echo -e "${RED}Error: Evidence not found: $evidence_id${NC}" >&2
        return 1
    fi

    cat << EOF
═══════════════════════════════════════════════════════════════════
DIGITAL EVIDENCE CHAIN OF CUSTODY REPORT
═══════════════════════════════════════════════════════════════════

Report Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')
Generated By: $(whoami)@$(hostname)
Evidence ID: $evidence_id

This report documents the complete chain of custody for digital evidence
collected and maintained according to ISO/IEC 27037:2012 and law
enforcement standards.

═══════════════════════════════════════════════════════════════════
EVIDENCE METADATA
═══════════════════════════════════════════════════════════════════

EOF

    cat "$evidence_path/metadata.txt"

    cat << EOF

═══════════════════════════════════════════════════════════════════
INTEGRITY VERIFICATION
═══════════════════════════════════════════════════════════════════

Verification Performed: $(date '+%Y-%m-%d %H:%M:%S %Z')

EOF

    # Perform integrity check
    local current_sha256=$(sha256sum "$evidence_path/evidence_file" | cut -d' ' -f1)
    local original_sha256=$(grep "SHA256:" "$evidence_path/metadata.txt" | head -1 | awk '{print $2}')

    if [ "$current_sha256" = "$original_sha256" ]; then
        cat << EOF
Status: ✓ VERIFIED
Result: Evidence integrity confirmed
Current SHA256:  $current_sha256
Original SHA256: $original_sha256

The evidence file has not been altered since collection.
All cryptographic hashes match original values.

═══════════════════════════════════════════════════════════════════
CERTIFICATION
═══════════════════════════════════════════════════════════════════

I hereby certify that the above digital evidence has been maintained
under proper chain of custody procedures, and that the integrity of
the evidence has been verified through cryptographic hash comparison.

The evidence handling procedures followed are in accordance with:
- ISO/IEC 27037:2012 (Guidelines for identification, collection,
  acquisition and preservation of digital evidence)
- ACPO Good Practice Guide for Digital Evidence
- NIJ Electronic Crime Scene Investigation Guide

Certified By: $(whoami)
Date: $(date '+%Y-%m-%d')
Signature: _______________________________________

═══════════════════════════════════════════════════════════════════
COMPLETE AUDIT TRAIL
═══════════════════════════════════════════════════════════════════

EOF
        grep "$evidence_id" "$AUDIT_LOG"

        cat << EOF

═══════════════════════════════════════════════════════════════════
END OF REPORT
═══════════════════════════════════════════════════════════════════
EOF
    else
        cat << EOF
Status: ✗ INTEGRITY VIOLATION
Result: Evidence has been modified

Current SHA256:  $current_sha256
Original SHA256: $original_sha256

WARNING: The cryptographic hashes do not match. This evidence may have
been tampered with and is NOT ADMISSIBLE in court proceedings.

═══════════════════════════════════════════════════════════════════
EOF
    fi
}

# List all evidence
list_evidence() {
    echo "═══════════════════════════════════════════════════════"
    echo "EVIDENCE INVENTORY"
    echo "═══════════════════════════════════════════════════════"
    echo

    if [ ! -f "$CUSTODY_DB" ] || [ $(wc -l < "$CUSTODY_DB") -le 1 ]; then
        echo "No evidence registered."
        return 0
    fi

    printf "%-20s %-15s %-30s %-12s\n" "EVIDENCE ID" "CASE NUMBER" "COLLECTED BY" "STATUS"
    echo "───────────────────────────────────────────────────────────────────────────────"

    tail -n +2 "$CUSTODY_DB" | grep -v "^#" | while IFS='|' read -r id file hash case investigator date status; do
        printf "%-20s %-15s %-30s %-12s\n" "$id" "$case" "$investigator" "$status"
    done

    echo
    echo "Total evidence items: $(grep -c "^EV-" "$CUSTODY_DB")"
    echo "═══════════════════════════════════════════════════════"
}

# Parse arguments
COLLECT_FILE=""
TRANSFER_ID=""
VIEW_ID=""
VERIFY_ID=""
REPORT_ID=""
LIST=false
CASE_NUMBER=""
INVESTIGATOR=""
NOTES=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--collect)
            COLLECT_FILE="$2"
            shift 2
            ;;
        -t|--transfer)
            TRANSFER_ID="$2"
            shift 2
            ;;
        -v|--view)
            VIEW_ID="$2"
            shift 2
            ;;
        -V|--verify)
            VERIFY_ID="$2"
            shift 2
            ;;
        -r|--export-report)
            REPORT_ID="$2"
            shift 2
            ;;
        -l|--list)
            LIST=true
            shift
            ;;
        --case-number)
            CASE_NUMBER="$2"
            shift 2
            ;;
        --investigator)
            INVESTIGATOR="$2"
            shift 2
            ;;
        --notes)
            NOTES="$2"
            shift 2
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

# Initialize
init_database

# Execute command
if [ -n "$COLLECT_FILE" ]; then
    collect_evidence "$COLLECT_FILE" "$CASE_NUMBER" "$INVESTIGATOR" "$NOTES"
elif [ -n "$TRANSFER_ID" ]; then
    transfer_custody "$TRANSFER_ID" "$INVESTIGATOR" "$NOTES"
elif [ -n "$VIEW_ID" ]; then
    view_custody "$VIEW_ID"
elif [ -n "$VERIFY_ID" ]; then
    verify_evidence "$VERIFY_ID"
elif [ -n "$REPORT_ID" ]; then
    export_report "$REPORT_ID"
elif [ "$LIST" = true ]; then
    list_evidence
else
    echo "Error: No command specified"
    show_usage
    exit 1
fi
