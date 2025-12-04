#!/bin/bash
# IOC Scanner - Search system for Indicators of Compromise

if [ $# -eq 0 ]; then
    echo "Usage: $0 <ioc_file>"
    echo "IOC file should contain one indicator per line:"
    echo "  - IP addresses"
    echo "  - Domain names"
    echo "  - File hashes (MD5/SHA256)"
    echo "  - File paths"
    exit 1
fi

IOC_FILE="$1"

if [ ! -f "$IOC_FILE" ]; then
    echo "Error: IOC file not found: $IOC_FILE"
    exit 1
fi

echo "==================================="
echo "IOC Scanner"
echo "==================================="
echo "Scan Time: $(date)"
echo "IOC File: $IOC_FILE"
echo "Hostname: $(hostname)"
echo "==================================="
echo

# Read IOCs from file
mapfile -t IOCS < "$IOC_FILE"

echo "[+] Loaded ${#IOCS[@]} IOCs"
echo

# Search logs for IOCs
echo "=== Searching Logs for IOCs ==="
for ioc in "${IOCS[@]}"; do
    # Skip empty lines and comments
    [[ -z "$ioc" || "$ioc" =~ ^# ]] && continue

    echo "Searching for: $ioc"

    # Search in log files
    grep -r "$ioc" /var/log/ 2>/dev/null | head -5

    # Search in current connections
    netstat -tunap 2>/dev/null | grep -i "$ioc" || ss -tunap 2>/dev/null | grep -i "$ioc"

    echo "---"
done
echo

# Search filesystem for file hashes
echo "=== Searching for File Hashes ==="
echo "⚠️  Warning: This may take a long time"
echo "Searching in /tmp, /var/tmp, /home (limited)..."

for ioc in "${IOCS[@]}"; do
    # Skip if not a hash (simple check: 32 or 64 hex chars)
    if [[ "$ioc" =~ ^[a-fA-F0-9]{32}$ ]] || [[ "$ioc" =~ ^[a-fA-F0-9]{64}$ ]]; then
        echo "Searching for hash: $ioc"
        find /tmp /var/tmp /home -type f -exec md5sum {} \; 2>/dev/null | grep -i "$ioc"
        find /tmp /var/tmp /home -type f -exec sha256sum {} \; 2>/dev/null | grep -i "$ioc"
    fi
done
echo

# Check running processes
echo "=== Checking Running Processes ==="
ps aux > /tmp/ps_output.txt
for ioc in "${IOCS[@]}"; do
    [[ -z "$ioc" || "$ioc" =~ ^# ]] && continue

    if grep -q "$ioc" /tmp/ps_output.txt 2>/dev/null; then
        echo "⚠️  IOC FOUND in running process: $ioc"
        grep "$ioc" /tmp/ps_output.txt
    fi
done
rm -f /tmp/ps_output.txt
echo

# Check network connections for IPs
echo "=== Checking Active Network Connections ==="
netstat -tunap 2>/dev/null > /tmp/netstat_output.txt || ss -tunap 2>/dev/null > /tmp/netstat_output.txt

for ioc in "${IOCS[@]}"; do
    # Check if it looks like an IP
    if [[ "$ioc" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        if grep -q "$ioc" /tmp/netstat_output.txt 2>/dev/null; then
            echo "⚠️  IOC FOUND in network connections: $ioc"
            grep "$ioc" /tmp/netstat_output.txt
        fi
    fi
done
rm -f /tmp/netstat_output.txt
echo

echo "==================================="
echo "IOC Scan Complete"
echo "==================================="
echo "⚠️  Review all findings above"
echo "⚠️  Investigate any matches immediately"
echo "==================================="
