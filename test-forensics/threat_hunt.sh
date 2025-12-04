#!/bin/bash
# Threat Hunting - Zoals de skill het zou doen

echo "═══════════════════════════════════════"
echo "   THREAT HUNTING OPERATION"
echo "═══════════════════════════════════════"
echo

echo "🔍 Hunting for threats on: $(hostname)"
echo "Time: $(date)"
echo

# 1. Suspicious Processes
echo "━━━ [1/7] SUSPICIOUS PROCESSES ━━━"
echo "Checking for unusual process locations..."
ps aux | grep -v -E '(/usr/|/bin/|/sbin/)' | head -10
echo

# 2. Network Connections
echo "━━━ [2/7] ACTIVE NETWORK CONNECTIONS ━━━"
echo "Checking for suspicious connections..."
netstat -tunap 2>/dev/null | grep ESTABLISHED | head -10 || ss -tunap 2>/dev/null | grep ESTABLISHED | head -10
echo

# 3. Recently Modified Files
echo "━━━ [3/7] RECENTLY MODIFIED FILES (Last 24h) ━━━"
echo "Checking /tmp for recent changes..."
find /tmp -type f -mtime -1 -ls 2>/dev/null | head -10
echo

# 4. Hidden Files in Suspicious Locations
echo "━━━ [4/7] HIDDEN FILES ━━━"
echo "Checking for hidden files in /tmp..."
find /tmp -name ".*" -type f 2>/dev/null | head -10
echo

# 5. SUID/SGID Files (Privilege Escalation)
echo "━━━ [5/7] SUID/SGID FILES ━━━"
echo "Checking for potential privilege escalation vectors..."
find /tmp /var/tmp /home -type f \( -perm -4000 -o -perm -2000 \) -ls 2>/dev/null | head -5
echo

# 6. Cron Jobs and Scheduled Tasks
echo "━━━ [6/7] SCHEDULED TASKS ━━━"
echo "Checking cron jobs..."
ls -la /etc/cron.d/ 2>/dev/null | head -5
echo

# 7. Listening Ports
echo "━━━ [7/7] LISTENING PORTS ━━━"
echo "Checking for suspicious listening services..."
netstat -tuln 2>/dev/null | grep LISTEN | head -10 || ss -tuln 2>/dev/null | grep LISTEN | head -10
echo

echo "═══════════════════════════════════════"
echo "✅ THREAT HUNT COMPLETE"
echo "═══════════════════════════════════════"
