#!/bin/bash
# Comprehensive Test Suite for Skill Orchestrator

echo "═══════════════════════════════════════════════════════════════════════"
echo "🧪 Skill Orchestrator - Comprehensive Test Suite"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""

# Test 1: Simple task matching
echo "Test 1: Simple Task Matching"
echo "─────────────────────────────────────────────────────────────────────"
python3 task_matcher.py --task "scrape website" --top 3
echo ""

# Test 2: Medium complexity task
echo "Test 2: Medium Complexity Task"
echo "─────────────────────────────────────────────────────────────────────"
python3 task_matcher.py --task "parse receipts and track expenses" --top 3
echo ""

# Test 3: Complex task with multiple capabilities
echo "Test 3: Complex Multi-Capability Task"
echo "─────────────────────────────────────────────────────────────────────"
python3 task_matcher.py --task "optimize database queries and visualize performance metrics" --top 3 --explain
echo ""

# Test 4: Security-focused task
echo "Test 4: Security Analysis Task"
echo "─────────────────────────────────────────────────────────────────────"
python3 task_matcher.py --task "analyze network traffic for security threats" --top 3
echo ""

# Test 5: Business task
echo "Test 5: Business Process Task"
echo "─────────────────────────────────────────────────────────────────────"
python3 task_matcher.py --task "generate invoice and track payments" --top 3
echo ""

echo "═══════════════════════════════════════════════════════════════════════"
echo "✅ Test Suite Complete"
echo "═══════════════════════════════════════════════════════════════════════"
