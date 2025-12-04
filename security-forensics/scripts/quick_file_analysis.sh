#!/bin/bash
# Quick File Analysis Script
# Performs rapid triage of suspicious files

if [ $# -eq 0 ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

echo "=================================="
echo "Quick File Analysis Report"
echo "=================================="
echo "File: $FILE"
echo "Analysis Time: $(date)"
echo "=================================="
echo

echo "=== Basic Information ==="
file -b "$FILE"
ls -lh "$FILE"
echo

echo "=== File Hashes ==="
echo "MD5:    $(md5sum "$FILE" | cut -d' ' -f1)"
echo "SHA1:   $(sha1sum "$FILE" | cut -d' ' -f1)"
echo "SHA256: $(sha256sum "$FILE" | cut -d' ' -f1)"
echo

echo "=== Timestamps ==="
stat "$FILE" | grep -E "Access|Modify|Change"
echo

echo "=== Magic Bytes (First 32 bytes) ==="
xxd "$FILE" | head -2
echo

echo "=== Entropy Analysis ==="
python3 << 'PYTHON_EOF'
import math
import sys
from collections import Counter

try:
    with open(sys.argv[1], 'rb') as f:
        data = f.read()
        if data:
            counter = Counter(data)
            entropy = -sum(count/len(data) * math.log2(count/len(data)) for count in counter.values())
            print(f"Entropy: {entropy:.4f} bits/byte")
            if entropy > 7.5:
                print("⚠️  HIGH ENTROPY - Likely encrypted/compressed/packed")
            elif entropy > 6.5:
                print("ℹ️  MEDIUM ENTROPY - Possibly compressed")
            else:
                print("✓  NORMAL ENTROPY")
except Exception as e:
    print(f"Error calculating entropy: {e}")
PYTHON_EOF
echo

echo "=== Interesting Strings (URLs, IPs, Paths) ==="
strings "$FILE" 2>/dev/null | grep -E "(https?://|ftp://|[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|C:\\|/etc/|/var/|/usr/)" | head -20
echo

echo "=== Suspicious Keywords ==="
strings "$FILE" 2>/dev/null | grep -iE "(password|admin|cmd|powershell|exploit|payload|shell|exec|system|root)" | head -15
echo

echo "=================================="
echo "Analysis Complete"
echo "=================================="
