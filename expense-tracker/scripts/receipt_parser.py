#!/usr/bin/env python3
"""
Receipt Parser - OCR-based Expense Extraction
Extract expense data from receipt images and PDFs
"""

import argparse
import json
import sys
import re
import os
from typing import Dict, Any, List, Optional
from datetime import datetime
from pathlib import Path

VERSION = "1.0"

class Colors:
    """ANSI color codes"""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    NC = '\033[0m'

# Categorization rules (merchant patterns -> category)
CATEGORY_RULES = {
    # Groceries & Food
    r'safeway|kroger|whole foods|trader joe|costco|walmart|target': 'Groceries',
    r'starbucks|coffee|cafe|restaurant|mcdonald|burger|pizza': 'Meals & Dining',

    # Transportation
    r'uber|lyft|taxi|shell|chevron|exxon|bp|gas': 'Transportation',
    r'airlines|delta|united|american air|southwest': 'Airfare',

    # Shopping
    r'amazon|ebay|best buy|apple store|target|walmart': 'Shopping',

    # Office & Business
    r'office depot|staples|fedex|ups|kinko': 'Office Supplies',
    r'aws|google cloud|azure|digitalocean|heroku': 'Cloud Services',
    r'github|jetbrains|adobe': 'Software',

    # Utilities & Services
    r'electric|gas company|water|internet|phone|cable': 'Utilities',

    # Healthcare
    r'pharmacy|cvs|walgreens|doctor|hospital|dental': 'Healthcare',

    # Entertainment
    r'netflix|spotify|steam|playstation|xbox': 'Entertainment',
}

class ReceiptParser:
    """Parse receipts using OCR"""

    def __init__(self, ocr_language='eng', verbose=False):
        self.ocr_language = ocr_language
        self.verbose = verbose

        # Check if pytesseract is available
        try:
            import pytesseract
            from PIL import Image
            self.pytesseract = pytesseract
            self.Image = Image
            self.ocr_available = True
        except ImportError:
            if verbose:
                print(f"{Colors.YELLOW}Warning: pytesseract not available, using pattern matching only{Colors.NC}")
            self.ocr_available = False

    def preprocess_image(self, image_path: str) -> Any:
        """Preprocess image for better OCR"""
        if not self.ocr_available:
            return None

        try:
            from PIL import ImageEnhance, ImageFilter

            img = self.Image.open(image_path)

            # Convert to grayscale
            img = img.convert('L')

            # Increase contrast
            enhancer = ImageEnhance.Contrast(img)
            img = enhancer.enhance(2.0)

            # Sharpen
            img = img.filter(ImageFilter.SHARPEN)

            return img

        except Exception as e:
            if self.verbose:
                print(f"{Colors.YELLOW}Preprocessing failed: {e}{Colors.NC}")
            return self.Image.open(image_path)

    def extract_text(self, image_path: str, preprocess: bool = False) -> str:
        """Extract text from image using OCR"""
        if not self.ocr_available:
            return ""

        try:
            if preprocess:
                img = self.preprocess_image(image_path)
            else:
                img = self.Image.open(image_path)

            text = self.pytesseract.image_to_string(img, lang=self.ocr_language)

            return text

        except Exception as e:
            if self.verbose:
                print(f"{Colors.RED}OCR failed: {e}{Colors.NC}")
            return ""

    def extract_amount(self, text: str) -> Optional[float]:
        """Extract dollar amount from text"""
        # Common patterns for amounts
        patterns = [
            r'\$\s*(\d+[,\d]*\.?\d*)',  # $123.45 or $1,234.56
            r'TOTAL\s*:?\s*\$?\s*(\d+[,\d]*\.?\d*)',  # TOTAL: 123.45
            r'AMOUNT\s*:?\s*\$?\s*(\d+[,\d]*\.?\d*)',  # AMOUNT: 123.45
            r'SUBTOTAL\s*:?\s*\$?\s*(\d+[,\d]*\.?\d*)',  # SUBTOTAL: 123.45
        ]

        amounts = []
        for pattern in patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            for match in matches:
                try:
                    amount = float(match.replace(',', ''))
                    amounts.append(amount)
                except ValueError:
                    continue

        # Return largest amount (likely total)
        return max(amounts) if amounts else None

    def extract_date(self, text: str) -> Optional[str]:
        """Extract date from text"""
        # Common date patterns
        patterns = [
            r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',  # 01/15/2024 or 01-15-24
            r'(\d{4}[/-]\d{1,2}[/-]\d{1,2})',  # 2024-01-15
            r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},?\s+\d{4}',  # Jan 15, 2024
        ]

        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                date_str = match.group(1) if '(' in pattern else match.group(0)
                # Try to parse and format
                try:
                    # Try various formats
                    for fmt in ['%m/%d/%Y', '%m-%d-%Y', '%Y-%m-%d', '%m/%d/%y', '%b %d, %Y']:
                        try:
                            date_obj = datetime.strptime(date_str, fmt)
                            return date_obj.strftime('%Y-%m-%d')
                        except ValueError:
                            continue
                except:
                    continue

        # Default to today if not found
        return datetime.now().strftime('%Y-%m-%d')

    def extract_merchant(self, text: str) -> Optional[str]:
        """Extract merchant name from text (usually first line)"""
        lines = [line.strip() for line in text.split('\n') if line.strip()]

        if not lines:
            return None

        # First non-empty line is usually merchant
        merchant = lines[0]

        # Clean up
        merchant = re.sub(r'[^\w\s&.-]', '', merchant)
        merchant = merchant.strip()

        return merchant if len(merchant) > 2 else None

    def suggest_category(self, merchant: str) -> str:
        """Suggest category based on merchant name"""
        if not merchant:
            return "Uncategorized"

        merchant_lower = merchant.lower()

        for pattern, category in CATEGORY_RULES.items():
            if re.search(pattern, merchant_lower, re.IGNORECASE):
                return category

        return "Uncategorized"

    def parse_receipt(self, image_path: str, preprocess: bool = False,
                     auto_categorize: bool = False) -> Dict[str, Any]:
        """Parse receipt and extract expense data"""
        if self.verbose:
            print(f"{Colors.BLUE}Parsing: {image_path}{Colors.NC}")

        # Extract text
        text = self.extract_text(image_path, preprocess)

        if self.verbose and text:
            print(f"Extracted text ({len(text)} chars)")

        # Extract fields
        amount = self.extract_amount(text)
        date = self.extract_date(text)
        merchant = self.extract_merchant(text)

        expense = {
            'date': date,
            'amount': amount,
            'merchant': merchant,
            'category': self.suggest_category(merchant) if auto_categorize else None,
            'currency': 'USD',
            'receipt_path': os.path.abspath(image_path),
            'raw_text': text[:500] if text else None  # First 500 chars
        }

        if self.verbose:
            print(f"{Colors.GREEN}✓ Parsed:{Colors.NC}")
            print(f"  Merchant: {merchant}")
            print(f"  Amount: ${amount}")
            print(f"  Date: {date}")
            if auto_categorize:
                print(f"  Category: {expense['category']}")

        return expense

def main():
    parser = argparse.ArgumentParser(
        description='Receipt Parser - Extract expense data from receipts',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    # Input
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument('--image', help='Receipt image file')
    input_group.add_argument('--pdf', help='PDF receipt')
    input_group.add_argument('--directory', help='Directory of receipts (batch)')

    # Output
    parser.add_argument('--output', help='Output JSON file')
    parser.add_argument('--output-dir', help='Output directory (batch mode)')
    parser.add_argument('--format', choices=['json', 'csv'], default='json', help='Output format')

    # OCR Options
    parser.add_argument('--ocr-language', default='eng', help='OCR language (default: eng)')
    parser.add_argument('--preprocess', action='store_true', help='Preprocess images')
    parser.add_argument('--auto-categorize', action='store_true', help='Auto-suggest category')

    # Options
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')

    args = parser.parse_args()

    # Print info
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"{Colors.BOLD}Receipt Parser v{VERSION}{Colors.NC}")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print()

    # Create parser
    receipt_parser = ReceiptParser(
        ocr_language=args.ocr_language,
        verbose=args.verbose
    )

    if not receipt_parser.ocr_available:
        print(f"{Colors.YELLOW}Warning: pytesseract not installed{Colors.NC}")
        print("Install with: pip install pytesseract pillow")
        print("Also install Tesseract: https://github.com/tesseract-ocr/tesseract")
        print()

    # Process files
    results = []

    if args.image:
        # Single image
        expense = receipt_parser.parse_receipt(args.image, args.preprocess, args.auto_categorize)
        results.append(expense)

    elif args.pdf:
        print(f"{Colors.YELLOW}PDF parsing not yet implemented{Colors.NC}")
        print("Use: pdf2image to convert PDF to images first")
        sys.exit(1)

    elif args.directory:
        # Batch processing
        path = Path(args.directory)
        image_files = list(path.glob('*.jpg')) + list(path.glob('*.jpeg')) + \
                     list(path.glob('*.png')) + list(path.glob('*.gif'))

        print(f"Found {len(image_files)} images")
        print()

        for image_file in image_files:
            try:
                expense = receipt_parser.parse_receipt(
                    str(image_file),
                    args.preprocess,
                    args.auto_categorize
                )
                results.append(expense)

                # Save individual file if output-dir specified
                if args.output_dir:
                    output_path = Path(args.output_dir) / f"{image_file.stem}.json"
                    output_path.parent.mkdir(parents=True, exist_ok=True)

                    with open(output_path, 'w') as f:
                        json.dump(expense, f, indent=2)

            except Exception as e:
                print(f"{Colors.RED}Error processing {image_file}: {e}{Colors.NC}")

    # Output results
    print()
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"Processed: {len(results)} receipts")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")

    if args.output:
        try:
            if args.format == 'json':
                with open(args.output, 'w') as f:
                    json.dump(results, f, indent=2)
                print(f"{Colors.GREEN}✓ Saved to {args.output} (JSON){Colors.NC}")

            elif args.format == 'csv':
                import csv
                with open(args.output, 'w', newline='') as f:
                    if results:
                        fieldnames = ['date', 'merchant', 'amount', 'category', 'currency', 'receipt_path']
                        writer = csv.DictWriter(f, fieldnames=fieldnames)
                        writer.writeheader()
                        for expense in results:
                            writer.writerow({k: expense.get(k) for k in fieldnames})
                print(f"{Colors.GREEN}✓ Saved to {args.output} (CSV){Colors.NC}")

        except Exception as e:
            print(f"{Colors.RED}Error saving output: {e}{Colors.NC}")
            sys.exit(1)
    else:
        # Print to stdout
        print(json.dumps(results, indent=2))

if __name__ == '__main__':
    main()
