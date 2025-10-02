#!/usr/bin/env zsh
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v<checksum>
#
# docs-legacy-guard.zsh
# -----------------------------------------------------------------------------
# Purpose:
#   Guard (warn phase) against adding or modifying non‑deprecated content
#   inside the legacy documentation tree: docs/redesign/
#   Each changed legacy file (excluding generated artifact subdirs) must
#   contain the standardized deprecation banner marker:
#
#     <!-- DEPRECATED: Use docs/redesignv2/ -->
#
# Modes:
#   Soft (default): Only warns; always exits 0 so CI does not fail yet.
#   Enforce: Fails (non‑zero) if violations are detected.
#
# Triggers / Detection:
#   - Compares current HEAD with a base ref (default: origin/main) to find
#     added (A), modified (M), copied (C), renamed (R) files under
#     docs/redesign/.
#   - Ignores generated artifact directories:
#       docs/redesign/{badges,metrics,checksums,inventories}
#
# Exit Codes:
#   0  Soft mode or no violations
#   7  Violations in enforce mode
#   2  Script usage / argument error
#
# Configuration:
#   BASE_REF=origin/main   (override comparison base)
#   MIGRATION_ENFORCE=1    (enforce mode)
#
# CLI Flags:
#   --enforce    Enable enforce mode (same as MIGRATION_ENFORCE=1)
#   --help       Show help
#
# Future (Phase C):
#   - Switch CI to enforce mode (set MIGRATION_ENFORCE=1 or pass --enforce)
#   - Optionally extend detection to block *any* new file creation (A) even
#     with marker, if policy changes to freeze directory entirely.
#
# Safe to run multiple times; output is deterministic.
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT=${0:t}
BASE_REF=${BASE_REF:-origin/main}
ENFORCE=0

print_help() {
    cat <<'EOF'
Usage: docs-legacy-guard.zsh [--enforce] [--help]

Checks changed files under docs/redesign/ between BASE_REF (default origin/main) and HEAD
and warns (soft mode) or fails (enforce mode) if any file lacks the standardized
deprecation banner:

  <!-- DEPRECATED: Use docs/redesignv2/ -->

Environment:
  BASE_REF=origin/main       Override comparison base
  MIGRATION_ENFORCE=1        Enforce mode (fail on violations)

Options:
  --enforce                  Enforce mode (same as MIGRATION_ENFORCE=1)
  --help                     Show this help

Exit Codes:
  0  Success / soft warnings
  7  Violations (enforce mode)
  2  Usage error
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --enforce)
        ENFORCE=1
        shift
        ;;
    --help | -h)
        print_help
        exit 0
        ;;
    *)
        echo "[$SCRIPT] Unknown argument: $1" >&2
        exit 2
        ;;
    esac
done
[[ ${MIGRATION_ENFORCE:-0} == 1 ]] && ENFORCE=1

echo "[$SCRIPT] legacy docs guard (mode: $([[ $ENFORCE == 1 ]] && echo ENFORCE || echo SOFT)) base_ref=$BASE_REF"

# Ensure we are in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[$SCRIPT] Not inside a git repository." >&2
    exit 2
fi

# Attempt to fetch base ref (ignore failure if already present)
git fetch --no-tags --depth=1 $(echo "$BASE_REF" | cut -d/ -f1) "${BASE_REF#*/}" 2>/dev/null || true

# Collect changed files (name-status) relative to BASE_REF...HEAD
# We use the triple-dot range for symmetric diff (common ancestor) to handle diverged bases safely.
DIFF_RANGE="${BASE_REF}...HEAD"

# Some CI setups might only have a single dot available; fallback gracefully
if ! git rev-parse "${BASE_REF}" >/dev/null 2>&1; then
    echo "[$SCRIPT] WARNING: base ref ${BASE_REF} not found locally; using simple diff against HEAD~1 as fallback." >&2
    DIFF_RANGE="HEAD~1..HEAD"
fi

# Gather changed entries
# Format lines: <status>\t<path> [\t<path2> ...]
changes_raw=$(git diff --name-status "$DIFF_RANGE" || true)

legacy_candidates=()
while IFS=$'\t' read -r status p1 p2; do
    [[ -z "${status:-}" ]] && continue
    # Normalize path for rename/copy (status starts with R or C)
    # For rename R100 old new -> we want new path
    case "$status" in
    R* | C*) target="$p2" ;;
    *) target="$p1" ;;
    esac
    [[ "$target" == docs/redesign/* ]] || continue
    legacy_candidates+=("$target")
done <<<"$changes_raw"

if ((${#legacy_candidates[@]} == 0)); then
    echo "[$SCRIPT] No changed legacy docs — nothing to check."
    exit 0
fi

# Deduplicate
typeset -A seen
unique=()
for f in "${legacy_candidates[@]}"; do
    [[ -n "${seen[$f]:-}" ]] && continue
    seen[$f]=1
    unique+=("$f")
done

# Artifact subpaths to ignore (auto-generated)
ARTIFACT_SUBDIRS=(
    docs/redesign/badges/
    docs/redesign/metrics/
    docs/redesign/checksums/
    docs/redesign/inventories/
)

is_artifact() {
    local f=$1
    for a in "${ARTIFACT_SUBDIRS[@]}"; do
        [[ $f == $a* ]] && return 0
    done
    return 1
}

MARKER='<!-- DEPRECATED: Use docs/redesignv2/'
violations=()

for f in "${unique[@]}"; do
    # Skip removed files (D status) and artifacts
    if ! [[ -f "$f" ]]; then
        continue
    fi
    if is_artifact "$f"; then
        continue
    fi
    # Quick binary skip
    if file "$f" | grep -qi 'binary'; then
        continue
    fi
    if ! grep -qi "${MARKER}" "$f"; then
        violations+=("$f")
    fi
done

if ((${#violations[@]})); then
    echo "[$SCRIPT] ⚠ Missing deprecation marker in legacy docs:"
    for v in "${violations[@]}"; do
        echo " - $v"
    done
    cat <<'BANNER'
Add the standardized banner near the top of each file:

<!-- DEPRECATED: Use docs/redesignv2/<new-path> -->
> This legacy file is retained temporarily during the redesign migration.
> Author new content under docs/redesignv2/ only.

(Replace <new-path> with the appropriate target if giving a direct link.)
BANNER

    if ((ENFORCE)); then
        echo "[$SCRIPT] ENFORCE mode: failing due to violations."
        exit 7
    else
        echo "[$SCRIPT] SOFT mode: not failing (will enforce in later phase)."
        exit 0
    fi
else
    echo "[$SCRIPT] ✔ All changed legacy docs contain the required deprecation banner (or were artifacts)."
fi

exit 0
