#!/usr/bin/env zsh
# test-git-hooks.zsh
#
# Integration test: verify critical Git hook infrastructure is present and properly documented.
#
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
# Sensitive action domain: repository security / contribution workflow integrity
# Policy references:
#   - [${HOME}/dotfiles/dot-config/ai/guidelines/100-security-standards.md](${HOME}/dotfiles/dot-config/ai/guidelines/100-security-standards.md)
#   - [${HOME}/dotfiles/dot-config/ai/guidelines/040-development-standards.md](${HOME}/dotfiles/dot-config/ai/guidelines/040-development-standards.md)
#
# Purpose:
#   Ensure required local enforcement points (Git hooks) exist and contain expected usage & safety guidance.
#
# Required hooks:
#   1. .githooks/pre-commit
#   2. .githooks/pre-commit.d/secret-scan
#
# Optional (warn-only):
#   3. .githooks/pre-push  (if present, ensure it references protections like ALLOW_MAIN_PUSH or HEAD:main)
#
# Validations performed:
#   - Presence of required files.
#   - Executable bit on required hook scripts.
#   - Shebang line correctness.
#   - Documentation line referencing:  `git config core.hooksPath .githooks`
#   - Secret scan hook includes entropy/pattern scanning or gitleaks reference.
#   - Pre-commit hook contains a warning about direct commits to main/master.
#   - Optional pre-push hook (if present) mentions HEAD:main or ALLOW_MAIN_PUSH (advisory).
#   - Generate a concise JSON result artifact (stdout + optional file) for CI parsing.
#
# Exit codes:
#   0 = all required checks pass (warnings allowed)
#   1 = one or more required checks failed
#
# Output format:
#   Human-readable PASS/FAIL/WARN lines
#   Final summary line: RESULT: PASS|FAIL (fail_count=<n> warn_count=<m>)
#
# This test is intentionally self‑contained (no external dependencies beyond POSIX tools + zsh).
#
set -euo pipefail

### Helpers ###################################################################

fail_count=0
warn_count=0
results=()

colorize() {
  local level="$1"; shift
  local msg="$*"
  if [[ -t 1 ]]; then
    case "$level" in
      FAIL) print -r -- "\e[31m${msg}\e[0m" ;;
      WARN) print -r -- "\e[33m${msg}\e[0m" ;;
      PASS) print -r -- "\e[32m${msg}\e[0m" ;;
      *) print -r -- "$msg" ;;
    esac
  else
    print -r -- "$msg"
  fi
}

pass() { colorize PASS "PASS: $*"; results+=$"PASS: $*"; }
warn() { colorize WARN "WARN: $*"; results+=$"WARN: $*"; ((warn_count++)); }
fail() { colorize FAIL "FAIL: $*"; results+=$"FAIL: $*"; ((fail_count++)); }

require_file() {
  local path="$1" desc="$2"
  if [[ -f "$path" ]]; then
    pass "$desc present ($path)"
  else
    fail "$desc missing ($path)"
  fi
}

require_exec() {
  local path="$1" desc="$2"
  if [[ -f "$path" && -x "$path" ]]; then
    pass "$desc executable ($path)"
  else
    fail "$desc not executable ($path)"
  fi
}

require_shebang() {
  local path="$1" desc="$2"
  if head -1 "$path" 2>/dev/null | grep -Eq '^#!'; then
    pass "$desc has shebang"
  else
    fail "$desc missing shebang"
  fi
}

grep_expect() {
  local path="$1" pattern="$2" desc="$3"
  if grep -Eq "$pattern" "$path" 2>/dev/null; then
    pass "$desc"
  else
    fail "$desc (pattern '$pattern' not found in $path)"
  fi
}

grep_warn() {
  local path="$1" pattern="$2" desc="$3"
  if grep -Eq "$pattern" "$path" 2>/dev/null; then
    pass "$desc"
  else
    warn "$desc (advisory pattern '$pattern' not present)"
  fi
}

json_escape() {
  # naive escape for quotes/backslashes/newlines
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

### Locate repository root ####################################################

if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT=$(git rev-parse --show-toplevel)
else
  # Fallback: assume script in tests/integration
  REPO_ROOT="${0:A:h:h:h}"
fi
cd "$REPO_ROOT"

### Paths #####################################################################

REQ_PRE_COMMIT=".githooks/pre-commit"
REQ_SECRET_SCAN=".githooks/pre-commit.d/secret-scan"
OPT_PRE_PUSH=".githooks/pre-push"

### Required Files ############################################################

require_file "$REQ_PRE_COMMIT" "pre-commit hook"
require_file "$REQ_SECRET_SCAN" "secret-scan pre-commit hook module"

### Executable & Shebang ######################################################

require_exec "$REQ_PRE_COMMIT" "pre-commit hook"
require_exec "$REQ_SECRET_SCAN" "secret-scan hook"
require_shebang "$REQ_PRE_COMMIT" "pre-commit hook"
require_shebang "$REQ_SECRET_SCAN" "secret-scan hook"

### Documentation / Content Assertions ########################################

# Hook path usage doc
grep_expect "$REQ_SECRET_SCAN" 'git config core\.hooksPath .*\.githooks' "secret-scan hook documents core.hooksPath usage"

# Secret scanning logic indicators
if grep -Eq 'gitleaks|entropy|SECRET_SCAN' "$REQ_SECRET_SCAN" 2>/dev/null; then
  pass "secret-scan hook contains scanning logic keywords"
else
  fail "secret-scan hook missing scanning logic indicators (gitleaks/entropy/SECRET_SCAN vars)"
fi

# Pre-commit should warn about direct commits to main/master
grep_expect "$REQ_PRE_COMMIT" 'Direct commit.*(main|master)' "pre-commit hook warns on direct main/master commits"

# Optional pre-push
if [[ -f "$OPT_PRE_PUSH" ]]; then
  pass "optional pre-push hook present"
  grep_warn "$OPT_PRE_PUSH" 'HEAD:main|ALLOW_MAIN_PUSH' "pre-push hook references main push protection"
else
  warn "optional pre-push hook not present (advisory only)"
fi

### Aggregate / Summary #######################################################

status="PASS"
(( fail_count > 0 )) && status="FAIL"

colorize "$status" "RESULT: $status (fail_count=$fail_count warn_count=$warn_count)"

# Emit JSON summary (stdout) for potential parsing
# Provide minimal machine-readable structure.
printf '\n%s\n' "JSON_SUMMARY: {\"status\":\"$status\",\"fail_count\":$fail_count,\"warn_count\":$warn_count}"

# Optionally create an artifact file (non-fatal if cannot)
ARTIFACT_DIR="docs/badges"
mkdir -p "$ARTIFACT_DIR" 2>/dev/null || true
echo "{\"schemaVersion\":1,\"label\":\"git-hooks-test\",\"message\":\"$status\",\"color\":\"$([[ $status == PASS ]] && echo brightgreen || echo red)\"}" > "$ARTIFACT_DIR/git-hooks-test.json" 2>/dev/null || true

exit $(( fail_count > 0 ? 1 : 0 ))
