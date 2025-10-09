#!/usr/bin/env zsh
# ==============================================================================
# Syntax Validation Test Script
# ==============================================================================
# Purpose: Validate ZSH syntax for all configuration files
# Part of: Phase 1, Task 1.2.1 - Configuration Stability Testing
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
  NC='\033[0m' # No Color
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# Test configuration
SCRIPT_DIR="${0:A:h}"
ZDOTDIR="${ZDOTDIR:-${HOME}/.config/zsh}"
TEST_REPORT_DIR="${ZDOTDIR}/tests/stability/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${TEST_REPORT_DIR}/syntax-validation-${TIMESTAMP}.md"

# Ensure report directory exists
mkdir -p "${TEST_REPORT_DIR}"

# Test counters
typeset -gi TOTAL_FILES=0
typeset -gi PASSED_FILES=0
typeset -gi FAILED_FILES=0
typeset -ga FAILED_LIST=()

# ==============================================================================
# Functions
# ==============================================================================

print_header() {
  print "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print "${BLUE}  ZSH Configuration Syntax Validation Test${NC}"
  print "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print ""
}

print_section() {
  print ""
  print "${YELLOW}▶ $1${NC}"
  print "${YELLOW}$(printf '─%.0s' {1..70})${NC}"
}

test_file_syntax() {
  local file="$1"
  local relative_path="${file#${ZDOTDIR}/}"
  
  TOTAL_FILES=$((TOTAL_FILES + 1))
  
  # Run syntax check
  if zsh -n "$file" 2>/dev/null; then
    print "  ${GREEN}✓${NC} ${relative_path}"
    PASSED_FILES=$((PASSED_FILES + 1))
    return 0
  else
    print "  ${RED}✗${NC} ${relative_path}"
    FAILED_FILES=$((FAILED_FILES + 1))
    FAILED_LIST+=("$relative_path")
    
    # Capture error details
    local error_output=$(zsh -n "$file" 2>&1)
    print "    ${RED}Error:${NC} ${error_output}"
    return 1
  fi
}

test_directory() {
  local dir="$1"
  local label="$2"
  
  print_section "$label"
  
  if [[ ! -d "$dir" ]]; then
    print "  ${YELLOW}⚠${NC} Directory not found: $dir"
    return 0
  fi
  
  local files=("$dir"/*.zsh(N))
  
  if [[ ${#files[@]} -eq 0 ]]; then
    print "  ${YELLOW}⚠${NC} No .zsh files found in $dir"
    return 0
  fi
  
  for file in "${files[@]}"; do
    test_file_syntax "$file"
  done
}

generate_report() {
  print_section "Generating Report"
  
  cat > "$REPORT_FILE" <<EOF
# ZSH Configuration Syntax Validation Report

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Test Script**: tests/stability/test-syntax-validation.zsh
**ZDOTDIR**: ${ZDOTDIR}

## Summary

- **Total Files Tested**: ${TOTAL_FILES}
- **Passed**: ${PASSED_FILES} (${GREEN}✓${NC})
- **Failed**: ${FAILED_FILES} (${RED}✗${NC})
- **Success Rate**: $(( TOTAL_FILES > 0 ? (PASSED_FILES * 100) / TOTAL_FILES : 0 ))%

## Test Results

### Pre-Plugin Configuration Files

EOF

  # Add detailed results for each directory
  for file in "${ZDOTDIR}/.zshrc.pre-plugins.d"/*.zsh(N); do
    local relative="${file#${ZDOTDIR}/}"
    if zsh -n "$file" 2>/dev/null; then
      echo "- ✅ \`${relative}\`" >> "$REPORT_FILE"
    else
      echo "- ❌ \`${relative}\`" >> "$REPORT_FILE"
      echo "  \`\`\`" >> "$REPORT_FILE"
      zsh -n "$file" 2>&1 | sed 's/^/  /' >> "$REPORT_FILE"
      echo "  \`\`\`" >> "$REPORT_FILE"
    fi
  done

  cat >> "$REPORT_FILE" <<EOF

### Plugin Definition Files

EOF

  for file in "${ZDOTDIR}/.zshrc.add-plugins.d"/*.zsh(N); do
    local relative="${file#${ZDOTDIR}/}"
    if zsh -n "$file" 2>/dev/null; then
      echo "- ✅ \`${relative}\`" >> "$REPORT_FILE"
    else
      echo "- ❌ \`${relative}\`" >> "$REPORT_FILE"
      echo "  \`\`\`" >> "$REPORT_FILE"
      zsh -n "$file" 2>&1 | sed 's/^/  /' >> "$REPORT_FILE"
      echo "  \`\`\`" >> "$REPORT_FILE"
    fi
  done

  cat >> "$REPORT_FILE" <<EOF

### Post-Plugin Configuration Files

EOF

  for file in "${ZDOTDIR}/.zshrc.d"/*.zsh(N); do
    local relative="${file#${ZDOTDIR}/}"
    if zsh -n "$file" 2>/dev/null; then
      echo "- ✅ \`${relative}\`" >> "$REPORT_FILE"
    else
      echo "- ❌ \`${relative}\`" >> "$REPORT_FILE"
      echo "  \`\`\`" >> "$REPORT_FILE"
      zsh -n "$file" 2>&1 | sed 's/^/  /' >> "$REPORT_FILE"
      echo "  \`\`\`" >> "$REPORT_FILE"
    fi
  done

  if [[ ${FAILED_FILES} -gt 0 ]]; then
    cat >> "$REPORT_FILE" <<EOF

## Failed Files

The following files failed syntax validation:

EOF
    for failed in "${FAILED_LIST[@]}"; do
      echo "- \`${failed}\`" >> "$REPORT_FILE"
    done
  fi

  cat >> "$REPORT_FILE" <<EOF

## Conclusion

EOF

  if [[ ${FAILED_FILES} -eq 0 ]]; then
    cat >> "$REPORT_FILE" <<EOF
✅ **All configuration files passed syntax validation.**

The ZSH configuration is syntactically correct and ready for runtime testing.
EOF
  else
    cat >> "$REPORT_FILE" <<EOF
❌ **${FAILED_FILES} file(s) failed syntax validation.**

Please review and fix the syntax errors listed above before proceeding with runtime testing.
EOF
  fi

  cat >> "$REPORT_FILE" <<EOF

---

*Generated by: tests/stability/test-syntax-validation.zsh*
*Part of: Phase 1, Task 1.2.1 - Configuration Stability Testing*
EOF

  print "  ${GREEN}✓${NC} Report saved to: ${REPORT_FILE}"
}

print_summary() {
  print ""
  print "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print "${BLUE}  Test Summary${NC}"
  print "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print ""
  print "  Total Files:  ${TOTAL_FILES}"
  print "  ${GREEN}Passed:       ${PASSED_FILES}${NC}"
  print "  ${RED}Failed:       ${FAILED_FILES}${NC}"
  print "  Success Rate: $(( TOTAL_FILES > 0 ? (PASSED_FILES * 100) / TOTAL_FILES : 0 ))%"
  print ""
  
  if [[ ${FAILED_FILES} -eq 0 ]]; then
    print "  ${GREEN}✓ All syntax checks passed!${NC}"
  else
    print "  ${RED}✗ Some files have syntax errors${NC}"
    print ""
    print "  Failed files:"
    for failed in "${FAILED_LIST[@]}"; do
      print "    - ${failed}"
    done
  fi
  print ""
  print "  Report: ${REPORT_FILE}"
  print ""
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
  print_header
  
  # Test each configuration directory
  test_directory "${ZDOTDIR}/.zshrc.pre-plugins.d" "Pre-Plugin Configuration (.zshrc.pre-plugins.d/)"
  test_directory "${ZDOTDIR}/.zshrc.add-plugins.d" "Plugin Definitions (.zshrc.add-plugins.d/)"
  test_directory "${ZDOTDIR}/.zshrc.d" "Post-Plugin Configuration (.zshrc.d/)"
  
  # Also test core files
  print_section "Core Configuration Files"
  [[ -f "${ZDOTDIR}/.zshenv" ]] && test_file_syntax "${ZDOTDIR}/.zshenv"
  [[ -f "${ZDOTDIR}/.zshrc" ]] && test_file_syntax "${ZDOTDIR}/.zshrc"
  
  # Generate report
  generate_report
  
  # Print summary
  print_summary
  
  # Exit with appropriate code
  if [[ ${FAILED_FILES} -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# Run main function
main "$@"

