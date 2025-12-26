#!/bin/bash

echo "═══════════════════════════════════════════════════════════════════════"
echo "⚡ Performance Benchmark Suite"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""

echo "Test: Database Load Time"
echo "─────────────────────────────────────────────────────────────────────"
time python3 -c "from skill_registry import SkillRegistry; sr = SkillRegistry(); print(f'Loaded {len(sr.database[\"skills\"])} skills')"
echo ""

echo "Test: Simple Task Match (10 iterations)"
echo "─────────────────────────────────────────────────────────────────────"
time for i in {1..10}; do
  python3 task_matcher.py --task "test api" --top 3 > /dev/null 2>&1
done
echo ""

echo "Test: Complex Task Match (10 iterations)"
echo "─────────────────────────────────────────────────────────────────────"
time for i in {1..10}; do
  python3 task_matcher.py --task "scrape data, analyze trends, create visualizations" --top 5 > /dev/null 2>&1
done
echo ""

echo "Test: Database Search (10 iterations)"
echo "─────────────────────────────────────────────────────────────────────"
time for i in {1..10}; do
  python3 skill_registry.py --search "visualization" > /dev/null 2>&1
done
echo ""

echo "Test: Workflow Generation (10 iterations)"
echo "─────────────────────────────────────────────────────────────────────"
time for i in {1..10}; do
  python3 orchestrator.py --task "optimize database and create dashboard" > /dev/null 2>&1
done
echo ""

echo "═══════════════════════════════════════════════════════════════════════"
echo "✅ Performance Benchmarks Complete"
echo "═══════════════════════════════════════════════════════════════════════"
