#!/bin/bash
# Query Analyzer - SQL Query Performance Analysis
VERSION="1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

QUERY="$1"

if [ -z "$QUERY" ]; then
    echo "Usage: $0 'SELECT * FROM users'"
    exit 1
fi

echo -e "${CYAN}Query Analysis${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Query: $QUERY"
echo ""

# Check for common anti-patterns
SCORE=100

# SELECT *
if echo "$QUERY" | grep -qi "SELECT \*"; then
    echo -e "${YELLOW}⚠ Using SELECT * - specify needed columns${NC}"
    ((SCORE-=10))
fi

# Missing WHERE
if echo "$QUERY" | grep -qi "SELECT" && ! echo "$QUERY" | grep -qi "WHERE"; then
    echo -e "${YELLOW}⚠ No WHERE clause - may return too many rows${NC}"
    ((SCORE-=5))
fi

# No LIMIT
if echo "$QUERY" | grep -qi "SELECT" && ! echo "$QUERY" | grep -qi "LIMIT"; then
    echo -e "${YELLOW}⚠ No LIMIT - consider adding LIMIT${NC}"
    ((SCORE-=5))
fi

# LIKE without index
if echo "$QUERY" | grep -qi "LIKE '%"; then
    echo -e "${YELLOW}⚠ LIKE with leading wildcard - cannot use index${NC}"
    ((SCORE-=15))
fi

# OR in WHERE
if echo "$QUERY" | grep -qi "WHERE.*OR"; then
    echo -e "${YELLOW}⚠ OR in WHERE - may prevent index usage${NC}"
    ((SCORE-=10))
fi

echo ""
echo "Score: $SCORE/100"
if [ $SCORE -ge 80 ]; then
    echo -e "${GREEN}✓ Good query${NC}"
elif [ $SCORE -ge 60 ]; then
    echo -e "${YELLOW}⚠ Needs optimization${NC}"
else
    echo -e "${RED}✗ Poor query - significant issues${NC}"
fi
