#!/bin/bash
# Evidence Collector - Collect forensic evidence with proper documentation

EVIDENCE_DIR="evidence_$(date +%Y%m%d_%H%M%S)"
HOSTNAME=$(hostname)
COLLECTOR=$(whoami)

echo "==================================="
echo "Forensic Evidence Collector"
echo "==================================="
echo "Timestamp: $(date)"
echo "Hostname: $HOSTNAME"
echo "Collector: $COLLECTOR"
echo "Evidence Directory: $EVIDENCE_DIR"
echo "==================================="
echo

# Create evidence directory
mkdir -p "$EVIDENCE_DIR"/{system_info,logs,process_info,network_info,files}

echo "[+] Creating evidence directory structure..."

# System Information
echo "[+] Collecting system information..."
{
    echo "=== System Information ==="
    echo "Collection Time: $(date)"
    echo "Hostname: $HOSTNAME"
    echo "Collector: $COLLECTOR"
    echo
    echo "=== OS Information ==="
    uname -a
    cat /etc/os-release 2>/dev/null
    echo
    echo "=== Uptime ==="
    uptime
    echo
    echo "=== Disk Usage ==="
    df -h
    echo
    echo "=== Memory Usage ==="
    free -h
} > "$EVIDENCE_DIR/system_info/system_info.txt"

# Process Information
echo "[+] Collecting process information..."
{
    echo "=== Running Processes ==="
    ps auxf
    echo
    echo "=== Top Processes by CPU ==="
    ps aux --sort=-%cpu | head -20
    echo
    echo "=== Top Processes by Memory ==="
    ps aux --sort=-%mem | head -20
} > "$EVIDENCE_DIR/process_info/processes.txt"

# Network Information
echo "[+] Collecting network information..."
{
    echo "=== Network Connections ==="
    netstat -tunap 2>/dev/null || ss -tunap 2>/dev/null
    echo
    echo "=== Listening Ports ==="
    netstat -tuln 2>/dev/null || ss -tuln 2>/dev/null
    echo
    echo "=== Routing Table ==="
    route -n 2>/dev/null || ip route 2>/dev/null
    echo
    echo "=== Network Interfaces ==="
    ip addr 2>/dev/null || ifconfig 2>/dev/null
} > "$EVIDENCE_DIR/network_info/network.txt"

# Open Files
echo "[+] Collecting open files information..."
lsof 2>/dev/null > "$EVIDENCE_DIR/process_info/open_files.txt" || echo "lsof not available" > "$EVIDENCE_DIR/process_info/open_files.txt"

# Log Files
echo "[+] Collecting log files..."
for log in /var/log/auth.log /var/log/syslog /var/log/messages; do
    if [ -f "$log" ]; then
        cp -p "$log" "$EVIDENCE_DIR/logs/" 2>/dev/null && echo "  - Collected: $log" || echo "  ⚠️  Failed: $log"
    fi
done

# User Information
echo "[+] Collecting user information..."
{
    echo "=== Current Users ==="
    w
    echo
    echo "=== Login History ==="
    last -20
    echo
    echo "=== All Users ==="
    cat /etc/passwd
} > "$EVIDENCE_DIR/system_info/users.txt"

# Scheduled Tasks
echo "[+] Collecting scheduled tasks..."
{
    echo "=== Crontab ==="
    cat /etc/crontab 2>/dev/null
    echo
    echo "=== Cron Jobs ==="
    ls -la /etc/cron.* 2>/dev/null
    echo
    echo "=== User Crontabs ==="
    for user in $(cut -f1 -d: /etc/passwd); do
        echo "--- $user ---"
        crontab -u $user -l 2>/dev/null
    done
} > "$EVIDENCE_DIR/system_info/scheduled_tasks.txt"

# Chain of Custody
echo "[+] Creating chain of custody documentation..."
{
    echo "=== Chain of Custody ==="
    echo "Evidence ID: $EVIDENCE_DIR"
    echo "Collection Date: $(date)"
    echo "Collection Time: $(date +%H:%M:%S)"
    echo "Hostname: $HOSTNAME"
    echo "Collector: $COLLECTOR"
    echo "Timezone: $(date +%Z)"
    echo
    echo "=== Files Collected ==="
    find "$EVIDENCE_DIR" -type f -ls
    echo
    echo "=== Integrity Hashes ==="
    find "$EVIDENCE_DIR" -type f -exec sha256sum {} \;
} > "$EVIDENCE_DIR/chain_of_custody.txt"

# Create archive
echo "[+] Creating evidence archive..."
tar -czf "${EVIDENCE_DIR}.tar.gz" "$EVIDENCE_DIR"

# Calculate archive hash
echo "[+] Calculating archive integrity hash..."
sha256sum "${EVIDENCE_DIR}.tar.gz" > "${EVIDENCE_DIR}.tar.gz.sha256"

echo
echo "==================================="
echo "Evidence Collection Complete"
echo "==================================="
echo "Archive: ${EVIDENCE_DIR}.tar.gz"
echo "SHA256: $(cat ${EVIDENCE_DIR}.tar.gz.sha256)"
echo
echo "⚠️  IMPORTANT: Store this archive securely"
echo "⚠️  Maintain chain of custody documentation"
echo "==================================="
