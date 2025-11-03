#!/usr/bin/env zsh
# ==============================================================================
# Plugin Loading Verification Test Script
# ==============================================================================
# Purpose: Verify zgenom and all plugins load correctly
# Part of: Phase 1, Task 1.2.2 - Configuration Stability Testing
# Created: 2025-10-07
# ==============================================================================

emulate -L zsh
setopt ERR_RETURN NO_UNSET PIPE_FAIL

# Color output helpers
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# Test configuration
SCRIPT_DIR="${0:A:h}"
ZDOTDIR="${ZDOTDIR:-${HOME}/.config/zsh}"
TEST_REPORT_DIR="${ZDOTDIR}/tests/stability/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${TEST_REPORT_DIR}/plugin-loading-${TIMESTAMP}.md"
TEMP_OUTPUT="/tmp/zsh-plugin-test-${TIMESTAMP}.log"

# Ensure report directory exists
mkdir -p "${TEST_REPORT_DIR}"

# Test results
typeset -gi TEST_PASSED=0
typeset -gi TEST_FAILED=0
typeset -ga ISSUES=()

# ==============================================================================
# Functions
# ==============================================================================

print_header() {
  print "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print "${BLUE}  ZSH Plugin Loading Verification Test${NC}"
  print "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print ""
}

print_section() {
  print ""
  print "${YELLOW}▶ $1${NC}"
  print "${YELLOW}$(printf '─%.0s' {1..70})${NC}"
}

test_zgenom_available() {
  print_section "Testing zgenom Availability"
  
  if zsh -i -c 'command -v zgenom >/dev/null 2>&1' 2>/dev/null; then
    print "  ${GREEN}✓${NC} zgenom command is available"
    TEST_PASSED=$((TEST_PASSED + 1))
    return 0
  else
    print "  ${RED}✗${NC} zgenom command not found"
    ISSUES+=("zgenom command not available in interactive shell")
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
  fi
}

test_zgenom_init() {
  print_section "Testing zgenom Initialization"
  
  local init_file="${ZGEN_DIR:-${ZDOTDIR}/.zgenom}/init.zsh"
  
  if [[ -f "$init_file" ]]; then
    print "  ${GREEN}✓${NC} zgenom init file exists: ${init_file}"
    TEST_PASSED=$((TEST_PASSED + 1))
  else
    print "  ${YELLOW}⚠${NC} zgenom init file not found: ${init_file}"
    print "    This is normal if zgenom hasn't been initialized yet"
  fi
}

test_plugin_count() {
  print_section "Testing Plugin Count"
  
  local plugin_count=$(zsh -i -c 'zgenom list 2>/dev/null | wc -l' 2>/dev/null | tr -d ' ')
  
  if [[ -n "$plugin_count" && "$plugin_count" -gt 0 ]]; then
    print "  ${GREEN}✓${NC} Loaded plugins: ${plugin_count}"
    TEST_PASSED=$((TEST_PASSED + 1))
    
    # List plugins
    print ""
    print "  Loaded plugins:"
    zsh -i -c 'zgenom list 2>/dev/null' 2>/dev/null | while read -r plugin; do
      print "    - ${plugin}"
    done
  else
    print "  ${RED}✗${NC} No plugins loaded or zgenom list failed"
    ISSUES+=("No plugins loaded or zgenom list command failed")
    TEST_FAILED=$((TEST_FAILED + 1))
  fi
}

test_shell_startup() {
  print_section "Testing Shell Startup"
  
  print "  Testing interactive shell startup..."
  
  if zsh -i -c 'exit 0' >"$TEMP_OUTPUT" 2>&1; then
    print "  ${GREEN}✓${NC} Shell starts without errors"
    TEST_PASSED=$((TEST_PASSED + 1))
    
    # Check for warnings in output
    if grep -qi "error\|warning\|failed" "$TEMP_OUTPUT" 2>/dev/null; then
      print "  ${YELLOW}⚠${NC} Warnings/errors detected in startup output:"
      grep -i "error\|warning\|failed" "$TEMP_OUTPUT" | head -5 | while read -r line; do
        print "    ${line}"
      done
    fi
  else
    print "  ${RED}✗${NC} Shell startup failed"
    ISSUES+=("Interactive shell startup failed")
    TEST_FAILED=$((TEST_FAILED + 1))
    
    if [[ -f "$TEMP_OUTPUT" ]]; then
      print "  Error output:"
      head -10 "$TEMP_OUTPUT" | while read -r line; do
        print "    ${line}"
      done
    fi
  fi
}

test_plugin_functionality() {
  print_section "Testing Plugin Functionality"
  
  # Test common plugin commands/features
  local -a tests=(
    "fzf:command -v fzf"
    "git-aliases:alias | grep -q git"
    "completions:compinit"
  )
  
  for test_spec in "${tests[@]}"; do
    local name="${test_spec%%:*}"
    local cmd="${test_spec#*:}"
    
    if zsh -i -c "$cmd >/dev/null 2>&1" 2>/dev/null; then
      print "  ${GREEN}✓${NC} ${name} functionality available"
      TEST_PASSED=$((TEST_PASSED + 1))
    else
      print "  ${YELLOW}⚠${NC} ${name} functionality not available (may not be installed)"
    fi
  done
}

test_plugin_errors() {
  print_section "Checking for Plugin Load Errors"
  
  # Start a shell and capture any error output
  local error_output=$(zsh -i -c 'exit 0' 2>&1 | grep -i "error\|failed\|cannot" || true)
  
  if [[ -z "$error_output" ]]; then
    print "  ${GREEN}✓${NC} No plugin load errors detected"
    TEST_PASSED=$((TEST_PASSED + 1))
  else
    print "  ${RED}✗${NC} Plugin load errors detected:"
    echo "$error_output" | head -10 | while read -r line; do
      print "    ${line}"
      ISSUES+=("Plugin error: ${line}")
    done
    TEST_FAILED=$((TEST_FAILED + 1))
  fi
}

generate_report() {
  print_section "Generating Report"
  
  local total_tests=$((TEST_PASSED + TEST_FAILED))
  local success_rate=$(( total_tests > 0 ? (TEST_PASSED * 100) / total_tests : 0 ))
  
  cat > "$REPORT_FILE" <<EOF
# ZSH Plugin Loading Verification Report

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Test Script**: tests/stability/test-plugin-loading.zsh
**ZDOTDIR**: ${ZDOTDIR}

## Summary

- **Total Tests**: ${total_tests}
- **Passed**: ${TEST_PASSED} ✅
- **Failed**: ${TEST_FAILED} ❌
- **Success Rate**: ${success_rate}%

## Test Results

### zgenom Availability

EOF

  if zsh -i -c 'command -v zgenom >/dev/null 2>&1' 2>/dev/null; then
    echo "✅ zgenom command is available" >> "$REPORT_FILE"
  else
    echo "❌ zgenom command not found" >> "$REPORT_FILE"
  fi

  cat >> "$REPORT_FILE" <<EOF

### Plugin Loading

EOF

  local plugin_count=$(zsh -i -c 'zgenom list 2>/dev/null | wc -l' 2>/dev/null | tr -d ' ')
  echo "**Loaded Plugins**: ${plugin_count:-0}" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  
  if [[ -n "$plugin_count" && "$plugin_count" -gt 0 ]]; then
    echo "Plugins loaded:" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    zsh -i -c 'zgenom list 2>/dev/null' 2>/dev/null >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
  fi

  cat >> "$REPORT_FILE" <<EOF

### Shell Startup

EOF

  if zsh -i -c 'exit 0' >/dev/null 2>&1; then
    echo "✅ Interactive shell starts successfully" >> "$REPORT_FILE"
  else
    echo "❌ Interactive shell startup failed" >> "$REPORT_FILE"
  fi

  if [[ ${#ISSUES[@]} -gt 0 ]]; then
    cat >> "$REPORT_FILE" <<EOF

## Issues Detected

The following issues were found during testing:

EOF
    for issue in "${ISSUES[@]}"; do
      echo "- ${issue}" >> "$REPORT_FILE"
    done
  fi

  cat >> "$REPORT_FILE" <<EOF

## Conclusion

EOF

  if [[ ${TEST_FAILED} -eq 0 ]]; then
    cat >> "$REPORT_FILE" <<EOF
✅ **All plugin loading tests passed.**

The ZSH configuration successfully loads zgenom and all configured plugins.
EOF
  else
    cat >> "$REPORT_FILE" <<EOF
❌ **${TEST_FAILED} test(s) failed.**

Please review the issues listed above and ensure all plugins are properly configured.
EOF
  fi

  cat >> "$REPORT_FILE" <<EOF

---

*Generated by: tests/stability/test-plugin-loading.zsh*
*Part of: Phase 1, Task 1.2.2 - Configuration Stability Testing*
EOF

  print "  ${GREEN}✓${NC} Report saved to: ${REPORT_FILE}"
}

print_summary() {
  local total_tests=$((TEST_PASSED + TEST_FAILED))
  
  print ""
  print "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print "${BLUE}  Test Summary${NC}"
  print "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print ""
  print "  Total Tests:  ${total_tests}"
  print "  ${GREEN}Passed:       ${TEST_PASSED}${NC}"
  print "  ${RED}Failed:       ${TEST_FAILED}${NC}"
  print "  Success Rate: $(( total_tests > 0 ? (TEST_PASSED * 100) / total_tests : 0 ))%"
  print ""
  
  if [[ ${TEST_FAILED} -eq 0 ]]; then
    print "  ${GREEN}✓ All plugin loading tests passed!${NC}"
  else
    print "  ${RED}✗ Some tests failed${NC}"
  fi
  print ""
  print "  Report: ${REPORT_FILE}"
  print ""
}

cleanup() {
  [[ -f "$TEMP_OUTPUT" ]] && rm -f "$TEMP_OUTPUT"
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
  trap cleanup EXIT
  
  print_header
  
  test_zgenom_available
  test_zgenom_init
  test_plugin_count
  test_shell_startup
  test_plugin_functionality
  test_plugin_errors
  
  generate_report
  print_summary
  
  if [[ ${TEST_FAILED} -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

main "$@"

