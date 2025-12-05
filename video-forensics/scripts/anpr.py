#!/usr/bin/env python3
"""
Automatic Number Plate Recognition (ANPR)
Extract license plate numbers from traffic camera footage
"""

import argparse
import cv2
import pytesseract
import re
import json
from pathlib import Path
import sys
import csv

# License plate patterns by country
PLATE_PATTERNS = {
    'NL': r'[A-Z]{2}-\d{2,3}-[A-Z]{2}',  # Dutch: AB-123-CD
    'UK': r'[A-Z]{2}\d{2}\s?[A-Z]{3}',   # UK: AB12 CDE
    'US': r'[A-Z]{3}-?\d{4}',            # US varies by state
    'DE': r'[A-Z]{1,3}-[A-Z]{1,2}\s?\d{1,4}',  # German
    'FR': r'[A-Z]{2}-\d{3}-[A-Z]{2}',    # French
    'BE': r'[1-9]-[A-Z]{3}-\d{3}',       # Belgian
}


def preprocess_image(image):
    """
    Preprocess image for better OCR results

    Args:
        image: Input image (BGR format)

    Returns:
        Preprocessed grayscale image
    """
    # Convert to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Apply bilateral filter to reduce noise while preserving edges
    bilateral = cv2.bilateralFilter(gray, 11, 17, 17)

    # Adaptive thresholding for better contrast
    thresh = cv2.adaptiveThreshold(
        bilateral, 255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        11, 2
    )

    return thresh


def detect_plate_regions(image):
    """
    Detect potential license plate regions in image

    Args:
        image: Input image (BGR format)

    Returns:
        List of (x, y, w, h) tuples for detected plate regions
    """
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Edge detection
    edges = cv2.Canny(gray, 30, 200)

    # Find contours
    contours, _ = cv2.findContours(edges, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    # Filter contours that could be license plates
    plate_candidates = []

    for contour in contours:
        area = cv2.contourArea(contour)

        # Filter by area (plates are typically medium-sized regions)
        if area < 500 or area > 50000:
            continue

        # Get bounding rectangle
        x, y, w, h = cv2.boundingRect(contour)

        # License plates have aspect ratio ~2:1 to 6:1
        aspect_ratio = w / h if h > 0 else 0

        if 2.0 <= aspect_ratio <= 6.0:
            plate_candidates.append((x, y, w, h))

    return plate_candidates


def extract_plate_text(image_region, country='NL'):
    """
    Extract plate number from image region using OCR

    Args:
        image_region: Cropped image of plate region
        country: Country code for plate pattern

    Returns:
        Extracted plate number (or None if not found)
    """
    # Preprocess
    preprocessed = preprocess_image(image_region)

    # OCR with custom config for license plates
    custom_config = r'--oem 3 --psm 7 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-'
    text = pytesseract.image_to_string(preprocessed, config=custom_config)

    # Clean up text
    text = text.strip().upper()
    text = re.sub(r'[^A-Z0-9-\s]', '', text)

    # Try to match against country pattern
    pattern = PLATE_PATTERNS.get(country, r'[A-Z0-9-]{5,10}')

    matches = re.findall(pattern, text)

    if matches:
        return matches[0]

    # Fallback: return cleaned text if it looks like a plate
    if len(text) >= 5 and any(c.isdigit() for c in text) and any(c.isalpha() for c in text):
        return text

    return None


def process_image(image_path, country='NL', save_annotated=None):
    """
    Process single image for license plates

    Args:
        image_path: Path to image file
        country: Country code for plate pattern
        save_annotated: Path to save annotated image (optional)

    Returns:
        List of detected plates with metadata
    """
    image = cv2.imread(str(image_path))
    if image is None:
        print(f"Error: Could not load image {image_path}")
        return []

    # Detect plate regions
    plate_regions = detect_plate_regions(image)

    results = []

    for i, (x, y, w, h) in enumerate(plate_regions):
        # Extract region
        plate_region = image[y:y+h, x:x+w]

        # OCR
        plate_text = extract_plate_text(plate_region, country)

        if plate_text:
            results.append({
                'plate_number': plate_text,
                'confidence': 0.8,  # Simplified confidence
                'bbox': (x, y, w, h),
                'region_id': i
            })

            # Annotate image if requested
            if save_annotated:
                cv2.rectangle(image, (x, y), (x+w, y+h), (0, 255, 0), 2)
                cv2.putText(image, plate_text, (x, y-10),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

    # Save annotated image
    if save_annotated and results:
        cv2.imwrite(str(save_annotated), image)

    return results


def process_directory(input_dir, output_csv, country='NL', save_annotated_dir=None):
    """
    Process directory of images for license plates

    Args:
        input_dir: Input directory with images
        output_csv: Output CSV file for results
        country: Country code for plate pattern
        save_annotated_dir: Directory to save annotated images (optional)
    """
    input_path = Path(input_dir)

    if save_annotated_dir:
        annotated_path = Path(save_annotated_dir)
        annotated_path.mkdir(parents=True, exist_ok=True)

    image_extensions = {'.jpg', '.jpeg', '.png', '.bmp'}
    image_files = [f for f in input_path.iterdir()
                   if f.suffix.lower() in image_extensions]

    print(f"Processing {len(image_files)} images for license plates...")
    print(f"Country: {country}")
    print("="*60)

    all_results = []

    for img_file in image_files:
        print(f"Processing: {img_file.name}...", end=" ")

        annotated_file = None
        if save_annotated_dir:
            annotated_file = annotated_path / f"annotated_{img_file.name}"

        results = process_image(img_file, country, annotated_file)

        if results:
            print(f"✓ {len(results)} plate(s) detected")
            for result in results:
                all_results.append({
                    'image': img_file.name,
                    'plate_number': result['plate_number'],
                    'confidence': result['confidence'],
                    'bbox': str(result['bbox'])
                })
        else:
            print("No plates detected")

    # Save to CSV
    if all_results:
        with open(output_csv, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=['image', 'plate_number', 'confidence', 'bbox'])
            writer.writeheader()
            writer.writerows(all_results)

    print("="*60)
    print(f"ANPR Complete")
    print("="*60)
    print(f"Images processed: {len(image_files)}")
    print(f"Plates detected: {len(all_results)}")
    print(f"Results saved to: {output_csv}")
    if save_annotated_dir:
        print(f"Annotated images: {save_annotated_dir}")
    print("="*60)

    # Print detected plates
    if all_results:
        print("\nDETECTED PLATES:")
        print("-"*60)
        for result in all_results:
            print(f"{result['image']:30} → {result['plate_number']}")

    return all_results


def main():
    parser = argparse.ArgumentParser(
        description="Automatic Number Plate Recognition (ANPR)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Supported countries:
  NL - Netherlands (AB-123-CD)
  UK - United Kingdom (AB12 CDE)
  US - United States (ABC-1234)
  DE - Germany (B-AB 1234)
  FR - France (AB-123-CD)
  BE - Belgium (1-ABC-123)

Examples:
  # Process directory for Dutch plates
  %(prog)s --dir traffic_cam_frames/ --output plates.csv --country NL

  # With annotated output
  %(prog)s --dir frames/ --output plates.csv --annotate annotated/

  # Single image
  %(prog)s --file vehicle.jpg --country UK
        """
    )

    parser.add_argument('--dir', help='Input directory with images')
    parser.add_argument('--file', help='Single image file')
    parser.add_argument('--output', help='Output CSV file')
    parser.add_argument('--country', default='NL', choices=PLATE_PATTERNS.keys(),
                       help='Country code for plate format (default: NL)')
    parser.add_argument('--annotate', help='Directory to save annotated images')

    args = parser.parse_args()

    if not args.dir and not args.file:
        parser.error("Either --dir or --file must be specified")

    if args.dir:
        if not args.output:
            args.output = "anpr_results.csv"
        process_directory(args.dir, args.output, args.country, args.annotate)

    elif args.file:
        results = process_image(args.file, args.country)
        if results:
            print(f"\nDetected plate(s):")
            for result in results:
                print(f"  {result['plate_number']} (confidence: {result['confidence']:.2f})")
        else:
            print("\nNo plates detected")


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
