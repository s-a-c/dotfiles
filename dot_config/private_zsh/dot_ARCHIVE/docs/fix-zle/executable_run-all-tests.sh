#!/bin/bash
# Master Test Runner - Runs all tests in sequence with prompts
# Execute: bash docs/fix-zle/run-all-tests.sh

echo "=== ZLE FIX - MASTER TEST RUNNER ==="
echo "This will run all bisection tests in sequence"
echo "You'll be prompted before each test"
echo ""

# Ensure we're in the right directory
if [[ ! -f ".zshenv.full.backup" ]]; then
    echo "❌ Error: Must run from /Users/s-a-c/.config/zsh"
    echo "Current directory: $(pwd)"
    exit 1
fi

echo "✅ Running from correct directory: $(pwd)"
echo ""

# Step 1: Setup
echo "=== STEP 1: SETUP ==="
read -p "Press Enter to run setup..."
bash docs/fix-zle/test-setup.sh
bash docs/fix-zle/test-results-template.sh
echo ""

# Step 2: Baseline
echo "=== STEP 2: BASELINE TEST ==="
echo "This tests the minimal .zshenv (should work perfectly)"
read -p "Press Enter to run baseline test..."
bash docs/fix-zle/test-baseline.sh
echo ""
read -p "Did the baseline test work? (y/n): " baseline_result
if [[ "$baseline_result" != "y" ]]; then
    echo "❌ Baseline test failed - something is fundamentally wrong"
    echo "Check your environment before proceeding"
    exit 1
fi

# Step 3: Full initial test
echo "=== STEP 3: FULL INITIAL TEST ==="
echo "This tests the complete .zshenv.full.backup (may hang)"
read -p "Press Enter to run full initial test..."
bash docs/fix-zle/test-full-initial.sh
echo ""
read -p "Did the full test work perfectly? (y/n): " full_result
if [[ "$full_result" == "y" ]]; then
    echo "✅ Full .zshenv works perfectly!"
    echo "The issue may be elsewhere or already resolved"
    exit 0
fi

# Step 4: Bisection tests
echo "=== STEP 4: BISECTION TESTS ==="
echo "Running bisection tests to find the problematic section..."
echo ""

for point in 1 2 3; do
    echo "=== BISECTION POINT $point ==="
    read -p "Press Enter to run bisection point $point..."
    bash "docs/fix-zle/test-bisect-point-$point.sh"
    echo ""
    read -p "Did bisection point $point work? (y/n): " point_result
    if [[ "$point_result" != "y" ]]; then
        echo "❌ Bisection point $point failed!"
        if [[ $point == 1 ]]; then
            echo "Problem is in the first 50 lines (emergency setup)"
        elif [[ $point == 2 ]]; then
            echo "Problem is between lines 50-130 (XDG/ZDOTDIR setup)"
        elif [[ $point == 3 ]]; then
            echo "Problem is between lines 130-260 (debug system)"
        fi
        echo ""
        echo "=== INVESTIGATION COMPLETE ==="
        echo "Check the results files in docs/fix-zle/results/"
        echo "Focus investigation on the identified problematic section"
        exit 0
    fi
done

echo "=== ALL BISECTION POINTS PASSED ==="
echo "The problem is after line 260. You may need to create additional bisection points."
echo "Check docs/fix-zle/results/ for all test results"
