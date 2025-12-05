# Forensic Tools Testing Framework

Comprehensive testing suite voor alle security-forensics tools om tekortkomingen te signaleren en verbeteringen aan te brengen.

## 📋 Overzicht

Dit test framework test **alle aspecten** van de forensische tools:

### Test Categorieën

1. **Basic Functionality** - Basis functionaliteit van alle tools
2. **Edge Cases** - Grensgevallen en ongebruikelijke input
3. **Corruption Handling** - Omgaan met beschadigde data
4. **Performance** - Snelheid en schaalbaarheid
5. **Integration** - Samenwerking tussen tools
6. **Security** - Veiligheidsaspecten
7. **Real-World Scenarios** - Realistische incident scenarios

## 🚀 Gebruik

### Quick Start - Alle Tests

```bash
cd security-forensics/tests
./forensic_test_framework.sh --all
```

### Specifieke Test Categorieën

```bash
# Alleen corruption handling testen
./forensic_test_framework.sh --corruption

# Edge cases + performance
./forensic_test_framework.sh --edge --performance

# Real-world scenarios
./forensic_test_framework.sh --realworld
```

### Test Specifieke Tool

```bash
# Test alleen metadata analyzer
./forensic_test_framework.sh --tool metadata_analyzer --all
```

### Advanced Opties

```bash
# Verbose mode met data behouden
./forensic_test_framework.sh --all --verbose --keep-data

# Custom output directory
./forensic_test_framework.sh --all --output /tmp/my_tests
```

## 🔒 Sandbox Testing (AANBEVOLEN!)

### Waarom Sandbox?

✅ **Veiligheid**
- Voorkomt contaminatie van productie omgeving
- Veilige malware analyse (gesimuleerde samples kunnen niet ontsnappen)
- Geen impact op host filesystem

✅ **Reproduceerbaarheid**
- Clean slate voor elke test run
- Consistente test omstandigheden
- Rollback capability

✅ **Isolatie**
- Geïsoleerde proces ruimte
- Network isolatie voor C&C simulatie
- Geen side-effects op host

### Sandbox Methoden

#### 1. Docker (Aanbevolen - Volledige isolatie)

```bash
# Maak Docker sandbox
./sandbox_test_environment.sh create --method docker

# Run tests in sandbox
./sandbox_test_environment.sh run "./forensic_test_framework.sh --all"

# Check status
./sandbox_test_environment.sh status

# Cleanup
./sandbox_test_environment.sh destroy
```

**Voordelen:**
- Volledige proces en network isolatie
- Read-only filesystem (behalve /tmp)
- Container wordt automatisch verwijderd na test
- Geen restanten op host systeem

#### 2. tmpfs (Snelst - RAM disk)

```bash
# Maak tmpfs sandbox (1GB RAM disk)
./sandbox_test_environment.sh create --method tmpfs

# Run tests
./sandbox_test_environment.sh run "./forensic_test_framework.sh --all"

# Cleanup
./sandbox_test_environment.sh destroy
```

**Voordelen:**
- Zeer snel (alles in RAM)
- Automatische cleanup bij reboot
- Geen disk I/O
- Lichtgewicht

#### 3. chroot (Linux - Middelmatig)

```bash
# Maak chroot sandbox
sudo ./sandbox_test_environment.sh create --method chroot

# Run tests
sudo ./sandbox_test_environment.sh run "./forensic_test_framework.sh --all"

# Cleanup
sudo ./sandbox_test_environment.sh destroy
```

**Voordelen:**
- Filesystem isolatie
- Process isolatie
- Geen Docker nodig

### Complete Test Workflow met Sandbox

```bash
# 1. Maak sandbox
./sandbox_test_environment.sh create --method docker

# 2. Run volledige test suite
./sandbox_test_environment.sh run "./forensic_test_framework.sh --all --verbose"

# 3. Check resultaten
./sandbox_test_environment.sh run "cat /tmp/forensic_tests_*/results/FINAL_REPORT.txt"

# 4. Cleanup
./sandbox_test_environment.sh destroy
```

## 📊 Test Output

### Locaties

```
/tmp/forensic_tests_YYYYMMDD_HHMMSS/
├── test_data/              # Gegenereerde test data
│   ├── basic/             # Clean evidence
│   ├── corruption/        # Corrupted files
│   ├── edge/              # Edge cases
│   ├── malware/           # Malware samples (safe)
│   ├── realworld/         # Incident scenarios
│   └── performance/       # Large datasets
├── results/
│   ├── FINAL_REPORT.txt   # ⭐ Hoofdrapport
│   ├── test_log.txt       # Detailed log
│   └── *.details.txt      # Per-test details
```

### Voorbeeld Output

```
═══════════════════════════════════════════════════════════════════
FORENSIC TEST FRAMEWORK - FINAL REPORT
═══════════════════════════════════════════════════════════════════

SUMMARY STATISTICS
───────────────────────────────────────────────────────────────────
Total Tests:    45
Passed:         38 (84%)
Failed:         3 (7%)
Warnings:       4 (9%)

Overall Status: ✓ GOOD (84% pass rate)

IDENTIFIED ISSUES & RECOMMENDATIONS
═══════════════════════════════════════════════════════════════════

CRITICAL FAILURES (require immediate attention):
  ✗ Timeline - Corruption Warnings - Failed to detect corruption markers
  ✗ IOC Scanner - Pattern Detection - Failed on binary data

WARNINGS (recommended improvements):
  ⚠ Metadata - Binary File - Issues with binary file handling
  ⚠ Performance - Large Timeline (1000 events) - Slow: 35s

RECOMMENDATIONS FOR IMPROVEMENT
═══════════════════════════════════════════════════════════════════
• Enhance corruption marker detection keywords
• Improve binary file handling
• Optimize performance for large datasets
```

## 🧪 Wat wordt getest?

### Basic Functionality Tests

- ✅ Hash Calculator - MD5, SHA1, SHA256 berekening
- ✅ Metadata Analyzer - Filesystem & EXIF metadata extractie
- ✅ Timeline Builder - Chronologische event reconstructie
- ✅ Evidence Quality Analyzer - Scoring algorithm
- ✅ Chain of Custody - Evidence collection workflow
- ✅ IOC Scanner - Pattern detection

### Corruption Handling Tests

- ✅ Detectie van corruption markers in bestanden
- ✅ Handling van incomplete logs met gaps
- ✅ Metadata extractie uit beschadigde documenten
- ✅ Quality score berekening voor corrupted evidence
- ✅ Timeline met missing entries
- ✅ Warnings in output voor data loss

### Edge Case Tests

- ✅ Empty files (0 bytes)
- ✅ Very large files (10MB+)
- ✅ Binary data handling
- ✅ Special characters in filenames (`!@#$%^&*`)
- ✅ Very long filenames (200+ chars)
- ✅ Files zonder extensie
- ✅ Unicode filenames (中文, العربية, etc.)

### Performance Tests

- ✅ Batch hashing (100 files)
- ✅ Large timeline (1000+ events)
- ✅ Multiple log correlation
- ✅ Memory usage profiling
- ✅ Execution time benchmarks

### Integration Tests

- ✅ Chain of custody → Hash verification workflow
- ✅ Timeline builder → Evidence quality analyzer workflow
- ✅ Multi-tool incident investigation pipeline
- ✅ Data flow between tools

### Real-World Scenario Tests

- ✅ **Ransomware Incident**
  - Email attachment execution
  - Mass file encryption
  - C&C communication
  - Data exfiltration
  - Antivirus detection

- ✅ **Phishing Attack**
  - Credential submission
  - Account compromise
  - Email forwarding rule creation
  - Geographic anomaly detection

- ✅ **Malware Analysis**
  - IOC extraction (IPs, domains, URLs)
  - Suspicious string detection
  - Network indicators
  - Behavioral patterns

### Security Tests

- ✅ Malicious input handling
- ✅ Path traversal prevention
- ✅ Command injection prevention
- ✅ Resource exhaustion protection

## 📈 Continuous Improvement

### Tekortkomingen Identificeren

Het framework identificeert automatisch:

1. **CRITICAL** - Tools die falen op basic input
2. **HIGH** - Corruption niet gedetecteerd
3. **MEDIUM** - Performance problemen
4. **LOW** - Edge cases niet gehandled

### Verbeteringen Implementeren

Workflow:

```bash
# 1. Run tests en identificeer issues
./forensic_test_framework.sh --all > /tmp/test_results.txt

# 2. Analyseer failures
grep "FAIL\|WARN" /tmp/test_results.txt

# 3. Fix issues in tools
# ... code improvements ...

# 4. Re-run specifieke tests
./forensic_test_framework.sh --corruption --edge

# 5. Verify fixes
# Check dat FAIL → PASS
```

### Regression Testing

```bash
# Voor elke code wijziging:
./forensic_test_framework.sh --all

# Vergelijk met vorige run:
diff previous_report.txt current_report.txt
```

## 🎯 Success Criteria

### Minimale Vereisten

- **Pass Rate**: ≥ 90% (Excellent)
- **No Critical Failures**: 0 FAIL tests in basic functionality
- **Corruption Detection**: 100% van corruption markers gedetecteerd
- **Performance**: <30s voor 1000 events timeline

### Ideale Doelen

- **Pass Rate**: 100%
- **Performance**: <10s voor 1000 events
- **Edge Cases**: Alle edge cases zonder warnings
- **Real-World**: Alle incidents correct gereconstrueerd

## 🔧 Troubleshooting

### Test Fails

```bash
# Check details van specific failure
cat /tmp/forensic_tests_*/results/Test_Name.details.txt

# Run single test in verbose mode
./forensic_test_framework.sh --basic --verbose --keep-data

# Inspect generated test data
ls -la /tmp/forensic_tests_*/test_data/
```

### Sandbox Issues

```bash
# Docker permission denied
sudo usermod -aG docker $USER
newgrp docker

# tmpfs mount failed
sudo ./sandbox_test_environment.sh create --method tmpfs

# chroot requires sudo
sudo -E ./sandbox_test_environment.sh create --method chroot
```

## 📝 Adding New Tests

### Custom Test Function

```bash
test_my_custom_feature() {
    echo -e "\n${BLUE}[TEST CATEGORY]${NC} My Custom Tests"
    echo "─────────────────────────────────────────────────────────────────"

    # Setup test data
    echo "test data" > "$TEST_DATA_DIR/custom/test.txt"

    # Run tool
    local output=$("$SCRIPTS_DIR/my_tool.sh" "$TEST_DATA_DIR/custom/test.txt" 2>&1)

    # Verify result
    if echo "$output" | grep -q "expected pattern"; then
        record_test_result "My Tool - Basic" "PASS" "Test passed"
    else
        record_test_result "My Tool - Basic" "FAIL" "Expected pattern not found" "$output"
    fi
}
```

### Register Test

Add to main execution block in `forensic_test_framework.sh`:

```bash
[ "$RUN_CUSTOM" = true ] && test_my_custom_feature
```

## 📚 Referenties

- **NIST SP 800-86** - Guide to Integrating Forensic Techniques into Incident Response
- **ISO/IEC 27037** - Guidelines for identification, collection, acquisition and preservation of digital evidence
- **ACPO Principles** - UK Good Practice Guide for Digital Evidence

## ⚡ Quick Reference

```bash
# Complete test run met sandbox
./sandbox_test_environment.sh create --method docker
./sandbox_test_environment.sh run "./forensic_test_framework.sh --all"
cat /tmp/forensic_tests_*/results/FINAL_REPORT.txt
./sandbox_test_environment.sh destroy

# Test specifieke category
./forensic_test_framework.sh --corruption --edge

# Performance benchmark
./forensic_test_framework.sh --performance --verbose

# Real-world scenarios only
./forensic_test_framework.sh --realworld --keep-data
```

---

**Ontwikkeld voor**: security-forensics skill
**Versie**: 1.0
**Laatst bijgewerkt**: 2024-12-05
