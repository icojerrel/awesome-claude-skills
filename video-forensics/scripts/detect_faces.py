#!/usr/bin/env python3
"""
Face Detection in Video Frames
Detects faces in images/video frames for forensic analysis
"""

import argparse
import cv2
import os
import json
from pathlib import Path
import sys

def detect_faces_in_image(image_path, output_dir=None, min_confidence=0.5):
    """
    Detect faces in a single image using OpenCV's DNN face detector

    Args:
        image_path: Path to image file
        output_dir: Directory to save face crops (optional)
        min_confidence: Minimum confidence threshold (0-1)

    Returns:
        List of face detections with bounding boxes
    """
    # Load the pre-trained face detection model
    # Using OpenCV's DNN face detector (more accurate than Haar Cascades)
    prototxt_path = "deploy.prototxt"
    model_path = "res10_300x300_ssd_iter_140000.caffemodel"

    # If models don't exist, try to use Haar Cascades as fallback
    use_haar = False
    if not os.path.exists(prototxt_path) or not os.path.exists(model_path):
        print("⚠ DNN models not found, using Haar Cascade (less accurate)")
        use_haar = True

    # Load image
    image = cv2.imread(str(image_path))
    if image is None:
        print(f"Error: Could not load image {image_path}")
        return []

    (h, w) = image.shape[:2]
    faces = []

    if use_haar:
        # Fallback to Haar Cascade
        face_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        )
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        detections = face_cascade.detectMultiScale(gray, 1.1, 4)

        for i, (x, y, w_box, h_box) in enumerate(detections):
            faces.append({
                'box': (x, y, x + w_box, y + h_box),
                'confidence': 1.0,  # Haar doesn't provide confidence
                'face_id': i
            })

            # Save face crop if requested
            if output_dir:
                face_crop = image[y:y+h_box, x:x+w_box]
                face_filename = f"{Path(image_path).stem}_face_{i}.jpg"
                cv2.imwrite(str(Path(output_dir) / face_filename), face_crop)

    else:
        # Use DNN face detector
        net = cv2.dnn.readNetFromCaffe(prototxt_path, model_path)

        # Prepare image blob
        blob = cv2.dnn.blobFromImage(
            cv2.resize(image, (300, 300)),
            1.0,
            (300, 300),
            (104.0, 177.0, 123.0)
        )

        net.setInput(blob)
        detections = net.forward()

        # Process detections
        for i in range(detections.shape[2]):
            confidence = detections[0, 0, i, 2]

            if confidence > min_confidence:
                box = detections[0, 0, i, 3:7] * [w, h, w, h]
                (startX, startY, endX, endY) = box.astype("int")

                # Ensure box is within image bounds
                startX, startY = max(0, startX), max(0, startY)
                endX, endY = min(w, endX), min(h, endY)

                faces.append({
                    'box': (startX, startY, endX, endY),
                    'confidence': float(confidence),
                    'face_id': i
                })

                # Save face crop if requested
                if output_dir:
                    face_crop = image[startY:endY, startX:endX]
                    face_filename = f"{Path(image_path).stem}_face_{i}_conf{confidence:.2f}.jpg"
                    cv2.imwrite(str(Path(output_dir) / face_filename), face_crop)

    return faces


def process_directory(input_dir, output_dir, min_confidence=0.5, annotate=False):
    """
    Process all images in a directory

    Args:
        input_dir: Directory containing images
        output_dir: Directory to save face crops
        min_confidence: Minimum confidence threshold
        annotate: Save annotated images with face boxes
    """
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    if annotate:
        annotated_dir = output_path / "annotated"
        annotated_dir.mkdir(exist_ok=True)

    # Supported image formats
    image_extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff'}
    image_files = [f for f in input_path.iterdir()
                   if f.suffix.lower() in image_extensions]

    print(f"Found {len(image_files)} images to process")

    results = []
    total_faces = 0

    for img_file in image_files:
        print(f"Processing: {img_file.name}...", end=" ")

        faces = detect_faces_in_image(img_file, output_path, min_confidence)

        if faces:
            print(f"✓ {len(faces)} face(s) detected")
            total_faces += len(faces)

            results.append({
                'image': str(img_file.name),
                'faces_detected': len(faces),
                'faces': faces
            })

            # Create annotated image if requested
            if annotate:
                image = cv2.imread(str(img_file))
                for face in faces:
                    (startX, startY, endX, endY) = face['box']
                    cv2.rectangle(image, (startX, startY), (endX, endY), (0, 255, 0), 2)
                    conf_text = f"{face['confidence']:.2f}"
                    cv2.putText(image, conf_text, (startX, startY - 10),
                               cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

                annotated_file = annotated_dir / f"annotated_{img_file.name}"
                cv2.imwrite(str(annotated_file), image)
        else:
            print("No faces detected")

    # Save results to JSON
    results_file = output_path / "detection_results.json"
    with open(results_file, 'w') as f:
        json.dump(results, f, indent=2)

    print("\n" + "="*60)
    print(f"Face Detection Complete")
    print("="*60)
    print(f"Images processed: {len(image_files)}")
    print(f"Total faces detected: {total_faces}")
    print(f"Face crops saved to: {output_path}")
    print(f"Results saved to: {results_file}")
    if annotate:
        print(f"Annotated images saved to: {annotated_dir}")
    print("="*60)

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Face Detection for Forensic Video Analysis",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Detect faces in all frames
  %(prog)s --dir frames/ --output faces/

  # With annotations
  %(prog)s --dir frames/ --output faces/ --annotate

  # Adjust confidence threshold
  %(prog)s --dir frames/ --output faces/ --confidence 0.7

  # Single image
  %(prog)s --file image.jpg --output faces/
        """
    )

    parser.add_argument('--dir', help='Input directory with images')
    parser.add_argument('--file', help='Single image file')
    parser.add_argument('--output', required=True, help='Output directory for face crops')
    parser.add_argument('--confidence', type=float, default=0.5,
                       help='Minimum confidence threshold (0-1, default: 0.5)')
    parser.add_argument('--annotate', action='store_true',
                       help='Save annotated images with face boxes')

    args = parser.parse_args()

    if not args.dir and not args.file:
        parser.error("Either --dir or --file must be specified")

    if args.dir:
        process_directory(args.dir, args.output, args.confidence, args.annotate)
    elif args.file:
        output_path = Path(args.output)
        output_path.mkdir(parents=True, exist_ok=True)

        faces = detect_faces_in_image(args.file, output_path, args.confidence)
        print(f"\nDetected {len(faces)} face(s) in {args.file}")
        print(f"Face crops saved to: {output_path}")


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nError: {e}")
        sys.exit(1)
