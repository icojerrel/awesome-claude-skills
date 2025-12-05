---
name: video-forensics
description: Comprehensive video forensics and analysis for law enforcement, including CCTV footage analysis, face detection/recognition, object tracking, license plate recognition (ANPR), frame extraction, video metadata analysis, and evidence timeline reconstruction. Supports surveillance video investigations, suspect identification, and court-admissible video evidence processing.
---

# Video Forensics & Analysis

Law enforcement grade video forensics toolkit for analyzing surveillance footage, CCTV recordings, and digital video evidence.

## When to Use This Skill

Use this skill when you need to:
- Analyze CCTV/surveillance footage from crime scenes
- Detect and recognize faces in video evidence
- Track objects (persons, vehicles, weapons) across frames
- Extract license plates from traffic camera footage (ANPR)
- Extract frames from video for detailed analysis
- Analyze video metadata for tampering detection
- Reconstruct timelines from multiple video sources
- Prepare video evidence for court proceedings
- Identify suspects or persons of interest in footage
- Analyze body camera or dashcam footage

## Capabilities

### 1. Video Processing
- Frame extraction at specified intervals or timestamps
- Video format conversion and codec analysis
- Resolution enhancement and denoising
- Video stabilization for shaky footage
- Speed adjustment (slow motion, time-lapse)
- Multi-video synchronization and merging

### 2. Face Detection & Recognition
- Detect faces in video frames
- Extract face crops for comparison
- Match faces against known suspect database
- Track individuals across frames
- Age/gender estimation (when needed)
- Generate face galleries from footage

### 3. Object Detection & Tracking
- Detect persons, vehicles, weapons, objects
- Track objects across frames (motion tracking)
- Count people entering/leaving areas
- Detect suspicious behavior patterns
- Loitering detection
- Perimeter breach detection

### 4. License Plate Recognition (ANPR)
- Automatic Number Plate Recognition
- Extract plate numbers from traffic cameras
- Track vehicle movements across multiple cameras
- Match against stolen vehicle databases
- Speed estimation from timestamps

### 5. Video Metadata Forensics
- Extract complete metadata (codec, resolution, timestamps)
- Detect video editing or tampering
- Analyze creation/modification timestamps
- Extract GPS coordinates (if embedded)
- Camera model and settings analysis
- Identify deepfakes or manipulated footage

### 6. Timeline Reconstruction
- Synchronize multiple video sources
- Create unified timeline from CCTV network
- Cross-reference with other evidence (logs, witness statements)
- Generate court-ready video timelines

## Helper Scripts

All scripts are located in `scripts/` directory:

### Core Video Processing
- `extract_frames.sh` - Extract frames from video at intervals
- `video_metadata.sh` - Extract and analyze video metadata
- `convert_video.sh` - Convert between video formats
- `enhance_video.sh` - Improve video quality (denoise, stabilize)

### Forensic Analysis
- `detect_faces.py` - Face detection in video frames
- `recognize_faces.py` - Face recognition against database
- `track_objects.py` - Object detection and tracking
- `anpr.py` - Automatic Number Plate Recognition
- `detect_tampering.sh` - Detect video manipulation
- `timeline_sync.py` - Synchronize multiple video sources

### Evidence Management
- `evidence_package.sh` - Package video evidence with chain of custody
- `generate_report.py` - Generate forensic analysis report
- `create_highlights.sh` - Create highlight reel of key moments

## Installation Requirements

### Required Tools
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y ffmpeg python3-opencv python3-pip

# Python dependencies
pip3 install opencv-python opencv-contrib-python pillow numpy
pip3 install face-recognition dlib  # For face recognition
pip3 install pytesseract  # For license plate OCR
pip3 install moviepy  # For video editing
```

### Optional (Enhanced Features)
```bash
# YOLO for advanced object detection
pip3 install ultralytics

# TensorFlow for deep learning models
pip3 install tensorflow

# GPU acceleration (if NVIDIA GPU available)
pip3 install opencv-python-headless
```

## Workflows

### Workflow 1: Analyze CCTV Footage for Suspect

**Scenario:** You have CCTV footage from a crime scene and need to identify suspects.

```bash
# Step 1: Extract metadata and basic info
./scripts/video_metadata.sh --file evidence/cctv_footage.mp4

# Step 2: Extract frames at key timestamps
./scripts/extract_frames.sh --file evidence/cctv_footage.mp4 \
  --interval 1s --output frames/

# Step 3: Detect faces in all frames
python3 scripts/detect_faces.py --dir frames/ --output faces/

# Step 4: Compare against suspect database
python3 scripts/recognize_faces.py --input faces/ \
  --database suspects_db/ --threshold 0.6

# Step 5: Track suspect movement across frames
python3 scripts/track_objects.py --file evidence/cctv_footage.mp4 \
  --detect person --output tracking_results.json

# Step 6: Generate evidence report
python3 scripts/generate_report.py --case 2024-INV-5678 \
  --video evidence/cctv_footage.mp4 \
  --findings faces/ tracking_results.json
```

**Output:**
- Face crops of all detected persons
- Suspect matches with confidence scores
- Movement timeline showing suspect's path
- Court-ready evidence report with timestamps

---

### Workflow 2: License Plate Recognition (ANPR)

**Scenario:** Traffic camera footage - identify vehicles at crime scene.

```bash
# Extract frames with vehicles
python3 scripts/track_objects.py --file traffic_cam.mp4 \
  --detect car --output vehicle_frames/

# Run ANPR on vehicle frames
python3 scripts/anpr.py --dir vehicle_frames/ \
  --output plates.csv \
  --country NL  # Dutch plates

# Cross-reference with stolen vehicle database
./scripts/check_stolen.sh --plates plates.csv \
  --database stolen_vehicles.db
```

**Output:**
```csv
Timestamp,Plate_Number,Confidence,Vehicle_Type,Color
2024-12-04 14:23:15,AB-123-CD,0.95,Sedan,Black
2024-12-04 14:24:02,XY-789-ZW,0.88,SUV,White
```

---

### Workflow 3: Multi-Camera Timeline Reconstruction

**Scenario:** Suspect moved through building with multiple CCTV cameras.

```bash
# Synchronize all camera feeds
python3 scripts/timeline_sync.py \
  --videos camera1.mp4 camera2.mp4 camera3.mp4 \
  --output synchronized_timeline.mp4

# Track suspect across all cameras
python3 scripts/track_objects.py \
  --file synchronized_timeline.mp4 \
  --detect person --id suspect_1 \
  --output movement_timeline.json

# Generate visual timeline
python3 scripts/generate_report.py \
  --timeline movement_timeline.json \
  --output timeline_report.pdf
```

**Output:** Unified timeline showing suspect's movement across all cameras with timestamps.

---

### Workflow 4: Video Metadata Forensics

**Scenario:** Verify authenticity of submitted video evidence.

```bash
# Extract all metadata
./scripts/video_metadata.sh --file submitted_video.mp4 \
  --extract-all --output metadata.json

# Check for tampering indicators
./scripts/detect_tampering.sh --file submitted_video.mp4

# Analyze frame-by-frame consistency
python3 scripts/detect_tampering.py --file submitted_video.mp4 \
  --check-consistency --output tampering_report.txt
```

**Checks for:**
- ❌ Inconsistent timestamps
- ❌ Codec changes mid-video
- ❌ Frame rate anomalies
- ❌ Resolution changes
- ❌ Audio/video desynchronization
- ❌ Deepfake indicators

---

## Face Recognition Database Setup

### Creating Suspect Database

```bash
# Create database structure
mkdir -p suspects_db/
mkdir -p suspects_db/known_suspects/

# Add suspect photos (one per person)
cp suspect1_photo.jpg suspects_db/known_suspects/john_doe.jpg
cp suspect2_photo.jpg suspects_db/known_suspects/jane_smith.jpg

# Build face encodings database
python3 scripts/build_face_db.py --input suspects_db/known_suspects/ \
  --output suspects_db/encodings.pkl
```

### Matching Faces

```bash
# Match faces from CCTV against database
python3 scripts/recognize_faces.py \
  --unknown faces_from_cctv/ \
  --database suspects_db/encodings.pkl \
  --threshold 0.6 \
  --output matches.json
```

**Output:**
```json
{
  "matches": [
    {
      "unknown_face": "frame_1234.jpg",
      "matched_person": "john_doe",
      "confidence": 0.87,
      "timestamp": "2024-12-04 14:23:15"
    }
  ]
}
```

---

## Object Detection Categories

Supported object types:
- `person` - Human detection and tracking
- `car`, `truck`, `bus` - Vehicle detection
- `bicycle`, `motorcycle` - Two-wheelers
- `backpack`, `handbag`, `suitcase` - Carried items
- `knife`, `gun` (requires specialized model) - Weapon detection
- `cell phone`, `laptop` - Electronics
- `bottle`, `cup` - Objects of interest

---

## Legal & Chain of Custody

### Evidence Packaging

When packaging video evidence:

```bash
# Create evidence package with chain of custody
./scripts/evidence_package.sh --file cctv_footage.mp4 \
  --case-number 2024-INV-5678 \
  --investigator "Det. Johnson" \
  --output evidence_package/

# This creates:
# - Original video (read-only copy)
# - SHA256 hash for integrity
# - Metadata extraction
# - Chain of custody log
# - Analysis results
```

### Court-Ready Reports

```bash
# Generate comprehensive forensic report
python3 scripts/generate_report.py \
  --case 2024-INV-5678 \
  --video evidence/cctv_footage.mp4 \
  --analysis-results faces/ tracking_results.json \
  --output Case_5678_Video_Forensics_Report.pdf

# Report includes:
# - Video metadata and authenticity verification
# - Face detection/recognition results
# - Object tracking timeline
# - Key frames with annotations
# - Chain of custody documentation
# - Methodology and tools used
# - Expert certification section
```

---

## Privacy & Legal Considerations

**IMPORTANT:** This skill is designed for law enforcement use only.

### Legal Requirements:
✅ Obtain proper legal authority (warrant, court order) before processing
✅ Maintain chain of custody for all video evidence
✅ Document all analysis methods and tools used
✅ Protect personally identifiable information (PII)
✅ Comply with GDPR/privacy regulations
✅ Only use for legitimate law enforcement purposes

### Prohibited Uses:
❌ Mass surveillance without legal authority
❌ Discriminatory profiling
❌ Processing private video without authorization
❌ Sharing results outside authorized personnel
❌ Using for commercial purposes

---

## Performance Optimization

### GPU Acceleration

For faster processing with NVIDIA GPU:

```bash
# Install CUDA-enabled OpenCV
pip3 install opencv-contrib-python-headless

# Enable GPU in scripts
export OPENCV_CUDA_ENABLE=1
```

### Batch Processing

For large video sets:

```bash
# Process multiple videos in parallel
./scripts/batch_process.sh --dir evidence_videos/ \
  --workers 4 \
  --operations "extract_frames,detect_faces,anpr"
```

---

## Troubleshooting

### Common Issues

**Issue:** Face recognition accuracy low
**Solution:**
- Use higher quality source images for database
- Adjust threshold (lower = more matches, higher = fewer false positives)
- Ensure good lighting in source footage

**Issue:** ANPR not detecting plates
**Solution:**
- Verify plate is clearly visible in frame
- Adjust country code setting
- Use frame extraction to get clearest shot of plate

**Issue:** Video processing too slow
**Solution:**
- Enable GPU acceleration
- Reduce frame rate for processing
- Process only key segments instead of full video

---

## Examples

See `examples/` directory for:
- `example_cctv_analysis.sh` - Complete CCTV analysis workflow
- `example_anpr.sh` - License plate recognition demo
- `example_face_matching.sh` - Face recognition against database
- `example_multi_camera.sh` - Multi-camera timeline sync

---

## References

- **ISO/IEC 27037:2012** - Digital evidence guidelines
- **NIST Special Publication 800-101** - Digital forensics guidelines
- **Scientific Working Group on Digital Evidence (SWGDE)** - Video analysis standards
- **OpenCV Documentation** - https://docs.opencv.org/
- **Face Recognition Library** - https://github.com/ageitgey/face_recognition

---

## Support

For issues or questions:
1. Check `examples/` for usage demonstrations
2. Review `docs/troubleshooting.md`
3. Ensure all dependencies are installed
4. Verify video format is supported (MP4, AVI, MOV, MKV)

---

**Remember:** This is a powerful tool for law enforcement. Use responsibly and within legal authority.
