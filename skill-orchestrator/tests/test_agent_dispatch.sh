#!/bin/bash
# Agent Dispatcher Test Suite

echo "═══════════════════════════════════════════════════════════════════════"
echo "🧪 Agent Dispatcher Test Suite"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""

cd "$(dirname "$0")/../scripts"

# Test 1: General-purpose for API testing
echo "Test 1: API Testing Task → general-purpose agent"
echo "─────────────────────────────────────────────────────────────────────"
python3 orchestrator.py --task "Test REST API endpoints" --dispatch | grep -E "Selected Agent:|Reason:"
echo ""

# Test 2: Explore for security analysis
echo "Test 2: Security Analysis → Explore agent (very thorough)"
echo "─────────────────────────────────────────────────────────────────────"
python3 orchestrator.py --task "Audit codebase for security vulnerabilities" --dispatch | grep -E "Selected Agent:|Thoroughness:|Reason:"
echo ""

# Test 3: General-purpose for data visualization
echo "Test 3: Data Visualization → general-purpose agent"
echo "─────────────────────────────────────────────────────────────────────"
python3 orchestrator.py --task "Create dashboard with sales metrics" --dispatch | grep -E "Selected Agent:|Reason:"
echo ""

# Test 4: General-purpose for web scraping
echo "Test 4: Web Scraping → general-purpose agent"
echo "─────────────────────────────────────────────────────────────────────"
python3 orchestrator.py --task "Scrape product data from e-commerce site" --dispatch | grep -E "Selected Agent:|Reason:"
echo ""

# Test 5: Explore for log analysis
echo "Test 5: Log Analysis → Explore agent (quick)"
echo "─────────────────────────────────────────────────────────────────────"
python3 orchestrator.py --task "Parse application logs and find errors" --dispatch | grep -E "Selected Agent:|Thoroughness:|Reason:"
echo ""

# Test 6: Explore for database optimization
echo "Test 6: Database Optimization → Explore agent (medium)"
echo "─────────────────────────────────────────────────────────────────────"
python3 orchestrator.py --task "Find slow database queries" --dispatch | grep -E "Selected Agent:|Thoroughness:|Reason:"
echo ""

# Test 7: General-purpose for receipt parsing
echo "Test 7: Receipt Parsing → general-purpose agent"
echo "─────────────────────────────────────────────────────────────────────"
python3 orchestrator.py --task "Extract data from receipts using OCR" --dispatch | grep -E "Selected Agent:|Reason:"
echo ""

# Test 8: Complex multi-step task
echo "Test 8: Multi-Step Workflow → general-purpose agent"
echo "─────────────────────────────────────────────────────────────────────"
python3 orchestrator.py --task "Scrape data, analyze trends, create visualizations, send report" --dispatch | grep -E "Selected Agent:|Reason:|Will use"
echo ""

echo "═══════════════════════════════════════════════════════════════════════"
echo "✅ Agent Dispatcher Tests Complete"
echo "═══════════════════════════════════════════════════════════════════════"
