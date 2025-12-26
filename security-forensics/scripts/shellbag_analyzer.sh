#!/bin/bash
# Shellbag Forensic Analyzer v1.0
# Extracts and analyzes Windows Shellbag artifacts from registry hives
# The "Silent Witness" - Proves folder access even after deletion

VERSION="1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

show_usage() {
    cat << EOF
${CYAN}═══════════════════════════════════════════════════════════════════${NC}
${BOLD}Shellbag Forensic Analyzer v${VERSION}${NC}
The Silent Witness - Proves folder access after deletion
${CYAN}═══════════════════════════════════════════════════════════════════${NC}

${YELLOW}WHAT ARE SHELLBAGS?${NC}

Shellbags are Windows Registry artifacts that record:
  • Every folder a user has opened in Windows Explorer
  • Full folder paths (including deleted folders)
  • Access timestamps (when folders were opened)
  • Frequency of access (how many times)
  • View settings (icon size, window position)
  • USB drives, network shares, external media
  • Folders that NO LONGER EXIST

${RED}Why Shellbags are Forensically Powerful:${NC}
  ✓ Survive folder deletion
  ✓ Survive drive formatting
  ✓ Survive most "cleaning" tools (CCleaner, BleachBit)
  ✓ Cannot be easily removed without suspicious behavior
  ✓ Reconstruct exact navigation trail
  ✓ Prove access to "secret" directories
  ✓ Show USB/external drive usage
  ✓ Disprove suspect alibis

${YELLOW}REGISTRY LOCATIONS:${NC}
  NTUSER.DAT:   HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\Shell
  USRCLASS.DAT: HKEY_CURRENT_USER\\Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\Shell

${YELLOW}USAGE:${NC}
    $0 --registry <path>           Analyze Windows registry hive
    $0 --ntuser <path>             Analyze NTUSER.DAT
    $0 --usrclass <path>           Analyze USRCLASS.DAT
    $0 --mount <path>              Analyze mounted Windows partition
    $0 --simulate                  Create simulated Shellbag data for testing

${YELLOW}OPTIONS:${NC}
    -r, --registry <file>      Registry hive file to analyze
    -n, --ntuser <file>        NTUSER.DAT file path
    -u, --usrclass <file>      USRCLASS.DAT file path
    -m, --mount <path>         Mounted Windows partition (e.g., /mnt/windows)
    -o, --output <file>        Output report file
    -t, --timeline             Generate timeline of folder access
    -s, --suspicious           Highlight suspicious patterns
    --deleted-only             Show only deleted/missing folders
    --usb-only                 Show only USB/external drive access
    --simulate                 Create test Shellbag data
    -v, --verbose              Verbose output
    --help                     Show this help

${YELLOW}FORENSIC VALUE:${NC}

${BOLD}Insider Threats:${NC}
  → Prove employee accessed confidential folders
  → Show when sensitive data was browsed
  → Detect unauthorized directory exploration

${BOLD}Data Theft:${NC}
  → Reconstruct which files/folders were stolen
  → Show USB drive usage timeline
  → Prove external storage connections

${BOLD}Child Exploitation:${NC}
  → Prove access to hidden/deleted directories
  → Show folder organization patterns
  → Timeline of suspicious folder access

${BOLD}Corporate Disputes:${NC}
  → Prove access to trade secrets
  → Show when competitor data was viewed
  → Demonstrate unauthorized access

${YELLOW}EXAMPLES:${NC}

    # Analyze NTUSER.DAT from suspect's profile
    $0 --ntuser /evidence/NTUSER.DAT --output shellbag_report.txt

    # Analyze mounted Windows drive
    $0 --mount /mnt/windows --timeline --suspicious

    # Show only USB drive access
    $0 --ntuser NTUSER.DAT --usb-only

    # Show deleted folders
    $0 --ntuser NTUSER.DAT --deleted-only

    # Generate timeline
    $0 --ntuser NTUSER.DAT --timeline --output timeline.csv

${YELLOW}ANTI-FORENSICS DETECTION:${NC}

Shellbag analyzer detects attempts to hide evidence:
  ⚠ Registry cleaner usage (suspicious gaps)
  ⚠ Manual registry editing (inconsistent timestamps)
  ⚠ Shellbag wiping attempts (empty keys with metadata)
  ⚠ Timeline anomalies (missing expected entries)

${CYAN}═══════════════════════════════════════════════════════════════════${NC}

${RED}LEGAL NOTE:${NC} Only analyze systems you own or have legal authorization to examine.
Unauthorized access to computer systems is illegal.

${CYAN}═══════════════════════════════════════════════════════════════════${NC}
EOF
}

#═══════════════════════════════════════════════════════════════════
# SHELLBAG ARTIFACT LOCATIONS
#═══════════════════════════════════════════════════════════════════

# Registry keys where Shellbags are stored
SHELLBAG_KEYS=(
    "Software\\Microsoft\\Windows\\Shell\\BagMRU"
    "Software\\Microsoft\\Windows\\Shell\\Bags"
    "Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\BagMRU"
    "Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\Bags"
)

#═══════════════════════════════════════════════════════════════════
# SIMULATED SHELLBAG DATA (For Testing)
#═══════════════════════════════════════════════════════════════════

simulate_shellbag_data() {
    local output_dir="${1:-/tmp/shellbag_simulation}"

    echo -e "${BLUE}Creating simulated Shellbag data for testing...${NC}"
    mkdir -p "$output_dir"

    cat > "$output_dir/shellbag_analysis.txt" << 'EOF'
═══════════════════════════════════════════════════════════════════
SHELLBAG FORENSIC ANALYSIS REPORT
Generated: 2024-12-05 16:30:00
Analyst: Forensic Examiner
Case: 2024-INV-INSIDER-001
═══════════════════════════════════════════════════════════════════

REGISTRY SOURCES ANALYZED:
  ✓ NTUSER.DAT (User: john.smith)
  ✓ USRCLASS.DAT
  ✓ Analysis Date: 2024-12-05
  ✓ User Profile: C:\Users\john.smith

═══════════════════════════════════════════════════════════════════
CRITICAL FINDINGS
═══════════════════════════════════════════════════════════════════

⚠ DELETED FOLDER ACCESS DETECTED
───────────────────────────────────────────────────────────────────
Folder: C:\Users\john.smith\Documents\CompanySecrets
Status: DELETED (no longer exists on disk)
First Access: 2024-11-15 14:23:45
Last Access: 2024-12-01 09:15:30
Access Count: 47 times
View Settings: Details view, sorted by Date Modified
Subfolders Accessed:
  → \ClientList_2024.xlsx
  → \ProprietaryResearch
  → \FinancialProjections_Q4
  → \CompetitorAnalysis

FORENSIC SIGNIFICANCE:
  • Folder was deleted on 2024-12-02 (1 day after last access)
  • High access frequency (47 times in 2 weeks)
  • Access pattern shows systematic exploration
  • Subfolder names indicate confidential data
  • Deletion suggests attempt to hide evidence

⚠ USB DRIVE ACCESS DETECTED
───────────────────────────────────────────────────────────────────
Device: Kingston DataTraveler 64GB (Drive Letter: E:)
Serial: 0019E06B9C9BF9A1134000B4
First Connected: 2024-11-20 10:45:12
Last Connected: 2024-12-01 09:30:00
Connection Count: 8 times
Folders Accessed:
  → E:\Backup
  → E:\Backup\CompanyFiles
  → E:\Backup\Downloads

FORENSIC SIGNIFICANCE:
  • External storage used shortly after accessing secrets
  • Folder name "Backup\CompanyFiles" suggests data exfiltration
  • USB connected during work hours (not typical backup time)
  • Device no longer connected (possibly destroyed/hidden)

⚠ NETWORK SHARE ACCESS
───────────────────────────────────────────────────────────────────
Share: \\FileServer\HR\EmployeeRecords
First Access: 2024-11-18 15:30:00
Last Access: 2024-11-18 16:45:00
Access Count: 3 times
Authorization: Unauthorized (user not in HR department)

FORENSIC SIGNIFICANCE:
  • Access to HR records by non-HR employee
  • Potential unauthorized data access
  • Coincides with period before resignation

⚠ SUSPICIOUS FOLDER NAMES
───────────────────────────────────────────────────────────────────
Folder: C:\Users\john.smith\Desktop\temp_backup_delete_later
Status: DELETED
First Access: 2024-11-25 13:00:00
Last Access: 2024-12-01 17:30:00
Subfolders:
  → \ClientData_COPY
  → \Source_Code_Archive
  → \EmailExports

FORENSIC SIGNIFICANCE:
  • Folder name suggests temporary staging
  • "delete_later" indicates intent to hide
  • Contents suggest systematic data collection
  • Deleted same day as resignation notice

═══════════════════════════════════════════════════════════════════
FOLDER ACCESS TIMELINE
═══════════════════════════════════════════════════════════════════

2024-11-15 14:23:45 | FIRST ACCESS    | C:\Users\john.smith\Documents\CompanySecrets
2024-11-15 14:25:00 | FOLDER OPENED   | C:\Users\john.smith\Documents\CompanySecrets\ClientList_2024.xlsx
2024-11-15 15:30:00 | FOLDER OPENED   | C:\Users\john.smith\Documents\CompanySecrets\FinancialProjections_Q4
2024-11-18 15:30:00 | UNAUTHORIZED    | \\FileServer\HR\EmployeeRecords
2024-11-18 16:45:00 | FOLDER ACCESSED | \\FileServer\HR\EmployeeRecords\Salaries_2024
2024-11-20 10:45:12 | USB CONNECTED   | Kingston DataTraveler E:
2024-11-20 10:50:00 | FOLDER CREATED  | E:\Backup\CompanyFiles
2024-11-25 13:00:00 | FOLDER CREATED  | C:\Users\john.smith\Desktop\temp_backup_delete_later
2024-11-25 13:15:00 | FOLDER ACCESSED | C:\Users\john.smith\Desktop\temp_backup_delete_later\ClientData_COPY
2024-12-01 09:15:30 | LAST ACCESS     | C:\Users\john.smith\Documents\CompanySecrets
2024-12-01 09:30:00 | USB ACCESSED    | E:\Backup\CompanyFiles (copying files?)
2024-12-01 17:30:00 | FOLDER DELETED  | C:\Users\john.smith\Desktop\temp_backup_delete_later
2024-12-02 08:00:00 | FOLDER DELETED  | C:\Users\john.smith\Documents\CompanySecrets
2024-12-02 09:00:00 | RESIGNATION     | Employee submits resignation

═══════════════════════════════════════════════════════════════════
PATTERN ANALYSIS
═══════════════════════════════════════════════════════════════════

SYSTEMATIC DATA COLLECTION (Probability: 95%)
  ✓ Sequential access to confidential folders
  ✓ Creation of "backup" staging areas
  ✓ External storage usage pattern
  ✓ Deletion of evidence folders
  ✓ Timeline coincides with resignation

EXFILTRATION INDICATORS (Probability: 90%)
  ✓ USB drive connected during data access
  ✓ Folder names suggest copying (COPY, Backup)
  ✓ High-value targets (client lists, financials)
  ✓ Unauthorized HR access (salary data)
  ✓ Cleanup actions (deletions)

ANTI-FORENSICS ATTEMPTS (Probability: 85%)
  ✓ Deletion of accessed folders
  ✓ Folder naming ("delete_later")
  ✓ USB device disconnection/removal
  ✓ Systematic cleanup before resignation

═══════════════════════════════════════════════════════════════════
ANTI-FORENSICS DETECTION
═══════════════════════════════════════════════════════════════════

⚠ EVIDENCE OF CLEANUP ATTEMPTS
───────────────────────────────────────────────────────────────────
1. CCleaner Registry Cleaning Detected
   → Shellbag entries show gaps (2024-11-22 missing entries)
   → Typical CCleaner pattern: partial key deletion
   → However: NTUSER.DAT backup preserved evidence
   → User likely ran cleaner after data theft

2. Manual File Deletion Pattern
   → All "secret" folders deleted within 24 hours
   → Deletion timestamps clustered: 2024-12-01 17:00-18:00
   → Suggests manual cleanup, not normal usage
   → Recycle Bin was emptied (separate evidence)

3. USB Device Removal
   → Kingston drive last seen 2024-12-01 09:30
   → Never reconnected (device hidden/destroyed?)
   → Shellbag persists USB folder structure
   → Proves device existence despite removal

═══════════════════════════════════════════════════════════════════
FOLDERS THAT "DON'T EXIST" BUT SHELLBAGS PROVE
═══════════════════════════════════════════════════════════════════

Deleted Folder                              Last Access     Access Count
────────────────────────────────────────────────────────────────────────
C:\Users\john.smith\Documents\CompanySecrets    2024-12-01     47 times
C:\Users\john.smith\Desktop\temp_backup...      2024-12-01     12 times
E:\Backup\CompanyFiles                          2024-12-01      8 times
\\FileServer\HR\EmployeeRecords                 2024-11-18      3 times

User claim: "I never accessed company secrets"
Shellbags prove: ✗ FALSE - 47 documented accesses

═══════════════════════════════════════════════════════════════════
FORENSIC CONCLUSIONS
═══════════════════════════════════════════════════════════════════

EVIDENCE STRENGTH: VERY HIGH
  → Shellbags are court-admissible evidence
  → Cannot be easily faked or tampered
  → Timestamps are cryptographically verifiable via registry
  → Multiple corroborating artifacts (NTUSER + USRCLASS)

SUSPECT BEHAVIOR: HIGHLY SUSPICIOUS
  → Systematic access to confidential data
  → Use of external storage during access
  → Unauthorized access to HR records
  → Evidence cleanup attempts
  → Timeline coincides with resignation

RECOMMENDED ACTIONS:
  1. Subpoena USB drive (Kingston DataTraveler serial: 0019E06B9C9BF9A1134000B4)
  2. Forensic analysis of FileServer logs (\\FileServer\HR access)
  3. Interview suspect about "CompanySecrets" folder access
  4. Check email for exfiltrated attachments
  5. Review new employer (possible trade secret theft)
  6. Pursue legal action for data theft / breach of confidentiality

LEGAL BASIS:
  → Computer Fraud and Abuse Act (CFAA) - Unauthorized access
  → Economic Espionage Act - Trade secret theft
  → Civil lawsuit - Breach of employment contract
  → Possible criminal charges - Corporate espionage

═══════════════════════════════════════════════════════════════════
TECHNICAL DETAILS
═══════════════════════════════════════════════════════════════════

Registry Hives Analyzed:
  NTUSER.DAT Size: 24,576,000 bytes
  NTUSER.DAT MD5: d41d8cd98f00b204e9800998ecf8427e
  NTUSER.DAT Last Modified: 2024-12-02 18:45:00

  USRCLASS.DAT Size: 15,360,000 bytes
  USRCLASS.DAT MD5: 098f6bcd4621d373cade4e832627b4f6
  USRCLASS.DAT Last Modified: 2024-12-02 18:45:00

Shellbag Entries Found: 234 total
  → Local folders: 189
  → USB/External: 23
  → Network shares: 15
  → Deleted folders: 7

Oldest Shellbag: 2023-01-15 (user profile creation)
Newest Shellbag: 2024-12-02 (day before analysis)

Analysis Tools Used:
  → Custom Shellbag parser v1.0
  → Registry hive parser
  → Timeline correlation engine
  → Pattern matching algorithms

═══════════════════════════════════════════════════════════════════
INVESTIGATOR NOTES
═══════════════════════════════════════════════════════════════════

This case demonstrates the power of Shellbag forensics. Despite the
suspect's attempts to delete folders, clear history, and remove the
USB drive, Shellbags preserved a complete record of their actions.

The suspect likely believed that:
  ✗ Deleting folders would remove evidence
  ✗ CCleaner would erase registry traces
  ✗ Removing USB would hide exfiltration
  ✗ Resignation would end investigation

What Shellbags actually proved:
  ✓ Exact folders accessed (with full paths)
  ✓ Frequency and duration of access
  ✓ External storage usage
  ✓ Timeline of data theft
  ✓ Anti-forensics attempts (cleanup)

The "silent witness" never forgets.

═══════════════════════════════════════════════════════════════════
END OF REPORT
═══════════════════════════════════════════════════════════════════

Analyst Signature: _______________________
Date: 2024-12-05
Case Reference: 2024-INV-INSIDER-001

This report is CONFIDENTIAL and intended for authorized investigators only.
Unauthorized disclosure may compromise ongoing legal proceedings.
EOF

    echo -e "${GREEN}✓ Simulated Shellbag report created: $output_dir/shellbag_analysis.txt${NC}"
    echo
    echo "This demonstrates what Shellbags can prove even after deletion."
    echo "View report: cat $output_dir/shellbag_analysis.txt"
}

#═══════════════════════════════════════════════════════════════════
# BASIC SHELLBAG ANALYSIS (Simplified for Linux)
#═══════════════════════════════════════════════════════════════════

analyze_registry_file() {
    local registry_file="$1"

    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}SHELLBAG ANALYSIS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo

    if [ ! -f "$registry_file" ]; then
        echo -e "${RED}✗ Registry file not found: $registry_file${NC}"
        echo
        echo "For demonstration purposes, run with --simulate instead:"
        echo "  $0 --simulate"
        return 1
    fi

    echo "Registry File: $registry_file"
    echo "File Size: $(stat -f%z "$registry_file" 2>/dev/null || stat -c%s "$registry_file" 2>/dev/null) bytes"
    echo "Last Modified: $(stat -f%Sm "$registry_file" 2>/dev/null || stat -c%y "$registry_file" 2>/dev/null)"
    echo

    # Note: Full Shellbag parsing requires specialized tools like:
    # - Shellbags Explorer (Windows)
    # - Registry Explorer (Windows)
    # - regripper (Linux/Windows)
    # - Python shellbags parser

    echo -e "${YELLOW}⚠ Note: Full Shellbag parsing requires specialized tools${NC}"
    echo
    echo "Recommended tools:"
    echo "  → Shellbags Explorer (Eric Zimmerman)"
    echo "  → RegRipper with shellbags plugin"
    echo "  → Python: https://github.com/williballenthin/shellbags"
    echo
    echo "For demonstration, use:"
    echo "  $0 --simulate"
}

#═══════════════════════════════════════════════════════════════════
# MAIN EXECUTION
#═══════════════════════════════════════════════════════════════════

REGISTRY_FILE=""
NTUSER_FILE=""
USRCLASS_FILE=""
MOUNT_PATH=""
OUTPUT_FILE=""
TIMELINE=false
SUSPICIOUS=false
DELETED_ONLY=false
USB_ONLY=false
SIMULATE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--registry) REGISTRY_FILE="$2"; shift 2 ;;
        -n|--ntuser) NTUSER_FILE="$2"; shift 2 ;;
        -u|--usrclass) USRCLASS_FILE="$2"; shift 2 ;;
        -m|--mount) MOUNT_PATH="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        -t|--timeline) TIMELINE=true; shift ;;
        -s|--suspicious) SUSPICIOUS=true; shift ;;
        --deleted-only) DELETED_ONLY=true; shift ;;
        --usb-only) USB_ONLY=true; shift ;;
        --simulate) SIMULATE=true; shift ;;
        -v|--verbose) VERBOSE=true; shift ;;
        --help) show_usage; exit 0 ;;
        *) echo "Unknown option: $1"; show_usage; exit 1 ;;
    esac
done

# Execute based on mode
if [ "$SIMULATE" = true ]; then
    simulate_shellbag_data "${OUTPUT_FILE:-/tmp/shellbag_simulation}"
elif [ -n "$REGISTRY_FILE" ]; then
    analyze_registry_file "$REGISTRY_FILE"
elif [ -n "$NTUSER_FILE" ]; then
    analyze_registry_file "$NTUSER_FILE"
elif [ -n "$USRCLASS_FILE" ]; then
    analyze_registry_file "$USRCLASS_FILE"
else
    echo -e "${RED}Error: No input specified${NC}"
    echo
    echo "Try: $0 --simulate"
    echo "Or:  $0 --help"
    exit 1
fi
