#!/bin/bash
# Hash Calculator - Calculate multiple hash types for files

if [ $# -eq 0 ]; then
    echo "Usage: $0 <file1> [file2] [file3] ..."
    echo "Calculates MD5, SHA1, SHA256, and SHA512 hashes"
    exit 1
fi

echo "==================================="
echo "Hash Calculator"
echo "==================================="
echo

for FILE in "$@"; do
    if [ ! -f "$FILE" ]; then
        echo "⚠️  Skipping (not found): $FILE"
        continue
    fi

    echo "File: $FILE"
    echo "Size: $(ls -lh "$FILE" | awk '{print $5}')"
    echo "-----------------------------------"
    echo "MD5:    $(md5sum "$FILE" | cut -d' ' -f1)"
    echo "SHA1:   $(sha1sum "$FILE" | cut -d' ' -f1)"
    echo "SHA256: $(sha256sum "$FILE" | cut -d' ' -f1)"
    echo "SHA512: $(sha512sum "$FILE" | cut -d' ' -f1)"
    echo "==================================="
    echo
done

echo "Hash calculation complete"
echo "Timestamp: $(date)"
