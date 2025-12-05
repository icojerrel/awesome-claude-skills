#!/bin/bash
# Extract and analyze video metadata for forensic purposes

show_usage() {
    cat << EOF
Video Metadata Extraction & Analysis

Extracts comprehensive metadata from video files and checks for tampering indicators.

Usage:
    $0 --file <video> [options]

Options:
    -f, --file <video>         Input video file
    --extract-all              Extract all available metadata
    --check-tampering          Check for tampering indicators
    --output <file>            Save metadata to JSON file
    --help                     Show this help

Examples:
    # Basic metadata
    $0 --file evidence.mp4

    # Full metadata extraction
    $0 --file evidence.mp4 --extract-all --output metadata.json

    # Check for tampering
    $0 --file evidence.mp4 --check-tampering
EOF
}

FILE=""
EXTRACT_ALL=false
CHECK_TAMPERING=false
OUTPUT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file) FILE="$2"; shift 2 ;;
        --extract-all) EXTRACT_ALL=true; shift ;;
        --check-tampering) CHECK_TAMPERING=true; shift ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --help) show_usage; exit 0 ;;
        *) echo "Unknown option: $1"; show_usage; exit 1 ;;
    esac
done

if [ -z "$FILE" ]; then
    echo "Error: --file is required"
    show_usage
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "Video Metadata Analysis"
echo "═══════════════════════════════════════════════════════"
echo "File: $FILE"
echo "═══════════════════════════════════════════════════════"
echo

# Basic file info
echo "[File Information]"
echo "Size: $(du -h "$FILE" | cut -f1)"
echo "Type: $(file -b "$FILE")"
echo "Modified: $(stat -c%y "$FILE" 2>/dev/null || stat -f "%Sm" "$FILE")"
echo

# FFprobe metadata
echo "[Video Stream]"
ffprobe -v quiet -select_streams v:0 -show_entries \
    stream=codec_name,width,height,r_frame_rate,bit_rate,duration \
    -of default=noprint_wrappers=1:nokey=0 "$FILE"
echo

echo "[Audio Stream]"
ffprobe -v quiet -select_streams a:0 -show_entries \
    stream=codec_name,sample_rate,channels,bit_rate \
    -of default=noprint_wrappers=1:nokey=0 "$FILE"
echo

echo "[Format]"
ffprobe -v quiet -show_entries \
    format=format_name,duration,size,bit_rate,nb_streams \
    -of default=noprint_wrappers=1:nokey=0 "$FILE"
echo

if [ "$EXTRACT_ALL" = true ]; then
    echo "[Complete Metadata]"
    ffprobe -v quiet -show_format -show_streams "$FILE" 2>&1
    echo

    echo "[Embedded Metadata Tags]"
    ffprobe -v quiet -show_entries format_tags "$FILE" 2>&1
    echo
fi

if [ "$CHECK_TAMPERING" = true ]; then
    echo "═══════════════════════════════════════════════════════"
    echo "Tampering Detection Analysis"
    echo "═══════════════════════════════════════════════════════"

    # Check for codec changes mid-stream
    echo "[Checking for codec consistency...]"
    CODECS=$(ffprobe -v error -select_streams v:0 -show_entries packet=codec_type -of csv=p=0 "$FILE" | sort -u | wc -l)
    if [ "$CODECS" -gt 1 ]; then
        echo "⚠ WARNING: Multiple video codecs detected (possible editing)"
    else
        echo "✓ Single codec throughout video"
    fi

    # Check for timestamp anomalies
    echo
    echo "[Checking timestamp consistency...]"
    ffprobe -v error -show_entries packet=pts_time -of csv=p=0 "$FILE" | \
    awk '{if(NR>1 && $1<prev) print "⚠ WARNING: Timestamp regression at packet",NR; prev=$1}' | head -5

    # Check for resolution changes
    echo
    echo "[Checking resolution consistency...]"
    ffprobe -v error -select_streams v:0 -show_entries frame=width,height -of csv=p=0 "$FILE" | \
    sort -u | wc -l | \
    awk '{if($1>1) print "⚠ WARNING: Resolution changes detected"; else print "✓ Consistent resolution"}'

    # Check for audio/video sync
    echo
    echo "[Checking A/V synchronization...]"
    V_DUR=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of csv=p=0 "$FILE")
    A_DUR=$(ffprobe -v error -select_streams a:0 -show_entries stream=duration -of csv=p=0 "$FILE")

    if [ -n "$V_DUR" ] && [ -n "$A_DUR" ]; then
        DIFF=$(echo "$V_DUR - $A_DUR" | bc 2>/dev/null || echo "0")
        DIFF_ABS=${DIFF#-}
        if (( $(echo "$DIFF_ABS > 0.5" | bc -l 2>/dev/null || echo 0) )); then
            echo "⚠ WARNING: A/V desynchronization detected (${DIFF}s difference)"
        else
            echo "✓ Audio and video in sync"
        fi
    fi

    echo
    echo "═══════════════════════════════════════════════════════"
fi

# Export to JSON if requested
if [ -n "$OUTPUT" ]; then
    echo "[Exporting metadata to JSON...]"
    ffprobe -v quiet -print_format json -show_format -show_streams "$FILE" > "$OUTPUT"
    echo "✓ Metadata exported to: $OUTPUT"
fi

echo
echo "Analysis complete."
