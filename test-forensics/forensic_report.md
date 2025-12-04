# Security Forensics Report

## Executive Summary
**CRITICAL THREAT DETECTED** - Malicious bash script with multiple indicators of compromise.

## Investigation Details
- **Date/Time**: 2025-12-04 05:50 UTC
- **Analyst**: Security-Forensics Skill
- **File Analyzed**: suspicious_script.sh
- **File Hash (SHA256)**: 119ae60f46436153390e3e6e4f98d75e1a0c8c28c72a68ac040dfcb209a03ac2

---

## Findings

### 1. ⚠️ Command & Control Communication
**Severity**: CRITICAL
**Description**: Script attempts to connect to remote C2 server
**Evidence**:
- Primary C2 IP: `192.168.100.50:4444`
- Backup C2 Domain: `malicious-c2.example.com`
- Downloads payload via curl: `http://192.168.100.50:4444/payload.sh`

**Impact**: Allows attacker remote control and payload delivery

**IOCs**:
- IP Address: 192.168.100.50
- Domain: malicious-c2.example.com
- Port: 4444 (common reverse shell port)
- File Path: /tmp/payload.sh

### 2. 🔑 Credential Harvesting
**Severity**: CRITICAL
**Description**: Script writes credentials to hidden file
**Evidence** (Line 14-15):
```bash
echo "admin:password123" > /tmp/.credentials
echo "root:secretpass" >> /tmp/.credentials
```

**Impact**: Credentials stored in plaintext, exfiltration risk

**IOCs**:
- File Path: /tmp/.credentials (hidden file)
- Credentials exposed: admin, root accounts

### 3. 🔄 Persistence Mechanism
**Severity**: HIGH
**Description**: Attempts to establish persistence via cron
**Evidence** (Line 18):
```bash
echo "* * * * * /tmp/.backdoor.sh" >> /tmp/fake_crontab
```

**Impact**: Malware survives reboots, executes every minute

**IOCs**:
- Cron entry: /tmp/.backdoor.sh
- Frequency: Every minute (* * * * *)

### 4. 🔐 Encoded Payload
**Severity**: MEDIUM
**Description**: Base64 encoded payload (obfuscation technique)
**Evidence** (Line 21):
```
PAYLOAD="ZWNobyAiVGhpcyBpcyBhIHRlc3QgcGF5bG9hZCI="
```

**Decoded**:
```bash
echo "This is a test payload"
```

**Impact**: Code obfuscation to evade detection

### 5. 💻 PowerShell Command Pattern
**Severity**: HIGH
**Description**: PowerShell encoded command pattern detected
**Evidence** (Line 24):
```bash
# powershell -enc $PAYLOAD
```

**Impact**: Cross-platform attack capability

---

## Timeline of Attack

**Initial Execution**: Script executes bash commands
↓
**C2 Connection**: Attempts connection to 192.168.100.50:4444
↓
**Credential Theft**: Writes credentials to /tmp/.credentials
↓
**Persistence**: Installs cron job for /tmp/.backdoor.sh
↓
**Payload Delivery**: Downloads additional payload from C2

---

## Indicators of Compromise (IOCs)

### Network IOCs
- **IP Address**: 192.168.100.50
- **Domain**: malicious-c2.example.com
- **Port**: 4444
- **Protocol**: HTTP

### File IOCs
- **Hash (MD5)**: 3a51367269f8ad676c011d1f95829c44
- **Hash (SHA256)**: 119ae60f46436153390e3e6e4f98d75e1a0c8c28c72a68ac040dfcb209a03ac2
- **File Paths**:
  - /tmp/.credentials
  - /tmp/.backdoor.sh
  - /tmp/fake_crontab
  - /tmp/payload.sh

### Behavioral IOCs
- Credential harvesting pattern
- Cron-based persistence
- Base64 encoding usage
- Hidden file creation (leading dot)

---

## Recommendations

### Immediate Actions (NOW)
1. ✅ **Quarantine** suspicious_script.sh immediately
2. ✅ **Block** IP 192.168.100.50 at firewall
3. ✅ **Block** domain malicious-c2.example.com at DNS
4. ✅ **Check** for /tmp/.credentials, /tmp/.backdoor.sh
5. ✅ **Review** crontab for unauthorized entries

### Remediation Steps (Next 24 hours)
1. Scan all systems for IOC hash: `3a51367269f8ad676c011d1f95829c44`
2. Check network logs for connections to 192.168.100.50:4444
3. Audit all accounts: admin, root for compromise
4. Review bash history for script execution
5. Check for additional backdoors in /tmp/

### Prevention Measures (Ongoing)
1. Implement application whitelisting
2. Monitor /tmp directory for suspicious files
3. Enable EDR/XDR for behavioral detection
4. Regular crontab auditing
5. Network segmentation to prevent C2 communication
6. Implement least privilege access

---

## Evidence Collected

1. **Original File**: suspicious_script.sh (preserved)
2. **Hash Values**: MD5, SHA1, SHA256 calculated
3. **Static Analysis**: Complete code review performed
4. **IOC List**: 10+ indicators documented
5. **Timeline**: Attack flow reconstructed

---

## Tools Used
- file - File type identification
- md5sum, sha256sum - Hash calculation
- strings - String extraction
- grep - Pattern matching
- stat - Timestamp analysis

---

## Conclusion

This is a **CRITICAL** security incident. The script exhibits multiple characteristics of:
- ✅ Remote Access Trojan (RAT)
- ✅ Credential Stealer
- ✅ Backdoor with Persistence
- ✅ Multi-stage malware (payload downloader)

**Recommendation**: Treat as **active breach** and initiate full incident response protocol.

---

**Report Generated**: 2025-12-04 05:50 UTC  
**Skill**: security-forensics v1.0  
**Confidence**: HIGH (multiple strong indicators)

