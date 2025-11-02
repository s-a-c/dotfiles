#!/usr/bin/env zsh
# Compliant with ${HOME}/dotfiles/dot-config/ai/guidelines.md v<checksum>
#
# docs-path-audit.zsh
# -----------------------------------------------------------------------------
# Purpose:
#   Soft (warn-mode) scanner for lingering references to legacy `docs/redesign/`
#   outside the legacy tree itself. Helps ensure contributors migrate paths to
#   `docs/redesignv2/` during the soft migration phase.
#
# Behavior:
#   - Scans all tracked text files (git ls-files).
#   - Ignores anything actually under docs/redesign/ (that tree is allowed to
#     contain self-references and deprecation banners).
#   - Filters out allow‑listed patterns to avoid false positives.
#   - Prints a warning list of files still referencing legacy paths.
#   - Exits 0 in soft mode (default) so CI does not fail.
#
# Enforced Mode (future):
#   - Pass --enforce OR set MIGRATION_ENFORCE=1 to make any findings a failure.
#
# Exit Codes:
#   0  (soft) always, unless --enforce/MIGRATION_ENFORCE triggers strict mode
#   8  findings detected in enforce mode
#
# Customization:
#   - Adjust ALLOWLIST_PATTERNS below as migration progresses.
#   - Add / remove ignored directory globs in IGNORE_DIRS.
#
# Safe Re-run:
#   Idempotent; produces the same output given the same tree state.
#
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_NAME=${0:t}

PRINT_HELP() {
    cat <<'EOF'
Usage: docs-path-audit.zsh [--enforce] [--help]

Options:
  --enforce          Fail (exit 8) if unexpected legacy references found.
  --help             Show this help and exit.

Environment:
  MIGRATION_ENFORCE=1  Equivalent to --enforce.

Soft Phase (default):
  Only warns. Use --enforce (later phase) to convert warnings to failures.
EOF
}

ENFORCE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
    --enforce)
        ENFORCE=1
        shift
        ;;
    --help | -h)
        PRINT_HELP
        exit 0
        ;;
    *)
        echo "[$SCRIPT_NAME] Unknown argument: $1" >&2
        exit 2
        ;;
    esac
done
[[ ${MIGRATION_ENFORCE:-0} == 1 ]] && ENFORCE=1

# Directories whose contents we skip entirely (globs relative to repo root).
IGNORE_DIRS=(
    '.git/'
    'zsh/docs/redesignv2/' # new tree (self-references fine)
    'zsh/docs/redesign/'   # legacy tree allowed (self references)
    'node_modules/'
    'vendor/'
    '.cache/'
)

# Patterns that, if present anywhere in the file, allow the reference.
# (Case-insensitive match performed.)
ALLOWLIST_PATTERNS=(
    'DEPRECATED: Use docs/redesignv2/'
    'migration'
    'deprecated'
    'docs/redesign/README'
    'redirect'
)

echo "[$SCRIPT_NAME] starting legacy path audit (mode: $([[ $ENFORCE == 1 ]] && echo ENFORCE || echo SOFT))"

# Resolve repository root (tolerant of being launched from subdir).
if command -v git >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
else
    REPO_ROOT=$PWD
fi
cd "$REPO_ROOT"

# Build a combined extended glob for ignore pruning.
# We'll just filter after listing; simpler & portable.
# Collect candidate files (tracked only).
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[$SCRIPT_NAME] Not inside a git work tree; aborting." >&2
    exit 1
fi

# Temp file for findings.
TMP_FINDINGS=$(mktemp)
trap 'rm -f "$TMP_FINDINGS"' EXIT

# Helper: return 0 if should ignore file.
_should_ignore() {
    local f=$1
    for pat in "${IGNORE_DIRS[@]}"; do
        # Normalize trailing slash expectation
        if [[ $pat == */ && $f == ${pat%/}/* ]]; then
            return 0
        fi
        # Direct match (directory or file)
        if [[ $f == $pat* ]]; then
            return 0
        fi
    done
    return 1
}

LEGACY_TOKEN='docs/redesign/'
files=($(git ls-files))

for f in "${files[@]}"; do
    [[ -f $f ]] || continue
    if _should_ignore "$f"; then
        continue
    fi
    # Quick skip if file does not contain token
    if ! grep -q "$LEGACY_TOKEN" "$f" 2>/dev/null; then
        continue
    fi

    # Exclude binary-ish files (very naive: non-text detection via 'file').
    if file "$f" | grep -qi 'binary'; then
        continue
    fi

    # If any allowlist pattern matches (case-insensitive), skip.
    allow_hit=0
    for pat in "${ALLOWLIST_PATTERNS[@]}"; do
        if grep -i -q "$pat" "$f"; then
            allow_hit=1
            break
        fi
    done
    ((allow_hit)) && continue

    echo "$f" >>"$TMP_FINDINGS"
done

if [[ -s $TMP_FINDINGS ]]; then
    echo "[$SCRIPT_NAME] ⚠ Legacy references found outside legacy tree:"
    sed 's/^/ - /' "$TMP_FINDINGS"
    echo ""
    echo "Remediation:"
    echo "  Replace occurrences of 'docs/redesign/' with 'docs/redesignv2/' (or update logic to auto-detect)."
    echo "  If a file must keep the reference temporarily, add a clear migration/deprecation comment."
    if ((ENFORCE)); then
        echo "[$SCRIPT_NAME] ENFORCE mode active: failing due to findings."
        exit 8
    else
        echo "[$SCRIPT_NAME] SOFT mode: not failing (will fail in enforce phase)."
        exit 0
    fi
else
    echo "[$SCRIPT_NAME] ✔ No unexpected legacy path references detected."
fi

exit 0
