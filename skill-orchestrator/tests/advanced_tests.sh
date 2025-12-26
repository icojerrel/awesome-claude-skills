#!/bin/bash

echo "═══════════════════════════════════════════════════════════════════════"
echo "🔬 Advanced Test Scenarios"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""

# Test 11: Very specific technical task
echo "Test 11: Very Specific Technical Task"
echo "─────────────────────────────────────────────────────────────────────"
python3 task_matcher.py --task "GraphQL mutation testing with schema validation" --top 3
echo ""

# Test 12: Vague/ambiguous task
echo "Test 12: Vague/Ambiguous Task"
echo "─────────────────────────────────────────────────────────────────────"
python3 task_matcher.py --task "improve application" --top 3
echo ""

# Test 13: Task with many capabilities
echo "Test 13: Multi-Capability Complex Task"
echo "─────────────────────────────────────────────────────────────────────"
python3 task_matcher.py --task "scrape e-commerce site, extract pricing, store in database, optimize queries, analyze trends, create dashboard with visualizations, send report" --top 5 --explain
echo ""

# Test 14: Domain-specific task
echo "Test 14: Domain-Specific Task (Forensics)"
echo "─────────────────────────────────────────────────────────────────────"
python3 task_matcher.py --task "analyze disk image for deleted files and suspicious activity" --top 3
echo ""

# Test 15: Creative/content task
echo "Test 15: Creative/Content Task"
echo "─────────────────────────────────────────────────────────────────────"
python3 task_matcher.py --task "write blog post about product launch" --top 3
echo ""

echo "═══════════════════════════════════════════════════════════════════════"
echo "✅ Advanced Tests Complete"
echo "═══════════════════════════════════════════════════════════════════════"
