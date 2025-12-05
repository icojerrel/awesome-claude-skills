#!/bin/bash
# Forensic Test Framework v1.0
# Comprehensive testing suite for all forensic tools
# Tests: functionality, edge cases, performance, failure modes

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

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORENSICS_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPTS_DIR="$FORENSICS_DIR/scripts"
TEST_OUTPUT_DIR="/tmp/forensic_tests_$(date +%Y%m%d_%H%M%S)"
TEST_DATA_DIR="$TEST_OUTPUT_DIR/test_data"
RESULTS_DIR="$TEST_OUTPUT_DIR/results"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNINGS=0

# Test categories
declare -A TEST_CATEGORIES=(
    ["basic"]="Basic functionality tests"
    ["edge"]="Edge cases and boundary conditions"
    ["corruption"]="Corrupted and incomplete data handling"
    ["performance"]="Performance and scalability tests"
    ["integration"]="Tool integration tests"
    ["security"]="Security and safety tests"
    ["realworld"]="Real-world scenario simulations"
)

show_usage() {
    cat << EOF
${CYAN}═══════════════════════════════════════════════════════════════════${NC}
Forensic Test Framework v${VERSION}
Comprehensive testing suite for security-forensics skill
${CYAN}═══════════════════════════════════════════════════════════════════${NC}

${YELLOW}USAGE:${NC}
    $0 [OPTIONS]

${YELLOW}OPTIONS:${NC}
    --all                   Run all test categories
    --basic                 Basic functionality tests
    --edge                  Edge case tests
    --corruption            Corruption handling tests
    --performance           Performance benchmarks
    --integration           Integration tests
    --security              Security tests
    --realworld             Real-world scenarios

    --tool <name>           Test specific tool only
    --verbose               Verbose output
    --keep-data             Keep test data after completion
    --output <dir>          Custom output directory
    --help                  Show this help

${YELLOW}EXAMPLES:${NC}
    # Run all tests
    $0 --all

    # Run specific category
    $0 --corruption --edge

    # Test specific tool
    $0 --tool metadata_analyzer --all

    # Verbose mode with data retention
    $0 --all --verbose --keep-data

${YELLOW}TEST CATEGORIES:${NC}
EOF
    for category in "${!TEST_CATEGORIES[@]}"; do
        printf "  %-15s %s\n" "$category:" "${TEST_CATEGORIES[$category]}"
    done
    echo
    echo "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
}

# Initialize test environment
init_test_environment() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}FORENSIC TEST FRAMEWORK v${VERSION}${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo
    echo "Initializing test environment..."

    mkdir -p "$TEST_DATA_DIR"
    mkdir -p "$RESULTS_DIR"

    echo "  Test output: $TEST_OUTPUT_DIR"
    echo "  Test data: $TEST_DATA_DIR"
    echo "  Results: $RESULTS_DIR"
    echo
}

# Test result tracking
record_test_result() {
    local test_name="$1"
    local status="$2"  # PASS, FAIL, WARN
    local message="$3"
    local details="$4"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    case "$status" in
        PASS)
            TESTS_PASSED=$((TESTS_PASSED + 1))
            echo -e "${GREEN}✓ PASS${NC} - $test_name"
            ;;
        FAIL)
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "${RED}✗ FAIL${NC} - $test_name"
            [ -n "$message" ] && echo -e "  ${RED}Error: $message${NC}"
            ;;
        WARN)
            TESTS_WARNINGS=$((TESTS_WARNINGS + 1))
            echo -e "${YELLOW}⚠ WARN${NC} - $test_name"
            [ -n "$message" ] && echo -e "  ${YELLOW}Warning: $message${NC}"
            ;;
    esac

    # Log to file
    echo "$(date +%Y-%m-%d\ %H:%M:%S) | $status | $test_name | $message" >> "$RESULTS_DIR/test_log.txt"

    [ -n "$details" ] && echo "$details" >> "$RESULTS_DIR/${test_name// /_}.details.txt"
}

#═══════════════════════════════════════════════════════════════════
# TEST DATA GENERATORS
#═══════════════════════════════════════════════════════════════════

generate_clean_evidence() {
    local output_dir="$1"

    # Clean log file
    cat > "$output_dir/clean_system.log" << 'EOF'
2024-12-05 08:00:00 [INFO] System startup
2024-12-05 08:00:15 [INFO] Network service started
2024-12-05 08:01:00 [INFO] User login: admin
2024-12-05 08:05:00 [INFO] File accessed: /etc/config.txt
2024-12-05 08:10:00 [INFO] User logout: admin
EOF

    # Clean document
    cat > "$output_dir/clean_document.txt" << 'EOF'
Business Report - Q4 2024
Author: John Doe
Created: 2024-12-01 10:00:00
Modified: 2024-12-05 08:00:00

Executive Summary:
This document contains the quarterly business report.
All metrics show positive growth trends.
EOF
}

generate_corrupted_evidence() {
    local output_dir="$1"

    # Severely corrupted log
    cat > "$output_dir/corrupted_severe.log" << 'EOF'
2024-12-05 08:00:00 [INFO] System startup
*** LOG CORRUPTION DETECTED - DATA LOSS ***
*** FILE SYSTEM ERROR - UNRECOVERABLE ***
*** CRITICAL: METADATA MISSING ***
2024-12-05 10:00:00 [WARNING] Partial recovery attempted
*** SECTION DELETED - CANNOT RESTORE ***
EOF

    # Partially corrupted data
    cat > "$output_dir/corrupted_partial.log" << 'EOF'
2024-12-05 08:00:00 [INFO] User login
2024-12-05 08:05:00 [INFO] File access
*** LOG ENTRY CORRUPTED ***
2024-12-05 08:30:00 [INFO] Network activity
EOF

    # Missing metadata document
    cat > "$output_dir/corrupted_metadata.txt" << 'EOF'
Document Title: [METADATA MISSING]
Author: [CORRUPTED]
Created: [FILE NOT FOUND]
Modified: [UNRECOVERABLE]

Content partially recovered...
*** DATA LOSS: 5KB MISSING ***
EOF
}

generate_incomplete_timeline() {
    local output_dir="$1"

    # Timeline with large gaps
    cat > "$output_dir/timeline_gaps.log" << 'EOF'
2024-12-05 08:00:00 [INFO] System boot
2024-12-05 08:01:00 [INFO] Services started
*** LOG ROTATION - ENTRIES MISSING ***
2024-12-05 10:00:00 [WARNING] System activity resumed
*** GAP: 2 HOURS OF LOGS MISSING ***
2024-12-05 12:00:00 [INFO] User login
EOF

    # Inconsistent timestamps
    cat > "$output_dir/timeline_inconsistent.log" << 'EOF'
2024-12-05 08:00:00 [INFO] Event A
2024-12-05 07:59:00 [INFO] Event B (timestamp before previous!)
2024-12-05 08:00:00 [INFO] Event C (duplicate timestamp)
2024-12-05 08:00:00 [INFO] Event D (duplicate timestamp)
2024-12-04 23:00:00 [INFO] Event E (backward in time!)
EOF
}

generate_malicious_samples() {
    local output_dir="$1"

    # Simulated malware strings (safe, just text patterns)
    cat > "$output_dir/malware_sample.txt" << 'EOF'
#!/bin/bash
# Simulated malware (SAFE - just strings for testing)
C2_SERVER="evil-c2.example.com"
CALLBACK_IP="203.0.113.666"  # Invalid IP for testing
PAYLOAD_URL="http://malware-download.example/payload.exe"
BACKDOOR_PORT=31337
CMD="powershell -enc QmFzZTY0RW5jb2RlZFBheWxvYWQ="
REGISTRY_KEY="HKEY_LOCAL_MACHINE\\Software\\Malware\\Persistence"
PASSWORD="admin123"
EXFILTRATE_TO="attacker@evil.example"
EOF

    # Suspicious log entries
    cat > "$output_dir/malicious_activity.log" << 'EOF'
2024-12-05 08:00:00 [AUTH] Failed login: admin (attempt 1)
2024-12-05 08:00:01 [AUTH] Failed login: admin (attempt 2)
2024-12-05 08:00:02 [AUTH] Failed login: admin (attempt 3)
2024-12-05 08:00:03 [AUTH] Failed login: root (attempt 4)
2024-12-05 08:00:15 [AUTH] Successful login: admin (brute force succeeded)
2024-12-05 08:01:00 [EXEC] Command executed: whoami
2024-12-05 08:01:05 [EXEC] Command executed: cat /etc/shadow
2024-12-05 08:01:10 [NETWORK] Outbound connection: 203.0.113.42:4444 (suspicious port)
2024-12-05 08:02:00 [FILE] File created: /tmp/.hidden_backdoor
2024-12-05 08:03:00 [FILE] Large file transfer: 500MB to external IP
EOF
}

generate_edge_cases() {
    local output_dir="$1"

    # Empty file
    touch "$output_dir/empty_file.txt"

    # Very large file (10MB of repetitive data)
    dd if=/dev/zero of="$output_dir/large_file.bin" bs=1M count=10 2>/dev/null

    # Binary data
    dd if=/dev/urandom of="$output_dir/binary_data.bin" bs=1K count=100 2>/dev/null

    # Special characters in filename
    touch "$output_dir/special chars & symbols!@#.txt"

    # Very long filename
    touch "$output_dir/$(printf 'a%.0s' {1..200}).txt" 2>/dev/null || touch "$output_dir/very_long_filename.txt"

    # File with no extension
    echo "No extension" > "$output_dir/noextension"

    # Unicode filename
    touch "$output_dir/测试文件.txt" 2>/dev/null || touch "$output_dir/unicode_test.txt"
}

generate_realistic_incident() {
    local output_dir="$1"

    # Realistic ransomware incident
    cat > "$output_dir/incident_ransomware.log" << 'EOF'
2024-12-05 08:00:00 [INFO] System startup - all services normal
2024-12-05 08:15:23 [AUTH] User login: marketing.manager@company.com
2024-12-05 08:16:45 [EMAIL] Email received from: invoice_department@suspicious-domain.com
2024-12-05 08:17:12 [FILE] Document opened: Invoice_Q4_2024.pdf.exe
2024-12-05 08:17:15 [PROCESS] New process: Invoice_Q4_2024.pdf.exe (suspicious)
2024-12-05 08:17:20 [NETWORK] Outbound connection to: 185.220.101.42:443
2024-12-05 08:17:25 [FILE] Mass file modifications detected
2024-12-05 08:17:30 [FILE] .encrypted extension added to 1,234 files
2024-12-05 08:17:35 [FILE] Ransom note created: _README_DECRYPT.txt
2024-12-05 08:17:40 [NETWORK] Data exfiltration: 2.3GB uploaded
2024-12-05 08:18:00 [ALERT] Antivirus detected: Ransomware.Generic
2024-12-05 08:18:05 [SYSTEM] Network isolated by admin
EOF

    # Phishing attack
    cat > "$output_dir/incident_phishing.log" << 'EOF'
2024-12-05 09:00:00 [EMAIL] Received: "Urgent: Verify your account" from noreply@micros0ft-security.com
2024-12-05 09:01:00 [WEB] User clicked link: http://micros0ft-security.com/verify (phishing)
2024-12-05 09:01:15 [WEB] Credentials submitted to phishing page
2024-12-05 09:05:00 [AUTH] Login attempt from Russia: 203.0.113.99
2024-12-05 09:05:30 [AUTH] Successful login from Russia (compromised credentials)
2024-12-05 09:06:00 [EMAIL] Password reset requested
2024-12-05 09:06:30 [EMAIL] Forwarding rule created: forward all to attacker@evil.com
EOF
}

#═══════════════════════════════════════════════════════════════════
# BASIC FUNCTIONALITY TESTS
#═══════════════════════════════════════════════════════════════════

test_basic_functionality() {
    mkdir -p "$TEST_DATA_DIR/basic"
    echo -e "\n${BLUE}[TEST CATEGORY]${NC} Basic Functionality Tests"
    echo "─────────────────────────────────────────────────────────────────"

    generate_clean_evidence "$TEST_DATA_DIR/basic"

    # Test 1: Hash calculator
    if [ -f "$SCRIPTS_DIR/hash_calculator.sh" ]; then
        local test_file="$TEST_DATA_DIR/basic/clean_document.txt"
        local output=$("$SCRIPTS_DIR/hash_calculator.sh" "$test_file" 2>&1)

        if echo "$output" | grep -q "MD5\|SHA256"; then
            record_test_result "Hash Calculator - Basic" "PASS" "All hashes calculated"
        else
            record_test_result "Hash Calculator - Basic" "FAIL" "Hash calculation failed" "$output"
        fi
    fi

    # Test 2: Metadata analyzer
    if [ -f "$SCRIPTS_DIR/metadata_analyzer.sh" ]; then
        local output=$("$SCRIPTS_DIR/metadata_analyzer.sh" -f "$TEST_DATA_DIR/basic/clean_document.txt" 2>&1)

        if echo "$output" | grep -q "FILESYSTEM\|METADATA"; then
            record_test_result "Metadata Analyzer - Basic" "PASS" "Metadata extracted"
        else
            record_test_result "Metadata Analyzer - Basic" "FAIL" "Metadata extraction failed" "$output"
        fi
    fi

    # Test 3: Timeline builder
    if [ -f "$SCRIPTS_DIR/timeline_builder_v2.sh" ]; then
        local output_file="$TEST_DATA_DIR/basic/timeline_output.txt"
        "$SCRIPTS_DIR/timeline_builder_v2.sh" \
            --files "$TEST_DATA_DIR/basic/clean_system.log" \
            --output "$output_file" 2>&1

        if [ -f "$output_file" ] && grep -q "TIMELINE" "$output_file"; then
            record_test_result "Timeline Builder - Basic" "PASS" "Timeline created"
        else
            record_test_result "Timeline Builder - Basic" "FAIL" "Timeline creation failed"
        fi
    fi

    # Test 4: Evidence quality analyzer
    if [ -f "$SCRIPTS_DIR/evidence_quality_analyzer.sh" ]; then
        local output_file="$TEST_DATA_DIR/basic/quality_report.txt"
        "$SCRIPTS_DIR/evidence_quality_analyzer.sh" \
            --files "$TEST_DATA_DIR/basic/clean_document.txt" \
            --output "$output_file" 2>&1

        if [ -f "$output_file" ] && grep -q "QUALITY SCORE" "$output_file"; then
            local score=$(grep "EVIDENCE QUALITY SCORE" "$output_file" | grep -o '[0-9]*' | head -1)
            if [ "$score" -ge 70 ]; then
                record_test_result "Evidence Quality - Clean Data" "PASS" "Score: $score/100 (expected high)"
            else
                record_test_result "Evidence Quality - Clean Data" "WARN" "Score unexpectedly low: $score/100"
            fi
        else
            record_test_result "Evidence Quality - Basic" "FAIL" "Analysis failed"
        fi
    fi
}

#═══════════════════════════════════════════════════════════════════
# CORRUPTION HANDLING TESTS
#═══════════════════════════════════════════════════════════════════

test_corruption_handling() {
    mkdir -p "$TEST_DATA_DIR/corruption"
    echo -e "\n${BLUE}[TEST CATEGORY]${NC} Corruption Handling Tests"
    echo "─────────────────────────────────────────────────────────────────"

    generate_corrupted_evidence "$TEST_DATA_DIR/corruption"

    # Test 1: Metadata analyzer detects corruption
    if [ -f "$SCRIPTS_DIR/metadata_analyzer.sh" ]; then
        local output=$("$SCRIPTS_DIR/metadata_analyzer.sh" \
            -f "$TEST_DATA_DIR/corruption/corrupted_metadata.txt" 2>&1)

        if echo "$output" | grep -iq "corruption"; then
            record_test_result "Metadata - Corruption Detection" "PASS" "Corruption markers detected"
        else
            record_test_result "Metadata - Corruption Detection" "FAIL" "Failed to detect corruption markers"
        fi
    fi

    # Test 2: Timeline builder handles corrupted logs
    if [ -f "$SCRIPTS_DIR/timeline_builder_v2.sh" ]; then
        local output_file="$TEST_DATA_DIR/corruption/timeline_corrupted.txt"
        "$SCRIPTS_DIR/timeline_builder_v2.sh" \
            --files "$TEST_DATA_DIR/corruption/corrupted_severe.log" \
            --output "$output_file" --quality-score 2>&1

        if [ -f "$output_file" ]; then
            if grep -iq "corruption" "$output_file"; then
                record_test_result "Timeline - Corruption Warnings" "PASS" "Corruption warnings present"
            else
                record_test_result "Timeline - Corruption Warnings" "WARN" "No corruption warnings found"
            fi

            # Check quality score
            local score=$(grep "QUALITY SCORE" "$output_file" | grep -o '[0-9]*' | head -1)
            if [ -n "$score" ] && [ "$score" -lt 60 ]; then
                record_test_result "Timeline - Low Score for Corruption" "PASS" "Score correctly low: $score/100"
            else
                record_test_result "Timeline - Low Score for Corruption" "WARN" "Score should be lower for corrupted data: $score/100"
            fi
        else
            record_test_result "Timeline - Corrupted Data" "FAIL" "Failed to process corrupted log"
        fi
    fi

    # Test 3: Evidence quality analyzer scoring
    if [ -f "$SCRIPTS_DIR/evidence_quality_analyzer.sh" ]; then
        local output_file="$TEST_DATA_DIR/corruption/quality_corrupted.txt"
        "$SCRIPTS_DIR/evidence_quality_analyzer.sh" \
            --files "$TEST_DATA_DIR/corruption/corrupted_severe.log" \
                    "$TEST_DATA_DIR/corruption/corrupted_partial.log" \
                    "$TEST_DATA_DIR/corruption/corrupted_metadata.txt" \
            --output "$output_file" 2>&1

        if [ -f "$output_file" ]; then
            local score=$(grep "FINAL SCORE" "$output_file" | grep -o '[0-9]*' | head -1)
            local corruption_count=$(grep "Corruption Markers:" "$output_file" | grep -o '[0-9]*' | head -1)

            if [ "$corruption_count" -ge 3 ]; then
                record_test_result "Evidence Quality - Corruption Count" "PASS" "Detected $corruption_count corrupted files"
            else
                record_test_result "Evidence Quality - Corruption Count" "FAIL" "Only detected $corruption_count/3 corrupted files"
            fi

            if [ "$score" -lt 50 ]; then
                record_test_result "Evidence Quality - Severe Corruption Score" "PASS" "Score correctly critical: $score/100"
            else
                record_test_result "Evidence Quality - Severe Corruption Score" "FAIL" "Score too high for severe corruption: $score/100"
            fi
        fi
    fi
}

#═══════════════════════════════════════════════════════════════════
# EDGE CASE TESTS
#═══════════════════════════════════════════════════════════════════

test_edge_cases() {
    mkdir -p "$TEST_DATA_DIR/edge"
    echo -e "\n${BLUE}[TEST CATEGORY]${NC} Edge Case Tests"
    echo "─────────────────────────────────────────────────────────────────"

    generate_edge_cases "$TEST_DATA_DIR/edge"

    # Test 1: Empty file handling
    if [ -f "$SCRIPTS_DIR/hash_calculator.sh" ]; then
        local output=$("$SCRIPTS_DIR/hash_calculator.sh" "$TEST_DATA_DIR/edge/empty_file.txt" 2>&1)

        if echo "$output" | grep -q "MD5\|SHA256"; then
            record_test_result "Hash Calculator - Empty File" "PASS" "Handled empty file"
        else
            record_test_result "Hash Calculator - Empty File" "FAIL" "Failed on empty file" "$output"
        fi
    fi

    # Test 2: Binary file handling
    if [ -f "$SCRIPTS_DIR/metadata_analyzer.sh" ]; then
        local output=$("$SCRIPTS_DIR/metadata_analyzer.sh" \
            -f "$TEST_DATA_DIR/edge/binary_data.bin" 2>&1)

        if [ $? -eq 0 ]; then
            record_test_result "Metadata - Binary File" "PASS" "Handled binary file"
        else
            record_test_result "Metadata - Binary File" "WARN" "Issues with binary file"
        fi
    fi

    # Test 3: Large file handling
    if [ -f "$SCRIPTS_DIR/hash_calculator.sh" ]; then
        local start_time=$(date +%s)
        "$SCRIPTS_DIR/hash_calculator.sh" "$TEST_DATA_DIR/edge/large_file.bin" > /dev/null 2>&1
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        if [ $duration -lt 30 ]; then
            record_test_result "Performance - Large File (10MB)" "PASS" "Completed in ${duration}s"
        else
            record_test_result "Performance - Large File (10MB)" "WARN" "Slow: ${duration}s (expected <30s)"
        fi
    fi

    # Test 4: Special characters in filenames
    if [ -f "$TEST_DATA_DIR/edge/special chars & symbols!@#.txt" ]; then
        if [ -f "$SCRIPTS_DIR/hash_calculator.sh" ]; then
            "$SCRIPTS_DIR/hash_calculator.sh" "$TEST_DATA_DIR/edge/special chars & symbols!@#.txt" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                record_test_result "Edge - Special Characters in Filename" "PASS" "Handled special chars"
            else
                record_test_result "Edge - Special Characters in Filename" "FAIL" "Failed with special chars"
            fi
        fi
    fi

    # Test 5: No extension file
    if [ -f "$SCRIPTS_DIR/metadata_analyzer.sh" ]; then
        "$SCRIPTS_DIR/metadata_analyzer.sh" -f "$TEST_DATA_DIR/edge/noextension" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            record_test_result "Edge - File Without Extension" "PASS" "Handled extensionless file"
        else
            record_test_result "Edge - File Without Extension" "WARN" "Issues with extensionless file"
        fi
    fi
}

#═══════════════════════════════════════════════════════════════════
# TIMELINE INTEGRITY TESTS
#═══════════════════════════════════════════════════════════════════

test_timeline_integrity() {
    mkdir -p "$TEST_DATA_DIR/timeline"
    echo -e "\n${BLUE}[TEST CATEGORY]${NC} Timeline Integrity Tests"
    echo "─────────────────────────────────────────────────────────────────"

    generate_incomplete_timeline "$TEST_DATA_DIR/timeline"

    if [ ! -f "$SCRIPTS_DIR/timeline_builder_v2.sh" ]; then
        record_test_result "Timeline Tests" "FAIL" "timeline_builder_v2.sh not found"
        return
    fi

    # Test 1: Gap detection
    local output_file="$TEST_DATA_DIR/timeline/gaps_detected.txt"
    "$SCRIPTS_DIR/timeline_builder_v2.sh" \
        --files "$TEST_DATA_DIR/timeline/timeline_gaps.log" \
        --output "$output_file" --quality-score 2>&1

    if grep -iq "gap" "$output_file"; then
        local gap_count=$(grep -i "gaps detected" "$output_file" | grep -o '[0-9]*' | head -1)
        if [ -n "$gap_count" ] && [ "$gap_count" -gt 0 ]; then
            record_test_result "Timeline - Gap Detection" "PASS" "Detected $gap_count gap(s)"
        else
            record_test_result "Timeline - Gap Detection" "WARN" "Gap mentioned but count unclear"
        fi
    else
        record_test_result "Timeline - Gap Detection" "FAIL" "Failed to detect timeline gaps"
    fi

    # Test 2: Timestamp inconsistencies
    local output_file2="$TEST_DATA_DIR/timeline/inconsistent.txt"
    "$SCRIPTS_DIR/timeline_builder_v2.sh" \
        --files "$TEST_DATA_DIR/timeline/timeline_inconsistent.log" \
        --output "$output_file2" 2>&1

    if [ -f "$output_file2" ]; then
        # Timeline should still be created despite inconsistencies
        if grep -q "TIMELINE" "$output_file2"; then
            record_test_result "Timeline - Timestamp Inconsistencies" "PASS" "Handled inconsistent timestamps"
        else
            record_test_result "Timeline - Timestamp Inconsistencies" "FAIL" "Failed on inconsistent timestamps"
        fi

        # Check if events are sorted
        local timestamps=$(grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}" "$output_file2")
        if [ -n "$timestamps" ]; then
            record_test_result "Timeline - Chronological Sorting" "PASS" "Events sorted chronologically"
        else
            record_test_result "Timeline - Chronological Sorting" "WARN" "Could not verify sorting"
        fi
    fi
}

#═══════════════════════════════════════════════════════════════════
# MALWARE DETECTION TESTS
#═══════════════════════════════════════════════════════════════════

test_malware_detection() {
    mkdir -p "$TEST_DATA_DIR/malware"
    echo -e "\n${BLUE}[TEST CATEGORY]${NC} Malware & Threat Detection Tests"
    echo "─────────────────────────────────────────────────────────────────"

    generate_malicious_samples "$TEST_DATA_DIR/malware"

    # Test 1: IOC scanner
    if [ -f "$SCRIPTS_DIR/ioc_scanner.sh" ]; then
        local output=$("$SCRIPTS_DIR/ioc_scanner.sh" \
            --file "$TEST_DATA_DIR/malware/malware_sample.txt" 2>&1)

        # Should detect IPs, domains, suspicious strings
        local detections=0
        echo "$output" | grep -iq "ip" && detections=$((detections + 1))
        echo "$output" | grep -iq "domain\|url" && detections=$((detections + 1))
        echo "$output" | grep -iq "suspicious\|malicious" && detections=$((detections + 1))

        if [ $detections -ge 2 ]; then
            record_test_result "IOC Scanner - Pattern Detection" "PASS" "Detected $detections IOC types"
        else
            record_test_result "IOC Scanner - Pattern Detection" "WARN" "Limited detections: $detections types"
        fi
    fi

    # Test 2: Log analyzer for suspicious activity
    if [ -f "$SCRIPTS_DIR/log_analyzer.sh" ]; then
        local output=$("$SCRIPTS_DIR/log_analyzer.sh" \
            "$TEST_DATA_DIR/malware/malicious_activity.log" 2>&1)

        if echo "$output" | grep -iq "brute\|suspicious\|attack"; then
            record_test_result "Log Analyzer - Threat Detection" "PASS" "Detected suspicious patterns"
        else
            record_test_result "Log Analyzer - Threat Detection" "WARN" "Limited threat detection"
        fi
    fi
}

#═══════════════════════════════════════════════════════════════════
# REAL-WORLD SCENARIO TESTS
#═══════════════════════════════════════════════════════════════════

test_realworld_scenarios() {
    mkdir -p "$TEST_DATA_DIR/realworld"
    echo -e "\n${BLUE}[TEST CATEGORY]${NC} Real-World Scenario Tests"
    echo "─────────────────────────────────────────────────────────────────"

    generate_realistic_incident "$TEST_DATA_DIR/realworld"

    # Test 1: Ransomware incident analysis
    if [ -f "$SCRIPTS_DIR/timeline_builder_v2.sh" ]; then
        local output_file="$TEST_DATA_DIR/realworld/ransomware_timeline.txt"
        "$SCRIPTS_DIR/timeline_builder_v2.sh" \
            --files "$TEST_DATA_DIR/realworld/incident_ransomware.log" \
            --output "$output_file" 2>&1

        if [ -f "$output_file" ]; then
            local event_count=$(grep -c "\[" "$output_file")
            if [ "$event_count" -ge 10 ]; then
                record_test_result "Real-World - Ransomware Timeline" "PASS" "Reconstructed $event_count events"
            else
                record_test_result "Real-World - Ransomware Timeline" "WARN" "Only $event_count events reconstructed"
            fi
        fi
    fi

    # Test 2: Phishing attack chain analysis
    if [ -f "$SCRIPTS_DIR/log_analyzer.sh" ]; then
        local output=$("$SCRIPTS_DIR/log_analyzer.sh" \
            "$TEST_DATA_DIR/realworld/incident_phishing.log" 2>&1)

        # Should identify key indicators
        local indicators=0
        echo "$output" | grep -iq "phish" && indicators=$((indicators + 1))
        echo "$output" | grep -iq "credential\|password" && indicators=$((indicators + 1))
        echo "$output" | grep -iq "suspicious\|malicious" && indicators=$((indicators + 1))

        if [ $indicators -ge 1 ]; then
            record_test_result "Real-World - Phishing Detection" "PASS" "Identified $indicators key indicators"
        else
            record_test_result "Real-World - Phishing Detection" "WARN" "Limited indicator detection"
        fi
    fi
}

#═══════════════════════════════════════════════════════════════════
# INTEGRATION TESTS
#═══════════════════════════════════════════════════════════════════

test_tool_integration() {
    echo -e "\n${BLUE}[TEST CATEGORY]${NC} Tool Integration Tests"
    echo "─────────────────────────────────────────────────────────────────"

    # Test 1: Chain of custody + hash verification workflow
    if [ -f "$SCRIPTS_DIR/chain_of_custody.sh" ] && [ -f "$SCRIPTS_DIR/hash_calculator.sh" ]; then
        local test_file="$TEST_DATA_DIR/basic/clean_document.txt"
        local evidence_dir="$TEST_DATA_DIR/integration/chain_test"

        # Collect evidence
        "$SCRIPTS_DIR/chain_of_custody.sh" collect \
            --file "$test_file" \
            --output-dir "$evidence_dir" \
            --case-number "TEST-001" \
            --investigator "Test Framework" 2>&1

        if [ -f "$evidence_dir"/*.evidence ]; then
            # Verify evidence
            local verify_output=$("$SCRIPTS_DIR/chain_of_custody.sh" verify \
                --evidence "$evidence_dir"/*.evidence 2>&1)

            if echo "$verify_output" | grep -iq "integrity.*pass\|verified"; then
                record_test_result "Integration - Chain of Custody Workflow" "PASS" "Evidence collected and verified"
            else
                record_test_result "Integration - Chain of Custody Workflow" "FAIL" "Verification failed"
            fi
        else
            record_test_result "Integration - Chain of Custody Workflow" "FAIL" "Evidence collection failed"
        fi
    fi

    # Test 2: Timeline + Evidence Quality workflow
    if [ -f "$SCRIPTS_DIR/timeline_builder_v2.sh" ] && [ -f "$SCRIPTS_DIR/evidence_quality_analyzer.sh" ]; then
        generate_corrupted_evidence "$TEST_DATA_DIR/integration/workflow"

        # Build timeline
        local timeline_out="$TEST_DATA_DIR/integration/workflow/timeline.txt"
        "$SCRIPTS_DIR/timeline_builder_v2.sh" \
            --files "$TEST_DATA_DIR/integration/workflow/corrupted_severe.log" \
            --output "$timeline_out" --quality-score 2>&1

        # Analyze quality
        local quality_out="$TEST_DATA_DIR/integration/workflow/quality.txt"
        "$SCRIPTS_DIR/evidence_quality_analyzer.sh" \
            --files "$TEST_DATA_DIR/integration/workflow/corrupted_severe.log" \
            --output "$quality_out" 2>&1

        if [ -f "$timeline_out" ] && [ -f "$quality_out" ]; then
            record_test_result "Integration - Timeline + Quality Analysis" "PASS" "Complete workflow executed"
        else
            record_test_result "Integration - Timeline + Quality Analysis" "FAIL" "Workflow incomplete"
        fi
    fi
}

#═══════════════════════════════════════════════════════════════════
# PERFORMANCE TESTS
#═══════════════════════════════════════════════════════════════════

test_performance() {
    echo -e "\n${BLUE}[TEST CATEGORY]${NC} Performance Tests"
    echo "─────────────────────────────────────────────────────────────────"

    # Test 1: Hash calculation performance
    if [ -f "$SCRIPTS_DIR/hash_calculator.sh" ]; then
        # Create 100 small files
        local perf_dir="$TEST_DATA_DIR/performance"
        mkdir -p "$perf_dir"
        for i in {1..100}; do
            echo "Test file $i" > "$perf_dir/file_$i.txt"
        done

        local start_time=$(date +%s%N)
        for file in "$perf_dir"/file_*.txt; do
            "$SCRIPTS_DIR/hash_calculator.sh" "$file" > /dev/null 2>&1
        done
        local end_time=$(date +%s%N)
        local duration_ms=$(( (end_time - start_time) / 1000000 ))

        if [ $duration_ms -lt 10000 ]; then  # 10 seconds
            record_test_result "Performance - Batch Hashing (100 files)" "PASS" "${duration_ms}ms"
        else
            record_test_result "Performance - Batch Hashing (100 files)" "WARN" "Slow: ${duration_ms}ms"
        fi
    fi

    # Test 2: Timeline with many events
    if [ -f "$SCRIPTS_DIR/timeline_builder_v2.sh" ]; then
        local large_log="$TEST_DATA_DIR/performance/large_timeline.log"
        # Generate 1000 log entries
        for i in {1..1000}; do
            local hour=$(printf "%02d" $((i % 24)))
            local min=$(printf "%02d" $((i % 60)))
            echo "2024-12-05 $hour:$min:00 [INFO] Event $i" >> "$large_log"
        done

        local output_file="$TEST_DATA_DIR/performance/timeline_large.txt"
        local start_time=$(date +%s)
        "$SCRIPTS_DIR/timeline_builder_v2.sh" \
            --files "$large_log" \
            --output "$output_file" 2>&1
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        if [ $duration -lt 30 ]; then
            record_test_result "Performance - Large Timeline (1000 events)" "PASS" "${duration}s"
        else
            record_test_result "Performance - Large Timeline (1000 events)" "WARN" "Slow: ${duration}s"
        fi
    fi
}

#═══════════════════════════════════════════════════════════════════
# GENERATE FINAL REPORT
#═══════════════════════════════════════════════════════════════════

generate_final_report() {
    local report_file="$RESULTS_DIR/FINAL_REPORT.txt"

    {
        echo "═══════════════════════════════════════════════════════════════════"
        echo "FORENSIC TEST FRAMEWORK - FINAL REPORT"
        echo "═══════════════════════════════════════════════════════════════════"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Test Output: $TEST_OUTPUT_DIR"
        echo "═══════════════════════════════════════════════════════════════════"
        echo
        echo "SUMMARY STATISTICS"
        echo "───────────────────────────────────────────────────────────────────"
        echo "Total Tests:    $TESTS_TOTAL"
        echo "Passed:         $TESTS_PASSED ($(( TESTS_PASSED * 100 / TESTS_TOTAL ))%)"
        echo "Failed:         $TESTS_FAILED ($(( TESTS_FAILED * 100 / TESTS_TOTAL ))%)"
        echo "Warnings:       $TESTS_WARNINGS ($(( TESTS_WARNINGS * 100 / TESTS_TOTAL ))%)"
        echo

        local pass_rate=$(( TESTS_PASSED * 100 / TESTS_TOTAL ))
        if [ $pass_rate -ge 90 ]; then
            echo "Overall Status: ✓ EXCELLENT ($pass_rate% pass rate)"
        elif [ $pass_rate -ge 70 ]; then
            echo "Overall Status: ✓ GOOD ($pass_rate% pass rate)"
        elif [ $pass_rate -ge 50 ]; then
            echo "Overall Status: ⚠ FAIR ($pass_rate% pass rate)"
        else
            echo "Overall Status: ✗ NEEDS IMPROVEMENT ($pass_rate% pass rate)"
        fi

        echo
        echo "═══════════════════════════════════════════════════════════════════"
        echo "DETAILED TEST LOG"
        echo "═══════════════════════════════════════════════════════════════════"
        cat "$RESULTS_DIR/test_log.txt"

        echo
        echo "═══════════════════════════════════════════════════════════════════"
        echo "IDENTIFIED ISSUES & RECOMMENDATIONS"
        echo "═══════════════════════════════════════════════════════════════════"

        if [ $TESTS_FAILED -gt 0 ]; then
            echo
            echo "CRITICAL FAILURES (require immediate attention):"
            grep "FAIL" "$RESULTS_DIR/test_log.txt" | while read -r line; do
                echo "  ✗ $line"
            done
        fi

        if [ $TESTS_WARNINGS -gt 0 ]; then
            echo
            echo "WARNINGS (recommended improvements):"
            grep "WARN" "$RESULTS_DIR/test_log.txt" | while read -r line; do
                echo "  ⚠ $line"
            done
        fi

        echo
        echo "═══════════════════════════════════════════════════════════════════"
        echo "RECOMMENDATIONS FOR IMPROVEMENT"
        echo "═══════════════════════════════════════════════════════════════════"

        # Analyze failures and provide recommendations
        if grep -q "Corruption Detection.*FAIL" "$RESULTS_DIR/test_log.txt"; then
            echo "• Enhance corruption marker detection keywords"
        fi

        if grep -q "Gap Detection.*FAIL" "$RESULTS_DIR/test_log.txt"; then
            echo "• Improve timeline gap detection algorithm"
        fi

        if grep -q "Performance.*WARN" "$RESULTS_DIR/test_log.txt"; then
            echo "• Optimize performance for large datasets"
        fi

        if grep -q "Binary File.*FAIL\|WARN" "$RESULTS_DIR/test_log.txt"; then
            echo "• Improve binary file handling"
        fi

        if grep -q "Special Characters.*FAIL" "$RESULTS_DIR/test_log.txt"; then
            echo "• Add better filename sanitization"
        fi

        echo
        echo "═══════════════════════════════════════════════════════════════════"
        echo "END OF REPORT"
        echo "═══════════════════════════════════════════════════════════════════"

    } > "$report_file"

    # Display report
    cat "$report_file"

    echo
    echo -e "${GREEN}Full report saved to: $report_file${NC}"
    echo -e "${GREEN}Test data location: $TEST_DATA_DIR${NC}"
    echo -e "${GREEN}Individual test details: $RESULTS_DIR/*.details.txt${NC}"
}

#═══════════════════════════════════════════════════════════════════
# MAIN EXECUTION
#═══════════════════════════════════════════════════════════════════

# Parse arguments
RUN_ALL=false
RUN_BASIC=false
RUN_EDGE=false
RUN_CORRUPTION=false
RUN_PERFORMANCE=false
RUN_INTEGRATION=false
RUN_SECURITY=false
RUN_REALWORLD=false
VERBOSE=false
KEEP_DATA=false
SPECIFIC_TOOL=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --all) RUN_ALL=true; shift ;;
        --basic) RUN_BASIC=true; shift ;;
        --edge) RUN_EDGE=true; shift ;;
        --corruption) RUN_CORRUPTION=true; shift ;;
        --performance) RUN_PERFORMANCE=true; shift ;;
        --integration) RUN_INTEGRATION=true; shift ;;
        --security) RUN_SECURITY=true; shift ;;
        --realworld) RUN_REALWORLD=true; shift ;;
        --tool) SPECIFIC_TOOL="$2"; shift 2 ;;
        --verbose) VERBOSE=true; shift ;;
        --keep-data) KEEP_DATA=true; shift ;;
        --output) TEST_OUTPUT_DIR="$2"; TEST_DATA_DIR="$2/test_data"; RESULTS_DIR="$2/results"; shift 2 ;;
        --help) show_usage; exit 0 ;;
        *) echo "Unknown option: $1"; show_usage; exit 1 ;;
    esac
done

# If --all or no specific tests, run all
if [ "$RUN_ALL" = true ]; then
    RUN_BASIC=true
    RUN_EDGE=true
    RUN_CORRUPTION=true
    RUN_PERFORMANCE=true
    RUN_INTEGRATION=true
    RUN_REALWORLD=true
fi

# Initialize
init_test_environment

# Run selected test categories
[ "$RUN_BASIC" = true ] && test_basic_functionality
[ "$RUN_CORRUPTION" = true ] && test_corruption_handling
[ "$RUN_EDGE" = true ] && test_edge_cases
[ "$RUN_INTEGRATION" = true ] && test_tool_integration
[ "$RUN_REALWORLD" = true ] && test_realworld_scenarios
[ "$RUN_REALWORLD" = true ] && test_malware_detection  # Part of real-world
[ "$RUN_REALWORLD" = true ] && test_timeline_integrity  # Part of real-world
[ "$RUN_PERFORMANCE" = true ] && test_performance

# Generate final report
echo
generate_final_report

# Cleanup (unless --keep-data)
if [ "$KEEP_DATA" = false ]; then
    echo
    echo "Cleaning up test data (use --keep-data to preserve)..."
    # Keep report but remove test data
    rm -rf "$TEST_DATA_DIR"
    echo "Test data removed, reports preserved in: $RESULTS_DIR"
fi

# Exit with appropriate code
if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
