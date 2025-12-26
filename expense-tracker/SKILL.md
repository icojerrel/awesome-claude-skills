---
name: expense-tracker
description: Personal and business expense tracking with receipt parsing, categorization, budgeting, and tax reporting. OCR receipt scanning, automatic categorization, monthly reports, budget alerts, and multi-currency support. Perfect for freelancers, small businesses, and personal finance.
---

# Expense Tracker

Comprehensive expense management for individuals and businesses.

## When to Use This Skill

- Personal expense tracking
- Business expense management
- Receipt digitization and organization
- Tax preparation and deductions
- Budget monitoring and alerts
- Travel expense reporting
- Team expense consolidation
- Monthly financial summaries
- Multi-currency expense tracking
- Subscription tracking

## Capabilities

### 1. Receipt Processing
- OCR text extraction (Tesseract)
- Image preprocessing
- Merchant name detection
- Amount extraction
- Date parsing
- Category suggestion
- PDF receipt handling
- Batch processing

### 2. Expense Categorization
- Automatic category detection
- Custom category rules
- Machine learning classification
- Merchant-based rules
- Keyword matching
- Manual override
- Subcategory support

### 3. Financial Reporting
- Monthly expense summaries
- Category breakdowns
- Year-over-year comparison
- Budget vs actual tracking
- Tax-deductible expenses
- Client/project reports
- CSV/PDF export
- Visual charts and graphs

### 4. Budget Management
- Budget allocation by category
- Spending alerts
- Budget warnings (80%, 90%, 100%)
- Remaining budget tracking
- Historical trends
- Forecasting
- Goal setting

### 5. Multi-Currency Support
- Currency conversion
- Exchange rate tracking
- Multi-currency reports
- Base currency selection
- Historical rates
- Cryptocurrency support

### 6. Integrations
- Email receipt parsing
- Bank statement import
- Credit card CSV import
- API integrations (Stripe, PayPal)
- Cloud storage (Dropbox, Google Drive)
- Accounting software export

## Instructions

When a user requests expense tracking:

### 1. Understand Requirements

Ask:
- Personal or business expenses?
- Receipt processing needed?
- Budget tracking required?
- Tax reporting needed?
- Multiple currencies?
- Integration requirements?

### 2. Receipt Scanning

```bash
# Scan single receipt
./receipt_parser.py \
  --image receipt.jpg \
  --output expense.json

# Batch processing
./receipt_parser.py \
  --directory receipts/ \
  --output-dir processed/ \
  --format json

# PDF receipts
./receipt_parser.py \
  --pdf invoice.pdf \
  --output expense.json

# With category suggestion
./receipt_parser.py \
  --image receipt.jpg \
  --auto-categorize \
  --output expense.json
```

### 3. Manual Entry

```bash
# Add expense
./add_expense.sh \
  --amount 49.99 \
  --merchant "Coffee Shop" \
  --category "Meals" \
  --date "2024-01-15" \
  --payment "Credit Card"

# With notes
./add_expense.sh \
  --amount 120.00 \
  --merchant "Office Depot" \
  --category "Office Supplies" \
  --notes "Printer paper and ink" \
  --tax-deductible

# Multiple currencies
./add_expense.sh \
  --amount 50 \
  --currency EUR \
  --merchant "Paris Restaurant" \
  --category "Meals" \
  --convert-to USD
```

### 4. Budget Tracking

```bash
# Set budget
./budget_manager.py \
  --category "Groceries" \
  --amount 600 \
  --period monthly

# Check budget status
./budget_manager.py --status

# Budget alerts
./budget_manager.py \
  --check-all \
  --alert-threshold 80
```

### 5. Reporting

```bash
# Monthly report
./expense_report.py \
  --month 2024-01 \
  --output report.pdf

# Category breakdown
./expense_report.py \
  --date-range "2024-01-01:2024-01-31" \
  --group-by category \
  --output category_report.csv

# Tax report
./expense_report.py \
  --year 2023 \
  --tax-deductible-only \
  --output tax_deductions_2023.pdf

# Year-over-year comparison
./expense_report.py \
  --compare-years 2023,2024 \
  --category "All" \
  --chart comparison.png
```

## Example Workflows

### Freelancer Tax Deductions

```bash
# Scan all 2023 receipts
./receipt_parser.py \
  --directory ~/receipts/2023/ \
  --output-dir ~/expenses/2023/ \
  --auto-categorize

# Import to database
./import_expenses.sh \
  --directory ~/expenses/2023/ \
  --database expenses.db

# Generate tax report
./expense_report.py \
  --year 2023 \
  --tax-deductible-only \
  --categories "Office Supplies,Software,Equipment,Meals,Travel" \
  --output tax_report_2023.pdf

# Export for accountant
./export_for_tax.py \
  --year 2023 \
  --format csv \
  --include-receipts \
  --output tax_package_2023.zip
```

### Business Travel Expenses

```bash
# Create trip
./trip_tracker.py \
  --create \
  --name "SF Sales Conference" \
  --start-date "2024-01-20" \
  --end-date "2024-01-22"

# Add expenses during trip
./add_expense.sh \
  --amount 350 \
  --merchant "Hotel Marriott" \
  --category "Lodging" \
  --trip "SF Sales Conference" \
  --receipt hotel_receipt.pdf

./add_expense.sh \
  --amount 45 \
  --merchant "Uber" \
  --category "Transportation" \
  --trip "SF Sales Conference"

# Generate trip report
./trip_tracker.py \
  --report "SF Sales Conference" \
  --output trip_report.pdf
```

### Monthly Budget Monitoring

```bash
# Setup monthly budgets
./budget_manager.py --init-defaults

# Daily check (cron job)
./budget_manager.py \
  --check-all \
  --alert-threshold 80 \
  --notify-email you@example.com

# End of month review
./expense_report.py \
  --month $(date +%Y-%m) \
  --budget-comparison \
  --output monthly_review.pdf
```

### Small Business Accounting

```bash
# Import bank transactions
./import_bank_csv.py \
  --file bank_statement.csv \
  --format chase \
  --auto-categorize

# Reconcile expenses
./reconcile.py \
  --date "2024-01-31" \
  --bank-balance 15432.50

# Client expense report
./expense_report.py \
  --client "Acme Corp" \
  --date-range "2024-01-01:2024-01-31" \
  --billable-only \
  --output client_expenses_jan2024.pdf

# QuickBooks export
./export_quickbooks.py \
  --month 2024-01 \
  --output quickbooks_import.iif
```

## Tools Reference

### receipt_parser.py

**Purpose**: Extract expense data from receipt images/PDFs

**Options**:
- `--image <FILE>` - Receipt image file
- `--pdf <FILE>` - PDF receipt
- `--directory <DIR>` - Batch process directory
- `--output <FILE>` - Output JSON file
- `--output-dir <DIR>` - Batch output directory
- `--auto-categorize` - Suggest category
- `--ocr-language <LANG>` - OCR language (default: eng)
- `--preprocess` - Image preprocessing
- `--verbose` - Detailed output

**Examples**:
```bash
# Single receipt
./receipt_parser.py --image receipt.jpg --output expense.json

# Batch processing
./receipt_parser.py --directory receipts/ --output-dir processed/

# PDF with preprocessing
./receipt_parser.py --pdf invoice.pdf --preprocess --output expense.json
```

### add_expense.sh

**Purpose**: Manually add expense entry

**Options**:
- `--amount <AMOUNT>` - Expense amount (required)
- `--merchant <NAME>` - Merchant/vendor name
- `--category <CATEGORY>` - Expense category
- `--subcategory <SUBCATEGORY>` - Subcategory
- `--date <DATE>` - Expense date (YYYY-MM-DD)
- `--payment <METHOD>` - Payment method
- `--currency <CODE>` - Currency code (default: USD)
- `--notes <TEXT>` - Additional notes
- `--receipt <FILE>` - Attach receipt file
- `--tax-deductible` - Mark as tax deductible
- `--billable` - Mark as billable to client
- `--client <NAME>` - Client name (if billable)
- `--project <NAME>` - Project name
- `--trip <NAME>` - Trip/travel name

**Examples**:
```bash
# Simple expense
./add_expense.sh --amount 25.50 --merchant "Starbucks" --category "Meals"

# Business expense
./add_expense.sh \
  --amount 1200 \
  --merchant "AWS" \
  --category "Cloud Services" \
  --payment "Credit Card" \
  --tax-deductible \
  --notes "Monthly hosting"
```

### budget_manager.py

**Purpose**: Manage budgets and track spending

**Options**:
- `--set-budget` - Set category budget
- `--category <CATEGORY>` - Category name
- `--amount <AMOUNT>` - Budget amount
- `--period <PERIOD>` - Period (monthly, yearly)
- `--status` - Show budget status
- `--check-all` - Check all budgets
- `--alert-threshold <PCT>` - Alert threshold %
- `--notify-email <EMAIL>` - Email for alerts

**Examples**:
```bash
# Set budget
./budget_manager.py --set-budget --category "Groceries" --amount 600 --period monthly

# Check status
./budget_manager.py --status

# Check with alerts
./budget_manager.py --check-all --alert-threshold 80
```

### expense_report.py

**Purpose**: Generate expense reports and summaries

**Options**:
- `--month <YYYY-MM>` - Monthly report
- `--year <YYYY>` - Yearly report
- `--date-range <START:END>` - Custom date range
- `--category <CATEGORY>` - Filter by category
- `--tax-deductible-only` - Only tax deductible
- `--billable-only` - Only billable expenses
- `--client <NAME>` - Filter by client
- `--project <NAME>` - Filter by project
- `--group-by <FIELD>` - Group by (category, merchant, date)
- `--budget-comparison` - Compare to budget
- `--compare-years <YEARS>` - Year comparison
- `--output <FILE>` - Output file (PDF/CSV)
- `--chart <FILE>` - Generate chart image
- `--format <FORMAT>` - Format (pdf, csv, json, html)

**Examples**:
```bash
# Monthly report
./expense_report.py --month 2024-01 --output january.pdf

# Tax deductions
./expense_report.py --year 2023 --tax-deductible-only --output tax2023.pdf

# Category breakdown
./expense_report.py --date-range "2024-01-01:2024-01-31" --group-by category
```

### category_trainer.py

**Purpose**: Train automatic categorization rules

**Options**:
- `--train` - Train from existing data
- `--add-rule` - Add categorization rule
- `--merchant <NAME>` - Merchant name pattern
- `--keyword <WORD>` - Keyword pattern
- `--category <CATEGORY>` - Category to assign
- `--test` - Test categorization accuracy
- `--export-rules <FILE>` - Export rules to JSON

**Examples**:
```bash
# Train from history
./category_trainer.py --train

# Add merchant rule
./category_trainer.py --add-rule --merchant "Safeway" --category "Groceries"

# Test accuracy
./category_trainer.py --test
```

## Data Storage

### Database Schema (SQLite)

```sql
CREATE TABLE expenses (
    id INTEGER PRIMARY KEY,
    date TEXT NOT NULL,
    amount REAL NOT NULL,
    currency TEXT DEFAULT 'USD',
    merchant TEXT,
    category TEXT,
    subcategory TEXT,
    payment_method TEXT,
    notes TEXT,
    receipt_path TEXT,
    tax_deductible BOOLEAN DEFAULT 0,
    billable BOOLEAN DEFAULT 0,
    client TEXT,
    project TEXT,
    trip TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE budgets (
    id INTEGER PRIMARY KEY,
    category TEXT NOT NULL,
    amount REAL NOT NULL,
    period TEXT DEFAULT 'monthly',
    start_date TEXT,
    end_date TEXT
);

CREATE TABLE categories (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    parent_category TEXT,
    tax_deductible BOOLEAN DEFAULT 0
);

CREATE TABLE categorization_rules (
    id INTEGER PRIMARY KEY,
    pattern TEXT NOT NULL,
    pattern_type TEXT, -- merchant, keyword
    category TEXT NOT NULL,
    confidence REAL DEFAULT 1.0
);
```

## Best Practices

### Receipt Management

1. **Scan Immediately**
   - Scan receipts as soon as possible
   - Thermal receipts fade quickly
   - Use high-quality scans (300 DPI minimum)

2. **Organize Files**
   ```
   receipts/
   ├── 2024/
   │   ├── 01-January/
   │   │   ├── 2024-01-15_starbucks.jpg
   │   │   └── 2024-01-20_office_depot.pdf
   │   └── 02-February/
   └── 2023/
   ```

3. **Naming Convention**
   - `YYYY-MM-DD_merchant_amount.ext`
   - Example: `2024-01-15_amazon_49.99.jpg`

### Categorization

**Common Categories**:
- **Business**: Office Supplies, Software, Equipment, Marketing, Legal
- **Travel**: Airfare, Lodging, Meals, Transportation, Entertainment
- **Personal**: Groceries, Dining, Healthcare, Utilities, Shopping
- **Tax Deductible**: Home Office, Professional Development, Charitable

### Tax Preparation

1. **Track Deductibles Throughout Year**
   - Mark expenses as tax-deductible immediately
   - Keep all receipts for deductions
   - Separate business and personal

2. **Required Information**
   - Date of expense
   - Amount
   - Business purpose
   - Receipt/proof

3. **Common Deductions**
   - Home office expenses
   - Business travel and meals
   - Professional development
   - Equipment and software
   - Vehicle mileage

## Security & Privacy

**Data Protection**:
```bash
# Encrypt database
./encrypt_database.sh --database expenses.db --password

# Backup (encrypted)
./backup.sh --encrypt --output expenses_backup_$(date +%Y%m%d).enc

# Secure delete receipts after archiving
./archive_receipts.sh --year 2023 --secure-delete
```

**Best Practices**:
- Encrypt sensitive financial data
- Use strong passwords
- Regular encrypted backups
- Secure cloud storage
- Limit access permissions
- GDPR/privacy compliance

## Common Use Cases

**Freelancer/Self-Employed**:
```
Track all business expenses
Quarterly tax estimates
Mileage tracking
Client billing
Year-end tax preparation
```

**Small Business**:
```
Team expense tracking
Department budgets
Client project expenses
Vendor management
Accounting integration
```

**Personal Finance**:
```
Monthly budgeting
Spending habits
Savings goals
Subscription tracking
Tax deduction optimization
```

**Travel & Events**:
```
Conference expenses
Per diem tracking
Mileage/kilometer logs
Reimbursement requests
Travel budgets
```

## Troubleshooting

**OCR Not Working**:
```bash
# Install Tesseract
sudo apt-get install tesseract-ocr  # Ubuntu/Debian
brew install tesseract              # macOS

# Image quality too low
./receipt_parser.py --image receipt.jpg --preprocess
```

**Wrong Category**:
```bash
# Manual override
./update_expense.sh --id 123 --category "Office Supplies"

# Add categorization rule
./category_trainer.py --add-rule --merchant "Amazon" --category "Online Shopping"
```

**Budget Alerts Not Working**:
```bash
# Check budget setup
./budget_manager.py --status

# Test alert
./budget_manager.py --check-all --alert-threshold 0 --verbose
```

## Related Skills

- [Data Visualization](../data-visualization/) - Visualize spending patterns
- [PDF Generator](../pdf-generator/) - Generate expense reports
- [Database Optimizer](../database-optimizer/) - Optimize expense database

## Resources

- [IRS Business Expense Deductions](https://www.irs.gov/publications/p535)
- [Tesseract OCR](https://github.com/tesseract-ocr/tesseract)
- [Personal Finance Best Practices](https://www.investopedia.com/personal-finance-4427760)
- [Expense Tracking Apps Comparison](https://www.nerdwallet.com/best/small-business/expense-tracking-apps)
