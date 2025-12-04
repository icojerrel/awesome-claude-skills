# Security & Forensics Skill

Comprehensive digital forensics and security analysis skill for Claude Code, covering incident response, threat hunting, malware analysis, and forensic investigations.

## Overview

This skill equips Claude with advanced security and forensics capabilities, enabling comprehensive analysis of security incidents, suspicious files, system logs, and digital evidence.

## Features

### Core Capabilities

- **File Analysis & Metadata Extraction**: Comprehensive file analysis including hashes, entropy, EXIF data, and hidden content detection
- **Malware Analysis**: Static analysis of suspicious files, IOC extraction, and behavioral pattern detection
- **Log Analysis**: System and application log parsing, security event correlation, and timeline reconstruction
- **Threat Hunting**: Process analysis, network monitoring, persistence mechanism detection, and IOC hunting
- **Secure File Operations**: Multi-pass secure deletion, data wiping, and verification
- **Network Forensics**: PCAP analysis, connection monitoring, and traffic pattern analysis
- **Memory & Process Analysis**: Process memory dumps, running process enumeration, and analysis
- **Evidence Collection**: Proper evidence gathering with chain of custody documentation

### Use Cases

- Incident response and investigation
- Malware analysis (static)
- Security log analysis
- Threat hunting operations
- CTF (Capture The Flag) challenges
- Digital forensics investigations
- IOC (Indicators of Compromise) detection
- Security research and analysis
- Timeline reconstruction
- Evidence preservation and documentation

## Installation

### For Claude Code

1. Copy the skill directory to your Claude Code skills folder:
```bash
mkdir -p ~/.config/claude-code/skills/
cp -r security-forensics ~/.config/claude-code/skills/
```

2. Verify installation:
```bash
ls -la ~/.config/claude-code/skills/security-forensics/
```

3. Start Claude Code - the skill will load automatically:
```bash
claude
```

### For Claude.ai

1. Navigate to Claude.ai
2. Click the skills icon (🧩)
3. Upload the `security-forensics` folder or the `SKILL.md` file
4. The skill will activate automatically when relevant

## Helper Scripts

The skill includes several helper scripts in the `scripts/` directory:

### 1. Quick File Analysis (`quick_file_analysis.sh`)
Performs rapid triage of suspicious files with:
- File type identification
- Hash calculation (MD5, SHA1, SHA256)
- Entropy analysis
- String extraction (URLs, IPs, suspicious keywords)
- Magic byte analysis

**Usage:**
```bash
./scripts/quick_file_analysis.sh suspicious_file.exe
```

### 2. Hash Calculator (`hash_calculator.sh`)
Calculates multiple hash types for files:
- MD5, SHA1, SHA256, SHA512
- Batch processing support

**Usage:**
```bash
./scripts/hash_calculator.sh file1.bin file2.exe file3.dll
```

### 3. Log Analyzer (`log_analyzer.sh`)
Quick security log analysis:
- Failed authentication attempts
- Successful logins
- Sudo command history
- System errors
- Login history

**Usage:**
```bash
./scripts/log_analyzer.sh
```

### 4. Evidence Collector (`evidence_collector.sh`)
Comprehensive evidence collection with:
- System information
- Process snapshots
- Network connections
- Log files
- Chain of custody documentation
- Integrity hashing

**Usage:**
```bash
sudo ./scripts/evidence_collector.sh
```

### 5. IOC Scanner (`ioc_scanner.sh`)
Searches system for Indicators of Compromise:
- IP addresses in logs and connections
- File hashes in filesystem
- Domain names
- Suspicious file paths

**Usage:**
```bash
./scripts/ioc_scanner.sh ioc_list.txt
```

**Example IOC file format:**
```
# IP Addresses
192.168.1.100
203.0.113.50

# File Hashes (MD5 or SHA256)
d41d8cd98f00b204e9800998ecf8427e
a1b2c3d4e5f6...

# Domains
malicious.example.com
```

## Quick Start Examples

### Example 1: Analyze a Suspicious File
```
Analyze this file: downloaded.exe - is it malware?
```

Claude will:
- Calculate hashes
- Check file type and magic bytes
- Extract strings and search for IOCs
- Analyze entropy
- Provide comprehensive security assessment

### Example 2: Investigate Unauthorized Access
```
Check my system for signs of unauthorized access in the last 24 hours
```

Claude will:
- Check authentication logs
- Review recent file modifications
- Analyze network connections
- Look for persistence mechanisms
- Create timeline of suspicious events

### Example 3: Threat Hunting
```
Hunt for threats on this system - check for malware, suspicious processes, and backdoors
```

Claude will:
- Enumerate running processes
- Check network connections
- Search for SUID files
- Review scheduled tasks
- Identify persistence mechanisms
- Report all findings

### Example 4: Log Analysis
```
Analyze auth.log for brute force attempts
```

Claude will:
- Count failed login attempts
- Identify attacking IPs
- Show targeted accounts
- Create timeline
- Provide mitigation recommendations

### Example 5: Secure File Deletion
```
Securely wipe these sensitive documents using DoD standard
```

Claude will:
- Confirm deletion intent
- Use 3-pass overwrite (DoD 5220.22-M)
- Verify deletion
- Provide confirmation

## Best Practices

### Legal & Ethical
- ✅ Only analyze systems you own or have explicit permission to investigate
- ✅ Document all evidence handling (chain of custody)
- ✅ Work on copies, not original evidence
- ✅ Authorized security testing only (CTF, pentests, research)

### Technical
- ✅ Calculate hashes before and after analysis
- ✅ Use isolated environments for malware analysis (VMs/sandboxes)
- ✅ Document all steps and findings
- ✅ Note timezone differences in timestamps
- ✅ Never execute suspicious code on production systems

## Tools Required

### Included in Most Linux Systems
- `file`, `stat` - File information
- `md5sum`, `sha256sum` - Hashing
- `strings` - String extraction
- `xxd`, `hexdump` - Hex viewers
- `grep`, `awk`, `sed` - Text processing
- `ps`, `lsof`, `netstat`/`ss` - Process/network info
- `find` - File search

### Optional (Enhanced Functionality)
- `exiftool` - Advanced metadata extraction
- `tcpdump`/`wireshark` - Network analysis
- `binwalk` - Firmware analysis
- `volatility` - Memory forensics

## Security Warnings

⚠️ **IMPORTANT**:
- Never execute suspicious files on production systems
- Always work in isolated environments for malware analysis
- Secure deletion on SSDs may not be fully effective due to wear leveling
- Modern filesystems may cache/snapshot data
- Maintain proper chain of custody for legal cases
- Only perform authorized security testing

## Contributing

Found a bug or have a feature request? This skill is part of the [Awesome Claude Skills](https://github.com/anthropics/awesome-claude-skills) repository.

## License

This skill is provided as-is for educational and authorized security testing purposes only.

## Related Skills

- **test-driven-development** - For secure code development
- **software-architecture** - For secure architecture design
- **file-organizer** - For organizing forensics evidence
- **webapp-testing** - For web application security testing

## Additional Resources

### Learning Resources
- [SANS Digital Forensics](https://www.sans.org/cyber-security-courses/advanced-incident-response-threat-hunting-training/)
- [Malware Analysis Tutorials](https://malware.news/)
- [Threat Hunting Resources](https://www.threathunting.net/)
- [CTF Practice](https://ctftime.org/)

### Useful Tools
- [Autopsy](https://www.autopsy.com/) - Digital forensics platform
- [Volatility](https://www.volatilityfoundation.org/) - Memory forensics
- [The Sleuth Kit](https://www.sleuthkit.org/) - Forensics toolkit
- [YARA](https://virustotal.github.io/yara/) - Malware identification

## Support

For issues or questions about this skill:
- Open an issue in the Awesome Claude Skills repository
- Check the skill documentation in `SKILL.md`
- Review the example scripts for reference implementations
