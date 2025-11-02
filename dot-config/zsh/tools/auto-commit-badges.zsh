#!/usr/bin/env zsh
# auto-commit-badges.zsh
#
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# Purpose:
#   Reusable helper to (optionally) stage, commit, and push updated badge artifacts
#   (JSON + SVG) produced by CI workflows or local tooling without duplicating
#   auto-commit logic across multiple workflows.
#
# Features:
#   - Safe no-op if no badge changes.
#   - Restricts scope to a configurable directory (default: docs/badges).
#   - Enforces main-branch-only commits unless overridden.
#   - Supports optional GPG / SSH signing (if git configured) and customizable commit messages.
#   - Distinguishes between "nothing to do" vs. fatal conditions via exit codes.
#   - Optional hash summary output for traceability.
#   - Optional PR fallback: if direct push is rejected (e.g., branch protection), create a branch and (optionally) a PR.
#
# Usage:
#   tools/auto-commit-badges.zsh [options]
#
# Options:
#   --dir <path>            Badge directory (default: docs/badges)
#   --include <glob>        Additional glob(s) (can repeat) to include for staging (default: "*.json" "*.svg")
#   --branch <name>         Expected branch (default: current HEAD branch)
#   --force-any-branch      Allow committing on non-main branches
#   --allow-dirty           Permit unrelated unstaged changes outside badge dir (ignored by this script)
#   --message <msg>         Custom commit message (default auto message)
#   --append-msg <text>     Append extra text to auto message
#   --skip-ci               Append "[skip ci]" trailer automatically
#   --sign                  Attempt to sign commit (equivalent to BADGE_AUTO_SIGN=1)
#   --dry-run               Show actions without performing git writes
#   --hash-summary          Print SHA256 summary of changed badge files post-commit
#   --pr-fallback           On push failure: create branch (badge-update-<timestamp>) and attempt PR (draft if gh CLI available)
#   --pr-draft              Force PR creation as draft (default if gh present)
#   --pr-title <title>      Custom PR title (default derived from commit)
#   --help                  Show this help
#
# Environment Overrides:
#   BADGE_AUTO_FORCE=1          (same as --force-any-branch)
#   BADGE_AUTO_ALLOW_DIRTY=1    (same as --allow-dirty)
#   BADGE_AUTO_SIGN=1           (same as --sign)
#   BADGE_AUTO_SKIP_CI=1        (same as --skip-ci)
#   BADGE_AUTO_DRY_RUN=1        (same as --dry-run)
#   BADGE_AUTO_HASH=1           (same as --hash-summary)
#   BADGE_AUTO_APPEND_MSG       (text appended to message)
#   BADGE_AUTO_PR_FALLBACK=1    (same as --pr-fallback)
#   BADGE_AUTO_PR_DRAFT=1       (same as --pr-draft)
#   BADGE_AUTO_PR_TITLE         (custom PR title)
#
# Exit Codes:
#   0  Success (commit pushed or changes not required)
#   10 Nothing to commit (clean)
#   20 Unrelated dirty workspace (and --allow-dirty not set)
#   30 Git push failed (and no PR fallback or fallback disabled)
#   40 Badge directory missing
#   50 Invalid usage / argument error
#   60 PR fallback branch push failed
#
# Security / Safety:
#   - Only stages files that match allowed patterns inside the badge directory (and optional includes).
#   - Will not auto-commit outside the intended directory unless explicitly included.
#
# Example:
#   tools/auto-commit-badges.zsh --dir docs/badges --skip-ci --hash-summary
#
# Future Enhancements (not implemented):
#   - Artifact signing / provenance manifest.
#   - Delta classification (trend vs. raw changes).
#
set -euo pipefail

SCRIPT_NAME=${0:t}
BADGE_DIR="docs/badges"
typeset -a INCLUDE_GLOBS
INCLUDE_GLOBS=("*.json" "*.svg")
EXPECTED_BRANCH=""
FORCE_ANY_BRANCH=${BADGE_AUTO_FORCE:-0}
ALLOW_DIRTY=${BADGE_AUTO_ALLOW_DIRTY:-0}
SIGN=${BADGE_AUTO_SIGN:-0}
SKIP_CI=${BADGE_AUTO_SKIP_CI:-0}
DRY_RUN=${BADGE_AUTO_DRY_RUN:-0}
HASH_SUMMARY=${BADGE_AUTO_HASH:-0}
APPEND_MSG="${BADGE_AUTO_APPEND_MSG:-}"
CUSTOM_MESSAGE=""
APPEND_CUSTOM=""
PR_FALLBACK=${BADGE_AUTO_PR_FALLBACK:-0}
PR_DRAFT=${BADGE_AUTO_PR_DRAFT:-0}
PR_TITLE="${BADGE_AUTO_PR_TITLE:-}"
COLOR=1

[[ -t 1 ]] || COLOR=0
if (( COLOR )); then
  c_green=$'%F{2}'
  c_yellow=$'%F{3}'
  c_red=$'%F{1}'
  c_blue=$'%F{4}'
  c_reset=$'%f'
else
  c_green=""; c_yellow=""; c_red=""; c_blue=""; c_reset=""
fi

print_info()  { print -- "${c_blue}[${SCRIPT_NAME}]${c_reset} $*"; }
print_warn()  { print -- "${c_yellow}[${SCRIPT_NAME}][WARN]${c_reset} $*"; }
print_error() { print -- "${c_red}[${SCRIPT_NAME}][ERROR]${c_reset} $*" >&2; }
print_ok()    { print -- "${c_green}[${SCRIPT_NAME}]${c_reset} $*"; }

usage() {
  sed -n '1,180p' "$0" | grep -E '^# ' | sed 's/^# //'
  echo
  exit 0
}

die() {
  print_error "$1"
  exit "${2:-50}"
}

have_gh() {
  command -v gh >/dev/null 2>&1
}

# ------------- Argument Parsing -------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) BADGE_DIR="$2"; shift 2 ;;
    --include) INCLUDE_GLOBS+=("$2"); shift 2 ;;
    --branch) EXPECTED_BRANCH="$2"; shift 2 ;;
    --force-any-branch) FORCE_ANY_BRANCH=1; shift ;;
    --allow-dirty) ALLOW_DIRTY=1; shift ;;
    --message) CUSTOM_MESSAGE="$2"; shift 2 ;;
    --append-msg) APPEND_CUSTOM="$2"; shift 2 ;;
    --skip-ci) SKIP_CI=1; shift ;;
    --sign) SIGN=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --hash-summary) HASH_SUMMARY=1; shift ;;
    --pr-fallback) PR_FALLBACK=1; shift ;;
    --pr-draft) PR_DRAFT=1; shift ;;
    --pr-title) PR_TITLE="$2"; shift 2 ;;
    --help|-h) usage ;;
    *) die "Unknown argument: $1" 50 ;;
  esac
done

[[ -d "$BADGE_DIR" ]] || die "Badge directory not found: $BADGE_DIR" 40

# ------------- Git Context -------------
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
else
  die "Not inside a git repository."
fi

if [[ -z "$EXPECTED_BRANCH" ]]; then
  EXPECTED_BRANCH="$CURRENT_BRANCH"
fi

if [[ "$CURRENT_BRANCH" != "$EXPECTED_BRANCH" ]] && [[ $FORCE_ANY_BRANCH -ne 1 ]]; then
  if [[ "$CURRENT_BRANCH" != "main" ]]; then
    print_warn "Current branch '$CURRENT_BRANCH' != expected '$EXPECTED_BRANCH'; auto-commit skipped (use --force-any-branch to override)."
    exit 10
  fi
fi

# ------------- Workspace Dirty Check -------------
if (( ! ALLOW_DIRTY )); then
  outside_dirty=$(git status --porcelain | awk '{print $2}' | grep -v "^${BADGE_DIR}/" || true)
  if [[ -n "$outside_dirty" ]]; then
    print_warn "Unrelated unstaged changes outside '$BADGE_DIR' detected; aborting (use --allow-dirty to override)."
    exit 20
  fi
fi

# ------------- Collect Candidate Files -------------
typeset -a CANDIDATES
pushd "$BADGE_DIR" >/dev/null || die "Cannot enter $BADGE_DIR"
for g in "${INCLUDE_GLOBS[@]}"; do
  for f in ${(f)"$(printf "%s\n" $~g 2>/dev/null)"}; do
    [[ -f "$f" ]] && CANDIDATES+=("$f")
  done
done
popd >/dev/null

if (( ${#CANDIDATES[@]} == 0 )); then
  print_warn "No matching badge artifacts under $BADGE_DIR (patterns: ${INCLUDE_GLOBS[*]})."
  exit 10
fi

# ------------- Determine Changed Files -------------
typeset -a CHANGED
for f in "${CANDIDATES[@]}"; do
  if ! git diff --quiet -- "$BADGE_DIR/$f" 2>/dev/null || ! git diff --cached --quiet -- "$BADGE_DIR/$f" 2>/dev/null; then
    CHANGED+=("$BADGE_DIR/$f")
  fi
done

if (( ${#CHANGED[@]} == 0 )); then
  print_ok "No badge changes detected."
  exit 10
fi

print_info "Detected changed badge files:"
for f in "${CHANGED[@]}"; do
  print_info "  - $f"
done

# ------------- Compose Commit Message -------------
timestamp=$(date -u +%FT%TZ 2>/dev/null || date)
if [[ -z "$CUSTOM_MESSAGE" ]]; then
  base_msg="ci: update badges (${#CHANGED[@]} file(s))"
else
  base_msg="$CUSTOM_MESSAGE"
fi

[[ -n "$APPEND_MSG" ]] && base_msg="$base_msg $APPEND_MSG"
[[ -n "$APPEND_CUSTOM" ]] && base_msg="$base_msg $APPEND_CUSTOM"
[[ $SKIP_CI -eq 1 ]] && base_msg="$base_msg [skip ci]"

# ------------- Dry Run Mode -------------
if (( DRY_RUN )); then
  print_info "Dry run: would stage & commit these files:"
  printf "%s\n" "${CHANGED[@]}"
  print_info "Proposed commit message: $base_msg"
  exit 0
fi

# ------------- Stage & Commit -------------
git add "${CHANGED[@]}" || die "Failed to stage badge files."

if git diff --cached --quiet; then
  print_ok "After staging, no net changes (possible race)."
  exit 10
fi

# Configure git user if absent (CI context)
if [[ -z "$(git config user.name || true)" ]]; then
  git config user.name "ci-badge-bot"
fi
if [[ -z "$(git config user.email || true)" ]]; then
  git config user.email "ci-badge-bot@users.noreply.github.com"
fi

commit_args=()
if (( SIGN )); then
  commit_args+=("-S")
fi

if ! git commit "${commit_args[@]}" -m "$base_msg"; then
  print_error "Commit failed."
  exit 30
fi

print_ok "Created commit for badge updates."

# ------------- Push -------------
if ! git push; then
  if (( PR_FALLBACK )); then
    print_warn "Direct push failed. Attempting PR fallback."
    fallback_branch="badge-update-${timestamp//[:T-]/}-${RANDOM}"
    # Create branch from current HEAD
    git branch "$fallback_branch" HEAD || {
      print_error "Failed to create fallback branch."
      exit 30
    }
    if ! git push -u origin "$fallback_branch"; then
      print_error "Fallback branch push failed."
      exit 60
    fi
    print_ok "Pushed fallback branch: $fallback_branch"
    # Attempt PR creation if gh CLI available
    if have_gh; then
      pr_title="${PR_TITLE:-Badge update ($fallback_branch)}"
      pr_body="Automated badge update fallback (original push blocked).\nGenerated at: $timestamp"
      gh pr create \
        --title "$pr_title" \
        --body "$pr_body" \
        --head "$fallback_branch" \
        $([[ $PR_DRAFT -eq 1 ]] && echo "--draft") || print_warn "gh pr create failed (non-fatal)."
      print_ok "PR creation attempted (gh)."
    else
      print_info "gh CLI not available; manual PR creation needed for branch: $fallback_branch"
    fi
    # Hash summary still possible after fallback
  else
    print_error "Git push failed."
    exit 30
  fi
else
  print_ok "Pushed badge update commit."
fi

# ------------- Hash Summary (Optional) -------------
if (( HASH_SUMMARY )); then
  print_info "SHA256 hashes of committed badge files:"
  for f in "${CHANGED[@]}"; do
    if command -v shasum >/dev/null 2>&1; then
      h=$(shasum -a 256 "$f" | awk '{print $1}')
    elif command -v sha256sum >/dev/null 2>&1; then
      h=$(sha256sum "$f" | awk '{print $1}')
    else
      h="(no-sha-tool)"
    fi
    print_info "  $h  $f"
  done
fi

exit 0
