#!/bin/bash
# Extract frames from video for forensic analysis

show_usage() {
    cat << EOF
Extract Frames from Video

Usage:
    $0 --file <video> --output <dir> [options]

Options:
    -f, --file <video>       Input video file
    -o, --output <dir>       Output directory for frames
    -i, --interval <time>    Extract every N seconds/frames (default: 1s)
    -s, --start <time>       Start time (format: HH:MM:SS or seconds)
    -e, --end <time>         End time (format: HH:MM:SS or seconds)
    -q, --quality <1-31>     JPEG quality (1=best, 31=worst, default=2)
    --timestamps             Add timestamps to filenames
    --key-frames-only        Extract only key frames
    --help                   Show this help

Examples:
    # Extract every second
    $0 --file cctv.mp4 --output frames/ --interval 1s

    # Extract every 10th frame
    $0 --file cctv.mp4 --output frames/ --interval 10

    # Extract specific time range
    $0 --file cctv.mp4 --output frames/ --start 00:05:30 --end 00:06:45

    # Extract only key frames (faster, less storage)
    $0 --file cctv.mp4 --output frames/ --key-frames-only
EOF
}

FILE=""
OUTPUT=""
INTERVAL="1"
START=""
END=""
QUALITY="2"
TIMESTAMPS=false
KEY_FRAMES_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file) FILE="$2"; shift 2 ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -i|--interval) INTERVAL="$2"; shift 2 ;;
        -s|--start) START="$2"; shift 2 ;;
        -e|--end) END="$2"; shift 2 ;;
        -q|--quality) QUALITY="$2"; shift 2 ;;
        --timestamps) TIMESTAMPS=true; shift ;;
        --key-frames-only) KEY_FRAMES_ONLY=true; shift ;;
        --help) show_usage; exit 0 ;;
        *) echo "Unknown option: $1"; show_usage; exit 1 ;;
    esac
done

if [ -z "$FILE" ] || [ -z "$OUTPUT" ]; then
    echo "Error: --file and --output are required"
    show_usage
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

mkdir -p "$OUTPUT"

echo "═══════════════════════════════════════════════════════"
echo "Frame Extraction - Forensic Video Analysis"
echo "═══════════════════════════════════════════════════════"
echo "Input: $FILE"
echo "Output: $OUTPUT"
echo "Interval: $INTERVAL"
[ -n "$START" ] && echo "Start: $START"
[ -n "$END" ] && echo "End: $END"
echo "═══════════════════════════════════════════════════════"
echo

# Build ffmpeg command
FFMPEG_CMD="ffmpeg -i \"$FILE\""

[ -n "$START" ] && FFMPEG_CMD="$FFMPEG_CMD -ss $START"
[ -n "$END" ] && FFMPEG_CMD="$FFMPEG_CMD -to $END"

if [ "$KEY_FRAMES_ONLY" = true ]; then
    # Extract only key frames (I-frames)
    FFMPEG_CMD="$FFMPEG_CMD -vf \"select='eq(pict_type,I)'\" -vsync vfr"
else
    # Extract at specified interval
    if [[ "$INTERVAL" =~ ^[0-9]+$ ]]; then
        # Frame interval
        FFMPEG_CMD="$FFMPEG_CMD -vf \"select='not(mod(n,$INTERVAL))'\" -vsync vfr"
    else
        # Time interval (e.g., 1s, 0.5s)
        FFMPEG_CMD="$FFMPEG_CMD -vf fps=1/${INTERVAL}"
    fi
fi

if [ "$TIMESTAMPS" = true ]; then
    FFMPEG_CMD="$FFMPEG_CMD \"$OUTPUT/frame_%Y-%m-%d_%H-%M-%S.jpg\""
else
    FFMPEG_CMD="$FFMPEG_CMD -q:v $QUALITY \"$OUTPUT/frame_%06d.jpg\""
fi

echo "[*] Extracting frames..."
eval $FFMPEG_CMD 2>&1 | grep -E "frame=|Duration:"

FRAME_COUNT=$(ls -1 "$OUTPUT"/*.jpg 2>/dev/null | wc -l)

echo
echo "✓ Extraction complete"
echo "Frames extracted: $FRAME_COUNT"
echo "Output directory: $OUTPUT"
echo
echo "Next steps:"
echo "  - Run face detection: python3 detect_faces.py --dir $OUTPUT"
echo "  - Run object tracking: python3 track_objects.py --dir $OUTPUT"
echo "  - Run ANPR: python3 anpr.py --dir $OUTPUT"
