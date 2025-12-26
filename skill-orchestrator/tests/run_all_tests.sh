#!/bin/bash
# Master Test Suite - Runs all Skill Orchestrator tests

cd "$(dirname "$0")/../scripts"

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║         Skill Orchestrator - Complete Test Suite                     ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

# Run main test suite
echo "Running: test_suite.sh"
../tests/test_suite.sh
echo ""

# Run advanced tests
echo "Running: advanced_tests.sh"
../tests/advanced_tests.sh
echo ""

# Run performance benchmarks
echo "Running: performance_benchmark.sh"
../tests/performance_benchmark.sh
echo ""

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                    All Tests Complete                                 ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "📄 Full test report: ../../ORCHESTRATOR_TEST_REPORT.md"
