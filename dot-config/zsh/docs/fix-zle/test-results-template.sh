#!/bin/bash
# Results Template - Creates template files for recording test results
# Execute: bash docs/fix-zle/test-results-template.sh

echo "=== CREATING RESULT TEMPLATES ==="
echo "Creating template files for recording test results..."
echo ""

mkdir -p docs/fix-zle/results

# Baseline results template
cat > docs/fix-zle/results/baseline-results.txt << 'EOF'
=== BASELINE TEST RESULTS ===
Date: [FILL IN]
Test: Complete minimal configuration (.zshenv.minimal.complete + .zshrc.minimal)

RESULT: [SUCCESS/HANGS/ERROR/ZLE_BROKEN]

Details:
- ZLE widgets available: [NUMBER]
- ZLE widget creation: [SUCCESS/FAILED]
- grep command: [SUCCESS/FAILED]
- ZDOTDIR value: [VALUE]
- Any error messages: [LIST OR "NONE"]

Notes:
[ANY ADDITIONAL OBSERVATIONS]
EOF

# Full initial results template
cat > docs/fix-zle/results/full-initial-results.txt << 'EOF'
=== FULL INITIAL TEST RESULTS ===
Date: [FILL IN]
Test: Complete .zshenv.full.bisect

RESULT: [SUCCESS/HANGS/ERROR/ZLE_BROKEN]

Details:
- Did zsh start? [YES/NO/TIMEOUT]
- ZLE widgets available: [NUMBER OR "N/A"]
- ZLE widget creation: [SUCCESS/FAILED/N/A]
- grep command: [SUCCESS/FAILED/N/A]
- ZDOTDIR value: [VALUE OR "N/A"]
- Any error messages: [LIST OR "NONE"]

Notes:
[ANY ADDITIONAL OBSERVATIONS]
EOF

# Bisection point templates
for i in {1..8}; do
    cat > "docs/fix-zle/results/bisect-point-${i}-results.txt" << EOF
=== BISECT POINT ${i} TEST RESULTS ===
Date: [FILL IN]
Test: Bisection point ${i}

RESULT: [SUCCESS/HANGS/ERROR/ZLE_BROKEN]

Details:
- Did zsh start? [YES/NO/TIMEOUT]
- ZLE widgets available: [NUMBER OR "N/A"]
- ZLE widget creation: [SUCCESS/FAILED/N/A]
- grep command: [SUCCESS/FAILED/N/A]
- Expected variables set correctly? [YES/NO/PARTIAL]
- Any error messages: [LIST OR "NONE"]

Notes:
[ANY ADDITIONAL OBSERVATIONS]
EOF
done

echo "✅ Created result template files:"
ls -la docs/fix-zle/results/
echo ""
echo "=== TEMPLATES CREATED ==="
echo "Fill in the appropriate template file after each test"
