#!/bin/bash
# Add Expense - Manual expense entry to database
# Simple expense tracking without complex dependencies

VERSION="1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default values
DATABASE="${EXPENSE_DB:-$HOME/.expenses/expenses.db}"
AMOUNT=""
MERCHANT=""
CATEGORY="Uncategorized"
SUBCATEGORY=""
DATE=$(date +%Y-%m-%d)
PAYMENT_METHOD=""
CURRENCY="USD"
NOTES=""
RECEIPT=""
TAX_DEDUCTIBLE=0
BILLABLE=0
CLIENT=""
PROJECT=""
TRIP=""

# Usage
usage() {
    cat << EOF
${BOLD}Add Expense v${VERSION}${NC}
Manually add expense entry to database

${BOLD}USAGE:${NC}
    $0 --amount <amount> [options]

${BOLD}REQUIRED:${NC}
    --amount <amount>           Expense amount (e.g., 49.99)

${BOLD}OPTIONS:${NC}
    --merchant <name>           Merchant/vendor name
    --category <category>       Expense category
    --subcategory <subcat>      Subcategory
    --date <YYYY-MM-DD>         Expense date (default: today)
    --payment <method>          Payment method
    --currency <code>           Currency code (default: USD)
    --notes <text>              Additional notes
    --receipt <file>            Attach receipt file
    --tax-deductible            Mark as tax deductible
    --billable                  Mark as billable to client
    --client <name>             Client name (if billable)
    --project <name>            Project name
    --trip <name>               Trip/travel name
    --database <file>           Database file (default: ~/.expenses/expenses.db)
    --help, -h                  Show this help

${BOLD}EXAMPLES:${NC}
    # Simple expense
    $0 --amount 25.50 --merchant "Starbucks" --category "Meals"

    # Business expense
    $0 --amount 1200 \\
       --merchant "AWS" \\
       --category "Cloud Services" \\
       --payment "Credit Card" \\
       --tax-deductible \\
       --notes "Monthly hosting"

    # Travel expense
    $0 --amount 350 \\
       --merchant "Hotel Marriott" \\
       --category "Lodging" \\
       --trip "SF Sales Conference" \\
       --receipt hotel_receipt.pdf
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --amount)
            AMOUNT="$2"
            shift 2
            ;;
        --merchant)
            MERCHANT="$2"
            shift 2
            ;;
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        --subcategory)
            SUBCATEGORY="$2"
            shift 2
            ;;
        --date)
            DATE="$2"
            shift 2
            ;;
        --payment)
            PAYMENT_METHOD="$2"
            shift 2
            ;;
        --currency)
            CURRENCY="$2"
            shift 2
            ;;
        --notes)
            NOTES="$2"
            shift 2
            ;;
        --receipt)
            RECEIPT="$2"
            shift 2
            ;;
        --tax-deductible)
            TAX_DEDUCTIBLE=1
            shift
            ;;
        --billable)
            BILLABLE=1
            shift
            ;;
        --client)
            CLIENT="$2"
            shift 2
            ;;
        --project)
            PROJECT="$2"
            shift 2
            ;;
        --trip)
            TRIP="$2"
            shift 2
            ;;
        --database)
            DATABASE="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$AMOUNT" ]; then
    echo -e "${RED}Error: --amount is required${NC}"
    usage
    exit 1
fi

# Validate amount is a number
if ! [[ "$AMOUNT" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    echo -e "${RED}Error: Invalid amount: $AMOUNT${NC}"
    exit 1
fi

# Check if sqlite3 is available
if ! command -v sqlite3 &> /dev/null; then
    echo -e "${RED}Error: sqlite3 is not installed${NC}"
    echo "Install with:"
    echo "  Ubuntu/Debian: sudo apt-get install sqlite3"
    echo "  macOS: brew install sqlite3"
    exit 1
fi

# Create database directory if it doesn't exist
mkdir -p "$(dirname "$DATABASE")"

# Initialize database if it doesn't exist
if [ ! -f "$DATABASE" ]; then
    echo -e "${BLUE}Creating new database: $DATABASE${NC}"

    sqlite3 "$DATABASE" << 'EOF'
CREATE TABLE IF NOT EXISTS expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    amount REAL NOT NULL,
    currency TEXT DEFAULT 'USD',
    merchant TEXT,
    category TEXT,
    subcategory TEXT,
    payment_method TEXT,
    notes TEXT,
    receipt_path TEXT,
    tax_deductible INTEGER DEFAULT 0,
    billable INTEGER DEFAULT 0,
    client TEXT,
    project TEXT,
    trip TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    parent_category TEXT,
    tax_deductible INTEGER DEFAULT 0
);

-- Insert common categories
INSERT OR IGNORE INTO categories (name, tax_deductible) VALUES
    ('Groceries', 0),
    ('Meals & Dining', 0),
    ('Transportation', 0),
    ('Airfare', 1),
    ('Lodging', 1),
    ('Shopping', 0),
    ('Office Supplies', 1),
    ('Cloud Services', 1),
    ('Software', 1),
    ('Utilities', 0),
    ('Healthcare', 1),
    ('Entertainment', 0),
    ('Uncategorized', 0);
EOF

    echo -e "${GREEN}✓ Database initialized${NC}"
    echo ""
fi

# Copy receipt file if specified
RECEIPT_PATH=""
if [ -n "$RECEIPT" ]; then
    if [ -f "$RECEIPT" ]; then
        RECEIPT_DIR="$(dirname "$DATABASE")/receipts"
        mkdir -p "$RECEIPT_DIR"

        # Generate filename: YYYY-MM-DD_merchant_amount.ext
        FILENAME="${DATE}_${MERCHANT//' '/'_'}_${AMOUNT}.${RECEIPT##*.}"
        RECEIPT_PATH="$RECEIPT_DIR/$FILENAME"

        cp "$RECEIPT" "$RECEIPT_PATH"
        echo -e "${GREEN}✓ Receipt copied to: $RECEIPT_PATH${NC}"
    else
        echo -e "${YELLOW}⚠ Receipt file not found: $RECEIPT${NC}"
    fi
fi

# Insert expense into database
sqlite3 "$DATABASE" << EOF
INSERT INTO expenses (
    date, amount, currency, merchant, category, subcategory,
    payment_method, notes, receipt_path, tax_deductible,
    billable, client, project, trip
) VALUES (
    '$DATE', $AMOUNT, '$CURRENCY', '$MERCHANT', '$CATEGORY', '$SUBCATEGORY',
    '$PAYMENT_METHOD', '$NOTES', '$RECEIPT_PATH', $TAX_DEDUCTIBLE,
    $BILLABLE, '$CLIENT', '$PROJECT', '$TRIP'
);
EOF

# Get inserted ID
EXPENSE_ID=$(sqlite3 "$DATABASE" "SELECT last_insert_rowid();")

# Print summary
echo -e "${CYAN}${'═' * 70}${NC}"
echo -e "${BOLD}Expense Added${NC}"
echo -e "${CYAN}${'═' * 70}${NC}"
echo "ID:       #$EXPENSE_ID"
echo "Date:     $DATE"
echo "Amount:   $CURRENCY $AMOUNT"
[ -n "$MERCHANT" ] && echo "Merchant: $MERCHANT"
echo "Category: $CATEGORY"
[ -n "$SUBCATEGORY" ] && echo "Subcategory: $SUBCATEGORY"
[ -n "$PAYMENT_METHOD" ] && echo "Payment:  $PAYMENT_METHOD"
[ -n "$NOTES" ] && echo "Notes:    $NOTES"
[ $TAX_DEDUCTIBLE -eq 1 ] && echo -e "Tax:      ${GREEN}Deductible${NC}"
[ $BILLABLE -eq 1 ] && echo -e "Billable: ${GREEN}Yes${NC}"
[ -n "$CLIENT" ] && echo "Client:   $CLIENT"
[ -n "$PROJECT" ] && echo "Project:  $PROJECT"
[ -n "$TRIP" ] && echo "Trip:     $TRIP"
[ -n "$RECEIPT_PATH" ] && echo "Receipt:  $RECEIPT_PATH"
echo ""
echo -e "${GREEN}✓ Expense saved to database${NC}"
echo "Database: $DATABASE"
