#!/bin/bash
# Log Analyzer - Quick security log analysis

echo "==================================="
echo "Security Log Analyzer"
echo "==================================="
echo "Analysis Time: $(date)"
echo "==================================="
echo

echo "=== Failed Authentication Attempts ==="
if [ -f /var/log/auth.log ]; then
    echo "Last 20 failed login attempts:"
    grep -i "failed\|failure\|invalid user" /var/log/auth.log 2>/dev/null | tail -20
    echo
    echo "Top 10 IPs with failed attempts:"
    grep -i "failed" /var/log/auth.log 2>/dev/null | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" | sort | uniq -c | sort -rn | head -10
else
    echo "⚠️  /var/log/auth.log not accessible"
fi
echo

echo "=== Successful Logins (Last 10) ==="
if [ -f /var/log/auth.log ]; then
    grep -i "accepted\|session opened" /var/log/auth.log 2>/dev/null | tail -10
else
    echo "⚠️  /var/log/auth.log not accessible"
fi
echo

echo "=== Recent Sudo Commands ==="
if [ -f /var/log/auth.log ]; then
    grep -i "sudo:" /var/log/auth.log 2>/dev/null | tail -15
else
    echo "⚠️  /var/log/auth.log not accessible"
fi
echo

echo "=== System Errors (Last 15) ==="
if [ -f /var/log/syslog ]; then
    grep -i "error\|critical\|alert" /var/log/syslog 2>/dev/null | tail -15
else
    echo "⚠️  /var/log/syslog not accessible"
fi
echo

echo "=== Kernel Errors ==="
dmesg | grep -i "error\|fail\|critical" 2>/dev/null | tail -10
echo

echo "=== Login History (Last 20) ==="
last -20 2>/dev/null || echo "⚠️  last command not available"
echo

echo "=== Currently Logged In Users ==="
w 2>/dev/null || who 2>/dev/null
echo

echo "==================================="
echo "Analysis Complete"
echo "==================================="
