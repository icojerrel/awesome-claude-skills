---
name: security-forensics
description: Comprehensive digital forensics and security analysis tool for incident response, threat hunting, malware analysis, log analysis, metadata extraction, secure file operations, and CTF challenges. Use when investigating security incidents, analyzing suspicious files, hunting threats, or performing forensic investigations.
---

# Security & Forensics

This skill provides comprehensive digital forensics and security analysis capabilities for incident response, threat hunting, malware analysis, and forensic investigations.

## When to Use This Skill

- Investigating security incidents or breaches
- Analyzing suspicious files or malware
- Extracting and analyzing file metadata
- Performing threat hunting activities
- Analyzing system and application logs
- Conducting digital forensics investigations
- Solving CTF (Capture The Flag) challenges
- Performing security research
- Securely deleting sensitive files
- Analyzing network traffic captures
- Memory forensics and analysis
- Timeline reconstruction
- Evidence collection and preservation

## Capabilities

### 1. File Analysis & Metadata Extraction
- Extract comprehensive file metadata (EXIF, timestamps, permissions)
- Analyze file signatures and magic bytes
- Identify file types and anomalies
- Extract embedded data and hidden content
- Hash calculation (MD5, SHA1, SHA256, SHA512)
- Entropy analysis for detecting encryption/compression

### 2. Malware Analysis
- Static analysis (strings, imports, PE headers)
- Hash-based malware identification
- Behavioral indicators extraction
- Suspicious pattern detection
- Packer/obfuscation detection
- Network indicators extraction

### 3. Log Analysis
- System log parsing (syslog, auth.log, kern.log)
- Application log analysis
- Web server log analysis (Apache, Nginx)
- Security event correlation
- Timeline reconstruction
- Anomaly detection in logs

### 4. Threat Hunting
- Process analysis and suspicious behavior detection
- Network connection analysis
- File system forensics
- Persistence mechanism detection
- IOC (Indicators of Compromise) identification
- Sigma rule application (when rules available)

### 5. Secure File Operations
- Secure file deletion (multiple overwrite passes)
- Data wiping verification
- Secure file comparison
- File carving and recovery

### 6. Network Forensics
- PCAP file analysis (with tcpdump/tshark if available)
- Network connection analysis
- DNS query analysis
- HTTP traffic extraction

### 7. Memory & System Analysis
- Process memory dumps analysis
- Running process enumeration
- Open file descriptors analysis
- Network connections analysis

## Instructions

When a user requests security or forensics assistance:

### 1. Understand the Scope and Context

Ask clarifying questions:
- What type of investigation? (incident response, malware analysis, threat hunting, CTF)
- What evidence or files need analysis?
- What's the suspected threat or issue?
- Any specific IOCs (Indicators of Compromise) to search for?
- Legal/authorization context? (authorized testing only)
- What's the goal? (identify malware, find intrusion point, timeline reconstruction)

**IMPORTANT**: Only perform security testing and forensics on:
- Systems you own or have explicit authorization to test
- CTF environments and challenges
- Security research in authorized contexts
- Educational purposes with proper authorization

### 2. File Metadata Extraction & Analysis

When analyzing files:

```bash
# Get basic file information
file -b [filename]
stat [filename]

# Calculate file hashes
md5sum [filename]
sha1sum [filename]
sha256sum [filename]
sha512sum [filename]

# Extract strings from binary
strings [filename] | head -100
strings -n 8 [filename]  # Longer strings (8+ chars)

# Check file type and magic bytes
xxd [filename] | head -20
hexdump -C [filename] | head -20

# For images - extract EXIF data
exiftool [filename] 2>/dev/null || identify -verbose [filename]

# Check file entropy (high entropy = encrypted/compressed)
ent [filename] 2>/dev/null || python3 -c "
import math
from collections import Counter
with open('[filename]', 'rb') as f:
    data = f.read()
    if data:
        counter = Counter(data)
        entropy = -sum(count/len(data) * math.log2(count/len(data)) for count in counter.values())
        print(f'Entropy: {entropy:.4f} bits/byte')
        print('High entropy (>7.5): Likely encrypted/compressed' if entropy > 7.5 else 'Normal entropy')
"

# Get extended attributes
getfattr -d [filename] 2>/dev/null || xattr -l [filename] 2>/dev/null
```

**Present findings**:
- File type and format
- Hash values (for threat intelligence lookup)
- Timestamps (created, modified, accessed)
- Size and permissions
- Entropy analysis results
- Extracted metadata
- Suspicious indicators

### 3. Malware Analysis (Static)

When analyzing potentially malicious files:

**SAFETY FIRST**:
- Always work in isolated environment
- Never execute malware on production systems
- Use sandboxes or VMs when available

```bash
# Basic static analysis
echo "=== File Information ==="
file [malware_sample]
ls -lh [malware_sample]

echo "=== Hash Values ==="
md5sum [malware_sample]
sha256sum [malware_sample]

echo "=== Strings Analysis ==="
strings [malware_sample] | grep -E "(http|ftp|\.exe|\.dll|HKEY|\\Users|\\Windows)" | head -50

# Look for suspicious patterns
echo "=== Suspicious Patterns ==="
strings [malware_sample] | grep -iE "(password|admin|cmd|powershell|exploit|payload|shell)"

# Check for embedded URLs/IPs
echo "=== Network Indicators ==="
strings [malware_sample] | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u
strings [malware_sample] | grep -oE 'https?://[^\s]+' | sort -u

# For ELF binaries - check headers and sections
readelf -h [malware_sample] 2>/dev/null
readelf -S [malware_sample] 2>/dev/null

# For PE files - use objdump if available
objdump -p [malware_sample] 2>/dev/null | head -100

# Check for packed/obfuscated binaries
echo "=== Packing Detection ==="
strings [malware_sample] | wc -l
# Few strings + high entropy = likely packed
```

**Report**:
1. File identification and hash values
2. Extracted strings and their significance
3. Network indicators (IPs, URLs, domains)
4. Suspicious API calls or functions
5. Packing or obfuscation indicators
6. Behavioral indicators
7. Recommended next steps

### 4. Log Analysis

When analyzing logs:

```bash
# System logs
echo "=== Recent Authentication Attempts ==="
grep -i "failed\|failure\|invalid" /var/log/auth.log 2>/dev/null | tail -50

echo "=== Successful Logins ==="
grep -i "accepted\|session opened" /var/log/auth.log 2>/dev/null | tail -30

echo "=== Sudo Commands ==="
grep -i "sudo:" /var/log/auth.log 2>/dev/null | tail -30

# Web server logs (if available)
echo "=== Suspicious Web Requests ==="
grep -E "(union select|script>|exec\(|\.\.\/)" /var/log/apache2/access.log /var/log/nginx/access.log 2>/dev/null | tail -50

echo "=== 404 Scanning Attempts ==="
grep " 404 " /var/log/apache2/access.log /var/log/nginx/access.log 2>/dev/null | cut -d' ' -f1,7 | sort | uniq -c | sort -rn | head -20

echo "=== Top IPs by Request Count ==="
awk '{print $1}' /var/log/apache2/access.log /var/log/nginx/access.log 2>/dev/null | sort | uniq -c | sort -rn | head -20

# System errors
echo "=== Recent System Errors ==="
grep -i "error\|critical\|alert" /var/log/syslog 2>/dev/null | tail -50
dmesg | grep -i "error\|fail" | tail -30

# Look for specific IOCs in logs
echo "=== Searching for IOCs ==="
# Example: grep -r "malicious.domain.com" /var/log/ 2>/dev/null
```

**Timeline Creation**:
```bash
# Create unified timeline from multiple log sources
echo "=== Timeline of Events ==="
# Combine and sort by timestamp
tail -n 100 /var/log/auth.log /var/log/syslog /var/log/apache2/access.log 2>/dev/null | \
  grep -E '^[A-Z][a-z]{2}\s+[0-9]' | sort -M -k1 -k2 -k3
```

### 5. Threat Hunting

When hunting for threats:

```bash
# Running processes analysis
echo "=== Suspicious Processes ==="
ps aux --sort=-%cpu | head -20
ps aux --sort=-%mem | head -20

# Look for processes running from unusual locations
ps aux | grep -v -E '(/usr/|/bin/|/sbin/)'

# Network connections
echo "=== Active Network Connections ==="
netstat -tunap 2>/dev/null || ss -tunap 2>/dev/null
lsof -i -P -n 2>/dev/null | grep ESTABLISHED

# Find files modified recently
echo "=== Recently Modified Files ==="
find /tmp /var/tmp /dev/shm -type f -mtime -1 -ls 2>/dev/null
find /etc -type f -mtime -1 -ls 2>/dev/null
find /home -type f -mtime -1 -ls 2>/dev/null | head -50

# Check for hidden files in suspicious locations
echo "=== Hidden Files ==="
find /tmp /var/tmp /dev/shm -name ".*" -type f 2>/dev/null

# SUID/SGID files (potential privilege escalation)
echo "=== SUID/SGID Files ==="
find / -type f \( -perm -4000 -o -perm -2000 \) -ls 2>/dev/null | head -30

# Check cron jobs and scheduled tasks
echo "=== Scheduled Tasks ==="
cat /etc/crontab 2>/dev/null
ls -la /etc/cron.* 2>/dev/null
crontab -l 2>/dev/null

# Check for persistence mechanisms
echo "=== Persistence Mechanisms ==="
cat /etc/rc.local 2>/dev/null
ls -la /etc/init.d/ 2>/dev/null
systemctl list-unit-files --type=service --state=enabled 2>/dev/null | grep -v "^$"

# Check loaded kernel modules
echo "=== Kernel Modules ==="
lsmod | head -20
```

**IOC Hunting**:
```bash
# Search entire filesystem for specific IOCs
# Example: IP addresses, domains, file hashes
grep -r "192.168.1.100" /var/log/ 2>/dev/null
find / -name "suspicious_filename.exe" 2>/dev/null
find / -type f -exec md5sum {} \; 2>/dev/null | grep "known_malware_hash"
```

### 6. Secure File Deletion

When securely deleting files:

```bash
# Single overwrite (fast)
shred -vfz -n 1 [filename]

# Multiple overwrites (DoD 5220.22-M standard - 3 passes)
shred -vfz -n 3 [filename]

# Secure deletion with 7 passes
shred -vfz -n 7 [filename]

# Securely wipe and delete
shred -vfzu -n 3 [filename]

# For entire directories
find [directory] -type f -exec shred -vfzu -n 3 {} \;

# Wipe free space on partition (careful!)
# dd if=/dev/zero of=/tmp/zero.file bs=1M
# rm /tmp/zero.file

# Verify file is actually deleted
ls -la [filename]  # Should not exist
```

**IMPORTANT**:
- Always confirm with user before deletion
- Explain that SSD/flash storage may retain data due to wear leveling
- Recommend full disk encryption for sensitive data
- Modern filesystems may have copies (snapshots, journaling)

### 7. Network Forensics

When analyzing network traffic:

```bash
# Analyze PCAP file with tcpdump
tcpdump -r [capture.pcap] -n | head -100
tcpdump -r [capture.pcap] -n 'port 80 or port 443'
tcpdump -r [capture.pcap] -n 'host 192.168.1.100'

# Extract HTTP traffic
tcpdump -r [capture.pcap] -A 'tcp port 80'

# DNS queries
tcpdump -r [capture.pcap] -n 'port 53'

# Statistics
tcpdump -r [capture.pcap] -qn | awk '{print $3}' | sort | uniq -c | sort -rn | head -20

# Current live connections
netstat -tunap 2>/dev/null | grep ESTABLISHED
ss -tunap 2>/dev/null | grep ESTABLISHED

# Connection statistics
netstat -s 2>/dev/null || ss -s 2>/dev/null
```

### 8. Memory & Process Analysis

When analyzing process memory:

```bash
# Dump process memory (requires privileges)
cat /proc/[PID]/maps
cat /proc/[PID]/status
cat /proc/[PID]/cmdline
strings /proc/[PID]/environ

# Analyze process
lsof -p [PID]
cat /proc/[PID]/fd
ls -la /proc/[PID]/fd/

# Search for strings in process memory
gdb -p [PID] -batch -ex 'dump memory /tmp/mem.dump 0x0 0xffffffffffffffff' 2>/dev/null
strings /tmp/mem.dump | grep -i "password\|key\|token"
```

### 9. Timeline Reconstruction

When reconstructing incident timeline:

```bash
# Collect all timestamps
echo "=== File Timeline ==="
find [directory] -type f -printf '%T+ %p\n' | sort

# System timeline
echo "=== System Events Timeline ==="
journalctl --since "2024-01-01" --until "2024-01-02" -o short-iso

# Combine multiple sources
echo "=== Unified Timeline ==="
# Parse and combine auth.log, syslog, application logs by timestamp
```

**Present timeline as**:
```markdown
# Incident Timeline

## 2024-12-04 10:23:15 - Initial Access
- Source IP: X.X.X.X
- Method: SSH brute force
- Evidence: /var/log/auth.log:1234

## 2024-12-04 10:25:42 - Privilege Escalation
- File modified: /etc/sudoers
- Evidence: stat output

[Continue chronologically...]
```

### 10. Evidence Collection

When collecting evidence:

```bash
# Create evidence directory with timestamp
EVIDENCE_DIR="evidence_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$EVIDENCE_DIR"

# Collect system information
uname -a > "$EVIDENCE_DIR/system_info.txt"
date > "$EVIDENCE_DIR/collection_time.txt"
whoami > "$EVIDENCE_DIR/collector.txt"

# Hash original files before collection
md5sum [evidence_file] > "$EVIDENCE_DIR/original_hashes.txt"

# Copy with metadata preservation
cp -p [evidence_file] "$EVIDENCE_DIR/"

# Document chain of custody
echo "Evidence collected: $(date)" >> "$EVIDENCE_DIR/chain_of_custody.txt"
echo "Collector: $(whoami)" >> "$EVIDENCE_DIR/chain_of_custody.txt"
echo "Hostname: $(hostname)" >> "$EVIDENCE_DIR/chain_of_custody.txt"

# Create archive
tar -czf "${EVIDENCE_DIR}.tar.gz" "$EVIDENCE_DIR"
sha256sum "${EVIDENCE_DIR}.tar.gz" > "${EVIDENCE_DIR}.tar.gz.sha256"
```

### 11. Reporting

After analysis, provide structured report:

```markdown
# Security Forensics Report

## Executive Summary
[Brief overview of findings]

## Investigation Details
- Date/Time: [timestamp]
- Analyst: [name]
- Case ID: [if applicable]
- Systems Analyzed: [list]

## Findings

### 1. [Finding Title]
**Severity**: Critical/High/Medium/Low
**Description**: [What was found]
**Evidence**: [File paths, log entries, screenshots]
**Impact**: [What this means]
**IOCs**:
- File hash: [hash]
- IP address: [IP]
- Domain: [domain]

### 2. [Next Finding]
[Continue...]

## Timeline of Events
[Chronological reconstruction]

## Indicators of Compromise (IOCs)
- File Hashes: [list]
- IP Addresses: [list]
- Domains: [list]
- File Paths: [list]
- Registry Keys: [if Windows]

## Recommendations
1. [Immediate actions]
2. [Remediation steps]
3. [Prevention measures]

## Evidence Collected
[List of collected evidence with hashes]

## Tools Used
[List of tools and commands used in analysis]
```

## Examples

### Example 1: Analyzing Suspicious File

**User**: "Analyze this file 'suspicious.exe' - it appeared in my Downloads folder"

**Process**:
1. Calculate hashes (MD5, SHA256)
2. Check file type and magic bytes
3. Extract strings and look for IOCs
4. Calculate entropy
5. Search for network indicators (IPs, URLs)
6. Check against known malware signatures
7. Provide comprehensive report with recommendations

**Output**:
```markdown
# Analysis: suspicious.exe

## File Information
- Type: PE32 executable
- Size: 245,760 bytes
- MD5: a1b2c3d4e5f6...
- SHA256: 1234567890ab...
- Entropy: 7.8 (HIGH - likely packed/encrypted)

## Suspicious Indicators
- High entropy suggests packing
- Found URL: http://malicious-c2.com/gate.php
- Found IP: 192.168.100.50
- Strings indicate PowerShell download cradle
- Creates registry run key for persistence

## Recommendation
🚨 MALWARE DETECTED - DO NOT EXECUTE
- Quarantine file immediately
- Scan system with updated antivirus
- Check for persistence mechanisms
- Monitor for C2 communications to 192.168.100.50
```

### Example 2: Incident Response - Unauthorized Access

**User**: "I suspect someone accessed my server. Can you investigate?"

**Process**:
1. Check auth logs for failed/successful logins
2. Analyze recent commands (bash history)
3. Check for new users or modified files
4. Review network connections
5. Look for persistence mechanisms
6. Create timeline of events

**Output**: [Detailed timeline with evidence and IOCs]

### Example 3: Log Analysis - Brute Force Detection

**User**: "Analyze auth.log for brute force attempts"

**Output**:
```markdown
# Brute Force Detection Report

## Summary
Detected 1,247 failed SSH login attempts from 15 unique IPs

## Top Attacking IPs
1. 203.0.113.50 - 456 attempts
2. 198.51.100.23 - 234 attempts
3. 192.0.2.100 - 189 attempts

## Targeted Accounts
- root: 876 attempts
- admin: 234 attempts
- ubuntu: 137 attempts

## Timeline
First attempt: 2024-12-04 02:13:45
Last attempt: 2024-12-04 08:45:22
Duration: 6 hours 31 minutes

## Successful Logins
⚠️ 1 successful login detected:
- Time: 2024-12-04 08:45:30
- User: root
- IP: 203.0.113.50

## Recommendations
1. Block IPs immediately
2. Investigate root session from 203.0.113.50
3. Implement fail2ban
4. Disable root SSH login
5. Enable 2FA
```

### Example 4: CTF Challenge - Hidden Data Extraction

**User**: "Help me solve this CTF challenge. I have an image file that supposedly contains hidden data"

**Process**:
1. Extract EXIF metadata
2. Check for steganography
3. Analyze file structure
4. Look for embedded files
5. Check LSB (Least Significant Bit) encoding

## Common Forensics Commands Reference

### File Analysis
```bash
file [filename]           # Identify file type
stat [filename]          # File metadata and timestamps
md5sum [filename]        # MD5 hash
sha256sum [filename]     # SHA256 hash
strings [filename]       # Extract readable strings
xxd [filename]           # Hex dump
exiftool [filename]      # EXIF metadata
```

### System Investigation
```bash
ps aux                   # Running processes
netstat -tunap          # Network connections
lsof -i                 # Open network files
last                    # Login history
w                       # Who is logged in
history                 # Command history
```

### Log Analysis
```bash
grep -i "error" /var/log/syslog
tail -f /var/log/auth.log
journalctl -xe
dmesg | grep -i error
```

### Evidence Collection
```bash
tar -czf evidence.tar.gz [files]
sha256sum evidence.tar.gz
dd if=/dev/sda of=image.dd bs=4M  # Disk imaging (careful!)
```

## Best Practices

### Legal & Ethical
1. **Authorization**: Only analyze systems you own or have explicit permission to investigate
2. **Chain of Custody**: Document all evidence handling
3. **Non-Destructive**: Preserve original evidence, work on copies
4. **Documentation**: Record all steps and findings

### Technical
1. **Hash Everything**: Calculate hashes before and after to prove integrity
2. **Use Write Blockers**: When imaging physical media
3. **Work on Copies**: Never analyze original evidence directly
4. **Time Synchronization**: Note timezone differences in timestamps
5. **Isolated Environment**: Analyze malware in sandboxes/VMs

### Investigation Process
1. **Preparation**: Gather tools and understand the scope
2. **Identification**: What evidence exists?
3. **Preservation**: Protect evidence from modification
4. **Collection**: Gather evidence properly
5. **Analysis**: Examine and interpret evidence
6. **Documentation**: Record findings
7. **Presentation**: Create clear reports

## Tools Reference

### Available on Most Linux Systems
- `file`, `stat` - File information
- `strings` - Extract strings
- `xxd`, `hexdump` - Hex viewers
- `md5sum`, `sha256sum` - Hashing
- `grep`, `awk`, `sed` - Text processing
- `tcpdump` - Network analysis
- `ps`, `lsof`, `netstat` - Process/network info
- `find` - File search
- `shred` - Secure deletion

### Optional Tools (install if needed)
- `exiftool` - Metadata extraction
- `binwalk` - Firmware analysis
- `volatility` - Memory forensics
- `autopsy` - Disk forensics
- `wireshark` - Network analysis
- `radare2` - Reverse engineering

## Security Warnings

🚨 **IMPORTANT**:
- Never execute suspicious files on production systems
- Always work in isolated environments (VMs, sandboxes)
- Malware analysis requires proper containment
- Secure deletion on SSDs may not be fully effective
- Modern filesystems may cache/snapshot data
- Always maintain chain of custody for legal cases

## Related Use Cases

- Security incident investigation
- Malware analysis and reverse engineering
- CTF (Capture The Flag) competitions
- Digital forensics for legal cases
- Threat hunting and IOC identification
- Security research and vulnerability analysis
- Log analysis and SIEM investigation
- Data recovery and file carving
- Network traffic analysis
- Memory forensics

## Quick Start Examples

**Analyze a suspicious file**:
```
Analyze this file: suspicious.bin - tell me if it's malware
```

**Investigate unauthorized access**:
```
Check auth logs for unauthorized access attempts in the last 24 hours
```

**Hunt for threats**:
```
Search for signs of compromise on this system - check processes, network connections, and recent file modifications
```

**Extract metadata**:
```
Extract all metadata from these images in the /evidence folder
```

**Secure delete**:
```
Securely wipe these sensitive files using DoD standard
```

**Analyze network capture**:
```
Analyze this PCAP file for suspicious HTTP traffic
```
