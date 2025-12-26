#!/bin/bash
# Dockerfile Analyzer - Best Practices Checker
VERSION="1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOCKERFILE="${1:-Dockerfile}"
SCORE=100
ISSUES=0

if [ ! -f "$DOCKERFILE" ]; then
    echo -e "${RED}Error: $DOCKERFILE not found${NC}"
    exit 1
fi

echo "Analyzing: $DOCKERFILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check base image
if grep -q "FROM scratch" "$DOCKERFILE"; then
    echo -e "${GREEN}✓ Using minimal base image (scratch)${NC}"
elif grep -q "FROM alpine" "$DOCKERFILE"; then
    echo -e "${GREEN}✓ Using lightweight base image (alpine)${NC}"
elif grep -q "FROM.*:latest" "$DOCKERFILE"; then
    echo -e "${YELLOW}⚠ Using :latest tag - pin specific versions${NC}"
    ((SCORE-=10))
    ((ISSUES++))
fi

# Check for apt-get without cleanup
if grep -q "apt-get install" "$DOCKERFILE" && ! grep -q "rm -rf /var/lib/apt/lists" "$DOCKERFILE"; then
    echo -e "${YELLOW}⚠ apt-get without cleanup - adds unnecessary size${NC}"
    ((SCORE-=5))
    ((ISSUES++))
fi

# Check USER directive
if ! grep -q "^USER " "$DOCKERFILE"; then
    echo -e "${YELLOW}⚠ No USER directive - running as root${NC}"
    ((SCORE-=15))
    ((ISSUES++))
fi

# Check for COPY . .
if grep -q "COPY \\. \\." "$DOCKERFILE"; then
    echo -e "${YELLOW}⚠ Using 'COPY . .' - use .dockerignore${NC}"
    ((SCORE-=5))
    ((ISSUES++))
fi

# Check layer count
LAYER_COUNT=$(grep -c "^RUN\|^COPY\|^ADD" "$DOCKERFILE")
if [ "$LAYER_COUNT" -gt 20 ]; then
    echo -e "${YELLOW}⚠ Too many layers ($LAYER_COUNT) - combine commands${NC}"
    ((SCORE-=10))
    ((ISSUES++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Score: $SCORE/100"
echo "Issues: $ISSUES"

if [ $SCORE -ge 80 ]; then
    echo -e "${GREEN}✓ Good Dockerfile${NC}"
elif [ $SCORE -ge 60 ]; then
    echo -e "${YELLOW}⚠ Needs improvement${NC}"
else
    echo -e "${RED}✗ Poor Dockerfile - significant issues${NC}"
fi
