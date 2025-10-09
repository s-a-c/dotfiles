#!/usr/bin/env bash
# clean-zsh-refactor.sh
# Purpose: Safely clean ephemeral artifacts produced by the zsh refactor environment.
# Phases: Maintenance utility (manual invocation) – NOT sourced automatically.
# Dependencies: None required; optional shellcheck for linting. POSIX-ish but uses bash arrays for clarity.
# Safety: Dry-run by default. Requires --apply to actually delete. Guards against removing outside repo root.
# Ends with exit codes: 0 success, >0 on error.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Allow override for testing
WORK_ROOT="${WORK_ROOT_OVERRIDE:-$REPO_ROOT}"

COLOR_RESET='\033[0m'
COLOR_RED='\033[31m'
COLOR_GREEN='\033[32m'
COLOR_YELLOW='\033[33m'
COLOR_BLUE='\033[34m'

say() { printf "%b\n" "$*"; }
info() { say "${COLOR_BLUE}[info]${COLOR_RESET} $*"; }
warn() { say "${COLOR_YELLOW}[warn]${COLOR_RESET} $*"; }
err()  { say "${COLOR_RED}[error]${COLOR_RESET} $*" >&2; }
success() { say "${COLOR_GREEN}[ok]${COLOR_RESET} $*"; }

die() { err "$1"; exit 1; }

DRY_RUN=1
APPLY=0
SCOPE="all"
KEEP_PATTERNS=()
PURGE_CACHES=0
RETAIN_LOG_BASELINES=0 # keep newest N baseline_* files (0 => no retention, remove all matching within scope)
LIST_SCOPES=0
VERBOSE=0

usage() {
  cat <<EOF
$SCRIPT_NAME - clean ephemeral artifacts for zsh refactor repo

Usage: $SCRIPT_NAME [options]

Options:
  --dry-run              (default) Show what would be deleted.
  --apply                Actually perform deletions (implies not dry-run).
  --scope <name>         Scope to clean: logs, artifacts, caches, all (default: all).
  --list-scopes          List supported scope groups and exit.
  --keep <pattern>       Glob (relative to repo root) to protect; can repeat.
  --purge-caches         Include cache directories (~/.zsh-evalcache etc inside repo).
  --retain <N>           Retain newest N baseline_* metric/log files in logs scope.
  -v / --verbose         Extra output.
  -h / --help            This help.

Examples:
  $SCRIPT_NAME --scope logs            # show candidate log deletions
  $SCRIPT_NAME --scope logs --retain 5 # keep 5 newest baseline_* files
  $SCRIPT_NAME --apply --scope artifacts
  $SCRIPT_NAME --apply --purge-caches --keep artifacts/smoke.json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --scope) SCOPE="$2"; shift 2 ;;
    --list-scopes) LIST_SCOPES=1; shift ;;
    --keep) KEEP_PATTERNS+=("$2"); shift 2 ;;
    --purge-caches) PURGE_CACHES=1; shift ;;
    --retain) RETAIN_LOG_BASELINES="$2"; shift 2 ;;
    -v|--verbose) VERBOSE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown argument: $1"; usage; exit 2 ;;
  esac
done

if [[ $LIST_SCOPES -eq 1 ]]; then
  cat <<EOF
Supported scopes:
  logs       -> logs/ baseline_* files + dated log dirs
  artifacts  -> artifacts/ JSON + metrics directory contents
  caches     -> .context-cache/ .zsh-evalcache/ .performance/ .augment/
  all        -> union of logs,artifacts plus caches if --purge-caches
EOF
  exit 0
fi

case "$SCOPE" in
  logs|artifacts|caches|all) ;;
  *) die "Invalid scope: $SCOPE" ;;
esac

# Collect candidate paths for deletion based on scope
collect_candidates() {
  local scope="$1"
  local -a items=()
  if [[ "$scope" == "logs" || "$scope" == "all" ]]; then
    if [[ -d "$WORK_ROOT/logs" ]]; then
      # baseline_* files
      while IFS= read -r -d '' f; do items+=("$f"); done < <(find "$WORK_ROOT/logs" -maxdepth 1 -type f -name 'baseline_*' -print0 2>/dev/null || true)
      # dated subdirs (simple heuristic YYYY-MM-DD)
      while IFS= read -r -d '' d; do items+=("$d"); done < <(find "$WORK_ROOT/logs" -mindepth 1 -maxdepth 1 -type d -regex '.*/[0-9]{4}-[0-9]{2}-[0-9]{2}' -print0 2>/dev/null || true)
    fi
  fi
  if [[ "$scope" == "artifacts" || "$scope" == "all" ]]; then
    if [[ -d "$WORK_ROOT/artifacts" ]]; then
      while IFS= read -r -d '' f; do items+=("$f"); done < <(find "$WORK_ROOT/artifacts" -maxdepth 1 -type f -name '*.json' -print0 2>/dev/null || true)
      if [[ -d "$WORK_ROOT/artifacts/metrics" ]]; then
        while IFS= read -r -d '' f; do items+=("$f"); done < <(find "$WORK_ROOT/artifacts/metrics" -type f -print0 2>/dev/null || true)
      fi
    fi
  fi
  if [[ $PURGE_CACHES -eq 1 && ( "$scope" == "caches" || "$scope" == "all" ) ]]; then
    for c in .context-cache .zsh-evalcache .performance .augment; do
      [[ -d "$WORK_ROOT/$c" ]] && items+=("$WORK_ROOT/$c") || true
    done
  fi
  printf '%s\n' "${items[@]}"
}

should_keep() {
  local path="$1"
  # If no keep patterns defined, return non-zero
  if [[ ${#KEEP_PATTERNS[@]:-0} -eq 0 ]]; then
    return 1
  fi
  local pat
  for pat in "${KEEP_PATTERNS[@]}"; do
    if [[ "$path" == "$WORK_ROOT/$pat" || "$path" == "$WORK_ROOT/$pat" ]]; then
      return 0
    fi
    # glob match relative
    local rel=${path#"$WORK_ROOT/"}
    if [[ "$rel" == "$pat" ]]; then
      return 0
    fi
  done
  return 1
}

apply_retention_filter() {
  local -a input=("$@")
  local -a out=()
  if [[ $RETAIN_LOG_BASELINES -gt 0 ]]; then
    local -a baseline_files=()
    local f
    for f in "${input[@]}"; do
      if [[ "$f" == */logs/baseline_* ]]; then
        baseline_files+=("$f")
      else
        out+=("$f")
      fi
    done
    if [[ ${#baseline_files[@]} -gt $RETAIN_LOG_BASELINES ]]; then
      # create a temp list sorted by mtime desc
      # Use printf + stat fallback; mac stat format: stat -f %m
      local tmpfile
      tmpfile="$(mktemp)" || return 1
      for f in "${baseline_files[@]}"; do
        if [[ -e "$f" ]]; then
          local mtime
          mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
          printf '%s\t%s\n' "$mtime" "$f" >> "$tmpfile"
        fi
      done
      # sort numeric reverse, extract path
      local -a baseline_sorted=()
      while IFS=$'\t' read -r _ ts_path; do baseline_sorted+=("$ts_path"); done < <(sort -rn "$tmpfile")
      rm -f "$tmpfile"
      local keep_count=0
      local -a keep_slice=()
      for f in "${baseline_sorted[@]}"; do
        if [[ $keep_count -lt $RETAIN_LOG_BASELINES ]]; then
          keep_slice+=("$f")
          keep_count=$((keep_count+1))
        else
          break
        fi
      done
      # mark keeps
      local k
      for f in "${baseline_files[@]}"; do
        local keep_flag=0
        for k in "${keep_slice[@]}"; do
          [[ "$f" == "$k" ]] && keep_flag=1 && break
        done
        if [[ $keep_flag -eq 0 ]]; then
          out+=("$f")
        fi
      done
    fi
    printf '%s\n' "${out[@]}"
  else
    printf '%s\n' "${input[@]}"
  fi
}

main() {
  # Use APPLY variable explicitly so shellcheck sees it
  if [[ $APPLY -eq 1 ]]; then :; fi
  [[ -d "$WORK_ROOT" ]] || die "Work root not found: $WORK_ROOT"
  local -a candidates=()
  while IFS= read -r line; do candidates+=("$line"); done < <(collect_candidates "$SCOPE")
  if [[ ${#candidates[@]} -eq 0 ]]; then
    info "No candidates found for scope '$SCOPE'"
    exit 0
  fi
  # retention
  local -a retained=()
  while IFS= read -r line; do retained+=("$line"); done < <(apply_retention_filter "${candidates[@]}")
  candidates=("${retained[@]}")
  local -a final=()
  local p
  for p in "${candidates[@]}"; do
    if should_keep "$p"; then
      [[ $VERBOSE -eq 1 ]] && info "keeping (pattern) $p" || true
      continue
    fi
    final+=("$p")
  done
  if [[ ${#final[@]} -eq 0 ]]; then
    info "Nothing to delete after filters."
    exit 0
  fi
  info "Planned deletions (count=${#final[@]}):"
  for p in "${final[@]}"; do
    say "  $p"
  done
  if [[ $DRY_RUN -eq 1 ]]; then
    warn "Dry-run mode; no deletions performed. Use --apply to proceed."
    exit 0
  fi
  warn "Proceeding with deletion (apply mode)."
  local failures=0
  for p in "${final[@]}"; do
    if [[ -e "$p" ]]; then
      rm -rf -- "$p" || { err "Failed to remove $p"; failures=$((failures+1)); }
    fi
  done
  if [[ $failures -gt 0 ]]; then
    die "$failures deletions failed"
  fi
  success "Deletion complete."
}

main "$@"
