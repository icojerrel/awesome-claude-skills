#!/usr/bin/env python3
"""
Face Recognition Against Known Database
Match unknown faces against database of known suspects/persons of interest
"""

import argparse
import face_recognition
import os
import json
from pathlib import Path
import sys
import pickle

def build_face_database(known_faces_dir, output_file="face_encodings.pkl"):
    """
    Build face encodings database from known face images

    Args:
        known_faces_dir: Directory with subdirectories per person
        output_file: Output pickle file for encodings

    Directory structure:
        known_faces/
            john_doe/
                photo1.jpg
                photo2.jpg
            jane_smith/
                photo1.jpg
    """
    known_encodings = []
    known_names = []

    known_path = Path(known_faces_dir)

    print(f"Building face database from: {known_faces_dir}")
    print("="*60)

    # Iterate through each person's directory
    for person_dir in known_path.iterdir():
        if not person_dir.is_dir():
            continue

        person_name = person_dir.name
        print(f"Processing: {person_name}...")

        # Process all images for this person
        for img_file in person_dir.glob("*.jpg") + person_dir.glob("*.png"):
            try:
                image = face_recognition.load_image_file(str(img_file))
                encodings = face_recognition.face_encodings(image)

                if encodings:
                    known_encodings.append(encodings[0])
                    known_names.append(person_name)
                    print(f"  ✓ Encoded: {img_file.name}")
                else:
                    print(f"  ⚠ No face found in: {img_file.name}")

            except Exception as e:
                print(f"  ✗ Error processing {img_file.name}: {e}")

    # Save encodings to pickle file
    database = {
        'encodings': known_encodings,
        'names': known_names
    }

    with open(output_file, 'wb') as f:
        pickle.dump(database, f)

    print("="*60)
    print(f"Database built: {len(known_encodings)} face(s) from {len(set(known_names))} person(s)")
    print(f"Saved to: {output_file}")
    print("="*60)

    return database


def recognize_faces(unknown_dir, database_file, threshold=0.6, output_file=None):
    """
    Match unknown faces against database

    Args:
        unknown_dir: Directory with unknown face images
        database_file: Pickle file with face encodings
        threshold: Match threshold (lower = stricter, default: 0.6)
        output_file: JSON file for results
    """
    # Load database
    print(f"Loading database: {database_file}")
    with open(database_file, 'rb') as f:
        database = pickle.load(f)

    known_encodings = database['encodings']
    known_names = database['names']

    print(f"Database loaded: {len(known_encodings)} known faces")
    print("="*60)

    unknown_path = Path(unknown_dir)
    results = []
    matches_found = 0

    # Process each unknown face image
    for img_file in unknown_path.glob("*.jpg"):
        try:
            print(f"Processing: {img_file.name}...", end=" ")

            image = face_recognition.load_image_file(str(img_file))
            unknown_encodings = face_recognition.face_encodings(image)

            if not unknown_encodings:
                print("No face detected")
                continue

            # Compare first face in image
            unknown_encoding = unknown_encodings[0]

            # Calculate distances to all known faces
            face_distances = face_recognition.face_distance(known_encodings, unknown_encoding)

            # Find best match
            best_match_index = face_distances.argmin()
            best_distance = face_distances[best_match_index]

            if best_distance < threshold:
                matched_name = known_names[best_match_index]
                confidence = 1 - best_distance

                print(f"✓ MATCH: {matched_name} (confidence: {confidence:.2f})")
                matches_found += 1

                results.append({
                    'unknown_image': str(img_file.name),
                    'matched_person': matched_name,
                    'confidence': float(confidence),
                    'distance': float(best_distance),
                    'status': 'MATCH'
                })
            else:
                print(f"No match (closest: {known_names[best_match_index]}, distance: {best_distance:.2f})")

                results.append({
                    'unknown_image': str(img_file.name),
                    'matched_person': None,
                    'confidence': 0.0,
                    'distance': float(best_distance),
                    'status': 'NO_MATCH'
                })

        except Exception as e:
            print(f"Error: {e}")

    # Save results
    if output_file:
        with open(output_file, 'w') as f:
            json.dump(results, f, indent=2)

    print("="*60)
    print(f"Recognition Complete")
    print("="*60)
    print(f"Images processed: {len(results)}")
    print(f"Matches found: {matches_found}")
    if output_file:
        print(f"Results saved to: {output_file}")
    print("="*60)

    # Print matches summary
    if matches_found > 0:
        print("\nMATCHES FOUND:")
        print("-"*60)
        for result in results:
            if result['status'] == 'MATCH':
                print(f"{result['unknown_image']:30} → {result['matched_person']:20} ({result['confidence']:.2%})")

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Face Recognition for Forensic Analysis",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Build database from known faces
  %(prog)s --build-database known_faces/ --output suspects.pkl

  # Match unknown faces against database
  %(prog)s --unknown faces_from_cctv/ --database suspects.pkl --output matches.json

  # Adjust threshold (stricter matching)
  %(prog)s --unknown faces/ --database suspects.pkl --threshold 0.5
        """
    )

    parser.add_argument('--build-database', help='Build face database from directory')
    parser.add_argument('--unknown', help='Directory with unknown faces to match')
    parser.add_argument('--database', help='Face database pickle file')
    parser.add_argument('--threshold', type=float, default=0.6,
                       help='Match threshold (0-1, lower=stricter, default: 0.6)')
    parser.add_argument('--output', help='Output JSON file for results')

    args = parser.parse_args()

    if args.build_database:
        output_file = args.output or "face_encodings.pkl"
        build_face_database(args.build_database, output_file)

    elif args.unknown and args.database:
        recognize_faces(args.unknown, args.database, args.threshold, args.output)

    else:
        parser.error("Either --build-database or (--unknown and --database) must be specified")


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
