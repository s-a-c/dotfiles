#!/usr/bin/env bash
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v9ab717af287538a58515d2f3369d011f40ef239829ec614afadfc1cc419e5f20
# Purpose: Observation-only repository size report for CI artifacts. No enforcement, no runner mutation, no secret access.
# Sensitive rules cited:
# - CI configuration: [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md:8)
# - Security & secret handling: [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md:16)
# - Path policy: [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md:23)

set -euo pipefail

print_section() { printf "\n===== %s =====\n" "$1"; }

du_smart_depth() {
  # Args: depth path
  local depth="$1"; shift
  local path="$1"
  if du -kh --max-depth="$depth" "$path" >/dev/null 2>&1; then
    du -kh --max-depth="$depth" "$path"
  elif du -kh -d "$depth" "$path" >/dev/null 2>&1; then
    du -kh -d "$depth" "$path"
  else
    # Fallback to a plain summary when depth flags are unavailable
    du -kh "$path"
  fi
}

now_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

print_section "environment"
echo "when=$(now_utc)"
echo "uname=$(uname -a)"
echo "shell=${SHELL:-}"
echo "pwd=$(pwd)"
echo "git_sha=$(git rev-parse --short HEAD 2>/dev/null || echo n/a)"

print_section "submodules"
if command -v git >/dev/null 2>&1; then
  git submodule status --recursive || true
else
  echo "git not available"
fi

print_section "totals"
# Total including .git
if du -sk . >/dev/null 2>&1; then
  du -sk . | awk '{printf "total_kb=%s\n", $1}'
fi
if du -sh . >/dev/null 2>&1; then
  du -sh . | awk '{printf "total_hr=%s\n", $1}'
fi

print_section "top-level-directories (depth=1)"
du_smart_depth 1 . | sort -h | tail -n 40

print_section "largest-directories (depth=2)"
du_smart_depth 2 . | sort -h | tail -n 40

print_section "largest-files (top 50, excluding common noisy paths)"
# Exclusions align with hardened ignores and common large/noisy dirs
# Use null-delimited find to handle spaces; guard against broken pipes by consuming limited results safely
PRUNE=(
  -path './.git' -prune -o
  -path './.cache' -prune -o
  -path './.direnv' -prune -o
  -path './node_modules' -prune -o
  -path './vendor' -prune -o
  -path './build' -prune -o
  -path './dist' -prune -o
)
# Collect list first to avoid upstream writers breaking when downstream exits early
mapfile -d '' FILES < <(find . "${PRUNE[@]}" -type f -print0)
if ((${#FILES[@]})); then
  # Batch du to reduce process count; ignore files that disappear
  printf '%s\
' "${FILES[@]}" | xargs -r -n 200 du -k 2>/dev/null \
    | sort -nrk1 \
    | head -n 50 \
    | awk '{printf "%8d KB  %s\n", $1, substr($0, index($0,$2))}'
else
  echo "(no files found after pruning)"
fi

print_section "note"
echo "This report is observational. It does not fail CI or enforce limits."
echo "Designed to be portable across GNU/BSD userlands with graceful fallbacks."
