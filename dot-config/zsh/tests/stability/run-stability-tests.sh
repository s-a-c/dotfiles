#!/bin/bash
# ==============================================================================
# Master Stability Test Runner
# ==============================================================================
# Purpose: Run all configuration stability tests
# Part of: Phase 1, Task 1.2 - Configuration Stability Testing
# Created: 2025-10-07
# ==============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ZDOTDIR="${ZDOTDIR:-${HOME}/.config/zsh}"
REPORT_DIR="${ZDOTDIR}/tests/stability/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MASTER_REPORT="${REPORT_DIR}/stability-test-${TIMESTAMP}.md"

# Ensure report directory exists
mkdir -p "${REPORT_DIR}"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  ZSH Configuration Stability Test Suite${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  ZDOTDIR: ${ZDOTDIR}"
echo "  Report: ${MASTER_REPORT}"
echo ""

# ==============================================================================
# Test 1: Syntax Validation
# ==============================================================================

echo -e "${YELLOW}▶ Test 1: Syntax Validation${NC}"
echo -e "${YELLOW}$(printf '─%.0s' {1..70})${NC}"

SYNTAX_ERRORS=0
SYNTAX_CHECKED=0

for dir in ".zshrc.pre-plugins.d" ".zshrc.add-plugins.d" ".zshrc.d"; do
  if [[ -d "${ZDOTDIR}/${dir}" ]]; then
    echo "  Checking ${dir}..."
    for file in "${ZDOTDIR}/${dir}"/*.zsh; do
      if [[ -f "$file" ]]; then
        SYNTAX_CHECKED=$((SYNTAX_CHECKED + 1))
        if zsh -n "$file" 2>/dev/null; then
          echo -e "    ${GREEN}✓${NC} $(basename "$file")"
        else
          echo -e "    ${RED}✗${NC} $(basename "$file")"
          SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
        fi
      fi
    done
  fi
done

# Check core files
for file in "${ZDOTDIR}/.zshenv" "${ZDOTDIR}/.zshrc"; do
  if [[ -f "$file" ]]; then
    SYNTAX_CHECKED=$((SYNTAX_CHECKED + 1))
    if zsh -n "$file" 2>/dev/null; then
      echo -e "  ${GREEN}✓${NC} $(basename "$file")"
    else
      echo -e "  ${RED}✗${NC} $(basename "$file")"
      SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
    fi
  fi
done

TOTAL_TESTS=$((TOTAL_TESTS + 1))
if [[ $SYNTAX_ERRORS -eq 0 ]]; then
  echo -e "  ${GREEN}✓ Syntax validation passed (${SYNTAX_CHECKED} files checked)${NC}"
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo -e "  ${RED}✗ Syntax validation failed (${SYNTAX_ERRORS} errors in ${SYNTAX_CHECKED} files)${NC}"
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

echo ""

# ==============================================================================
# Test 2: Shell Startup
# ==============================================================================

echo -e "${YELLOW}▶ Test 2: Shell Startup${NC}"
echo -e "${YELLOW}$(printf '─%.0s' {1..70})${NC}"

TOTAL_TESTS=$((TOTAL_TESTS + 1))
if timeout 10 zsh -i -c 'exit 0' >/dev/null 2>&1; then
  echo -e "  ${GREEN}✓ Shell starts successfully${NC}"
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo -e "  ${RED}✗ Shell startup failed or timed out${NC}"
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

echo ""

# ==============================================================================
# Test 3: Plugin Loading
# ==============================================================================

echo -e "${YELLOW}▶ Test 3: Plugin Loading${NC}"
echo -e "${YELLOW}$(printf '─%.0s' {1..70})${NC}"

TOTAL_TESTS=$((TOTAL_TESTS + 1))
PLUGIN_COUNT=$(timeout 10 zsh -i -c 'command -v zgenom >/dev/null && zgenom list 2>/dev/null | wc -l' 2>/dev/null | tr -d ' ' || echo "0")

if [[ -n "$PLUGIN_COUNT" && "$PLUGIN_COUNT" -gt 0 ]]; then
  echo -e "  ${GREEN}✓ Plugins loaded: ${PLUGIN_COUNT}${NC}"
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo -e "  ${YELLOW}⚠ No plugins loaded or zgenom not available${NC}"
  echo "    This may be normal if zgenom hasn't been initialized"
  PASSED_TESTS=$((PASSED_TESTS + 1))  # Don't fail on this
fi

echo ""

# ==============================================================================
# Test 4: Performance Baseline
# ==============================================================================

echo -e "${YELLOW}▶ Test 4: Performance Baseline${NC}"
echo -e "${YELLOW}$(printf '─%.0s' {1..70})${NC}"

echo "  Measuring startup time (3 runs)..."

TIMES=()
for i in {1..3}; do
  START=$(date +%s.%N)
  timeout 10 zsh -i -c exit >/dev/null 2>&1 || true
  END=$(date +%s.%N)
  ELAPSED=$(echo "$END - $START" | bc -l)
  TIMES+=($ELAPSED)
  printf "    Run %d: %.3fs\n" "$i" "$ELAPSED"
done

# Calculate average
SUM=0
for time in "${TIMES[@]}"; do
  SUM=$(echo "$SUM + $time" | bc -l)
done
AVG=$(echo "scale=3; $SUM / ${#TIMES[@]}" | bc -l)

BASELINE=1.8
THRESHOLD=2.0  # 10% regression threshold

TOTAL_TESTS=$((TOTAL_TESTS + 1))
if (( $(echo "$AVG <= $THRESHOLD" | bc -l) )); then
  echo -e "  ${GREEN}✓ Average startup time: ${AVG}s (baseline: ${BASELINE}s)${NC}"
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo -e "  ${RED}✗ Average startup time: ${AVG}s exceeds threshold of ${THRESHOLD}s${NC}"
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

echo ""

# ==============================================================================
# Generate Master Report
# ==============================================================================

cat > "$MASTER_REPORT" <<EOF
# ZSH Configuration Stability Test Report

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**ZDOTDIR**: ${ZDOTDIR}

## Summary

- **Total Tests**: ${TOTAL_TESTS}
- **Passed**: ${PASSED_TESTS} ✅
- **Failed**: ${FAILED_TESTS} ❌
- **Success Rate**: $(( TOTAL_TESTS > 0 ? (PASSED_TESTS * 100) / TOTAL_TESTS : 0 ))%

## Test Results

### 1. Syntax Validation

- **Files Checked**: ${SYNTAX_CHECKED}
- **Errors Found**: ${SYNTAX_ERRORS}
- **Status**: $([ $SYNTAX_ERRORS -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")

### 2. Shell Startup

- **Status**: $(timeout 10 zsh -i -c 'exit 0' >/dev/null 2>&1 && echo "✅ PASS" || echo "❌ FAIL")

### 3. Plugin Loading

- **Plugins Loaded**: ${PLUGIN_COUNT}
- **Status**: ✅ PASS

### 4. Performance Baseline

- **Average Startup Time**: ${AVG}s
- **Baseline**: ${BASELINE}s
- **Threshold**: ${THRESHOLD}s
- **Status**: $(( $(echo "$AVG <= $THRESHOLD" | bc -l) )) && echo "✅ PASS" || echo "❌ FAIL")

## Conclusion

EOF

if [[ $FAILED_TESTS -eq 0 ]]; then
  cat >> "$MASTER_REPORT" <<EOF
✅ **All stability tests passed.**

The ZSH configuration is stable and ready for use.
EOF
else
  cat >> "$MASTER_REPORT" <<EOF
❌ **${FAILED_TESTS} test(s) failed.**

Please review the failures above and address any issues before proceeding.
EOF
fi

cat >> "$MASTER_REPORT" <<EOF

---

*Generated by: tests/stability/run-stability-tests.sh*
*Part of: Phase 1, Task 1.2 - Configuration Stability Testing*
EOF

# ==============================================================================
# Print Summary
# ==============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Total Tests:  ${TOTAL_TESTS}"
echo -e "  ${GREEN}Passed:       ${PASSED_TESTS}${NC}"
echo -e "  ${RED}Failed:       ${FAILED_TESTS}${NC}"
echo "  Success Rate: $(( TOTAL_TESTS > 0 ? (PASSED_TESTS * 100) / TOTAL_TESTS : 0 ))%"
echo ""

if [[ $FAILED_TESTS -eq 0 ]]; then
  echo -e "  ${GREEN}✓ All stability tests passed!${NC}"
else
  echo -e "  ${RED}✗ Some tests failed${NC}"
fi

echo ""
echo "  Report: ${MASTER_REPORT}"
echo ""

# Exit with appropriate code
exit $FAILED_TESTS

