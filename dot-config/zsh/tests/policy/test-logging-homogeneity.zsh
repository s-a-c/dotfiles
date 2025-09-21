#!/usr/bin/env zsh
# test-logging-homogeneity.zsh
#
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# PURPOSE:
#   Enforce logging namespace homogeneity (REFERENCE §5.4) ensuring only
#   the approved public logging functions are used:
#       zf::log  zf::warn  zf::err
#
#   Legacy / deprecated underscore-prefixed wrappers MUST NOT appear:
#       _zf_log  _zf_warn  _zf_err
#
# SCOPE:
#   Scans all *.zsh files under the redesign tree (and adjacent config scope),
#   excluding this test file itself. Produces a failing exit code (1) if any
#   disallowed identifiers are detected.
#
# SUCCESS CRITERIA:
#   - No matches for patterns: _zf_log|_zf_warn|_zf_err
#   - Test runtime negligible (<50ms typical)
#
# OVERRIDES:
#   Set ALLOW_LEGACY_LOG_WRAPPERS=1 to temporarily bypass (e.g. for bisect).
#
# OUTPUT:
#   On failure, emits a summary block enumerating each offending file:line + snippet.
#
# SECURITY / PRIVACY:
#   Pure static pattern scan; no user data exposure.
#
# EXIT CODES:
#   0 = homogeneous (pass)
#   1 = violation(s) found
#
# ------------------------------------------------------------------------------

emulate -L zsh
setopt errexit nounset pipefail

# Fast opt-out (used only for controlled transitional scenarios)
if [[ "${ALLOW_LEGACY_LOG_WRAPPERS:-0}" == "1" ]]; then
  print -r -- "[INFO] Homogeneity gate bypassed via ALLOW_LEGACY_LOG_WRAPPERS=1"
  exit 0
fi

# Determine repository root relative to this test file.
# Expected path: .../dot-config/zsh/tests/policy/test-logging-homogeneity.zsh
SCRIPT_PATH="${(%):-%N}"
SCRIPT_DIR="${SCRIPT_PATH:A:h}"
ZSH_CONFIG_ROOT="${SCRIPT_DIR:A:h:h:h}"   # ascend 3 levels to dot-config/zsh

if [[ ! -d "${ZSH_CONFIG_ROOT}" ]]; then
  print -r -- "[WARN] Could not resolve zsh config root: ${ZSH_CONFIG_ROOT}"
  # Fail safe (treat as configuration error)
  exit 1
fi

# Assemble file list (only .zsh). Exclude this test file explicitly.
autoload -Uz is-at-least 2>/dev/null || true

# Use 'find' to collect candidates. We deliberately avoid grep -r directly so we
# can control exclusion logic precisely.
typeset -a CANDIDATES
while IFS= read -r f; do
  [[ "${f}" == "${SCRIPT_PATH:A}" ]] && continue
  CANDIDATES+=("${f}")
done < <(find "${ZSH_CONFIG_ROOT}" -type f -name '*.zsh' 2>/dev/null | sort)

# If no candidates (unexpected), treat as failure to surface anomaly.
if (( ${#CANDIDATES[@]} == 0 )); then
  print -r -- "[FAIL] No .zsh files discovered under ${ZSH_CONFIG_ROOT}"
  exit 1
fi

# Patterns to forbid (whole tokens or substrings). We keep it simple because
# the deprecated functions had distinct names unlikely to appear legitimately.
FORBID_REGEX='(_zf_log|_zf_warn|_zf_err)'

typeset -a VIOLATIONS

for file in "${CANDIDATES[@]}"; do
  # Grep with -n for line numbers; suppress errors for unreadable files (should not happen)
  if grep -E -n -- "${FORBID_REGEX}" -- "${file}" >/dev/null 2>&1; then
    # Collect all matching lines for this file
    while IFS= read -r line; do
      VIOLATIONS+=("${file}:${line}")
    done < <(grep -E -n -- "${FORBID_REGEX}" -- "${file}" 2>/dev/null || true)
  fi
done

if (( ${#VIOLATIONS[@]} > 0 )); then
  print -r -- "============================================================"
  print -r -- "[FAIL] Logging homogeneity violations detected (${#VIOLATIONS[@]}):"
  print -r -- "Forbidden identifiers: _zf_log _zf_warn _zf_err"
  print -r -- "REFERENCE §5.4 mandates only zf::log / zf::warn / zf::err."
  print -r -- "------------------------------------------------------------"
  for v in "${VIOLATIONS[@]}"; do
    # Split out to show context
    file="${v%%:*}"
    rest="${v#*:}"
    lnum="${rest%%:*}"
    content="${rest#*:}"
    print -r -- "${file}:${lnum}: ${content}"
  done
  print -r -- "============================================================"
  exit 1
fi

print -r -- "[PASS] Logging homogeneity enforced: no legacy underscore wrappers found."
exit 0
