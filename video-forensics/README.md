# Video Forensics & Analysis

**Law Enforcement Grade Video Forensics Toolkit**

Complete video analysis solution for investigating surveillance footage, CCTV recordings, and digital video evidence.

## 🎯 Key Capabilities

- ✅ **Face Detection & Recognition** - Identify suspects in footage
- ✅ **License Plate Recognition (ANPR)** - Extract vehicle plates from traffic cameras
- ✅ **Object Tracking** - Track persons, vehicles, weapons across frames
- ✅ **Video Metadata Forensics** - Detect tampering and manipulation
- ✅ **Frame Extraction** - Extract frames at specific timestamps
- ✅ **Timeline Reconstruction** - Synchronize multiple camera feeds
- ✅ **Evidence Packaging** - Chain of custody compliance

## 📋 Use Cases

### Law Enforcement
- Analyze CCTV footage from crime scenes
- Identify suspects using face recognition
- Track suspect movements across multiple cameras
- Extract license plates from traffic cameras
- Verify video evidence authenticity

### Incident Investigation
- Body camera footage analysis
- Dashcam video processing
- Surveillance video timeline reconstruction
- Evidence preparation for court proceedings

## 🚀 Quick Start

### Installation

```bash
# Install system dependencies
sudo apt-get update
sudo apt-get install -y ffmpeg python3-opencv python3-pip tesseract-ocr

# Install Python packages
pip3 install opencv-python face-recognition pytesseract
```

### Basic Usage

```bash
# 1. Extract frames from CCTV footage
./scripts/extract_frames.sh --file cctv.mp4 --output frames/ --interval 1s

# 2. Detect faces in frames
python3 scripts/detect_faces.py --dir frames/ --output faces/

# 3. Run license plate recognition
python3 scripts/anpr.py --dir frames/ --output plates.csv --country NL

# 4. Analyze video metadata
./scripts/video_metadata.sh --file cctv.mp4 --check-tampering
```

## 📁 Scripts

### Video Processing
- `extract_frames.sh` - Extract frames from video
- `video_metadata.sh` - Extract and analyze metadata
- `convert_video.sh` - Convert video formats

### Forensic Analysis
- `detect_faces.py` - Face detection in frames
- `recognize_faces.py` - Face recognition against database
- `anpr.py` - Automatic Number Plate Recognition
- `track_objects.py` - Object detection and tracking

## 📚 Documentation

See [SKILL.md](SKILL.md) for complete documentation including:
- Detailed workflows
- Face recognition database setup
- Multi-camera timeline reconstruction
- Legal and chain of custody requirements
- Troubleshooting guide

## 🔒 Legal Compliance

This toolkit is designed for **law enforcement use only** and must be used in compliance with:
- ISO/IEC 27037:2012 (Digital Evidence Guidelines)
- Local privacy and surveillance regulations
- Proper legal authority (warrants, court orders)
- Chain of custody requirements

## ⚖️ Privacy Notice

**IMPORTANT:** Use only for legitimate law enforcement purposes with proper legal authority.

❌ **Prohibited Uses:**
- Mass surveillance without legal authority
- Discriminatory profiling
- Processing private video without authorization
- Commercial purposes

## 📝 Examples

### Example 1: Analyze Suspect in CCTV

```bash
# Extract frames
./scripts/extract_frames.sh --file cctv_robbery.mp4 --output frames/

# Detect faces
python3 scripts/detect_faces.py --dir frames/ --output suspect_faces/

# Match against database
python3 scripts/recognize_faces.py \
    --unknown suspect_faces/ \
    --database known_suspects.pkl \
    --output matches.json
```

### Example 2: Traffic Camera ANPR

```bash
# Extract vehicle frames
./scripts/extract_frames.sh --file traffic_cam.mp4 --output vehicles/ --interval 2s

# Run ANPR
python3 scripts/anpr.py --dir vehicles/ --output plates.csv --country NL --annotate annotated/
```

## 🛠️ Requirements

**Minimum:**
- FFmpeg
- Python 3.7+
- OpenCV
- 4GB RAM

**Recommended:**
- NVIDIA GPU (for faster processing)
- 8GB+ RAM
- SSD storage

## 📊 Supported Formats

**Video:** MP4, AVI, MOV, MKV, FLV, WMV
**Images:** JPG, PNG, BMP, TIFF
**License Plates:** NL, UK, US, DE, FR, BE (more can be added)

## 🤝 Contributing

This is a law enforcement toolkit. Contributions should focus on:
- Improved accuracy
- Additional plate recognition patterns
- Performance optimization
- Documentation improvements

## 📄 License

See parent repository license. Use restricted to authorized law enforcement purposes.

---

**For detailed usage instructions, see [SKILL.md](SKILL.md)**
