#!/usr/bin/env bash
#
# history-purge.sh
#
# Unified tool to remove sensitive file paths from ALL git history using git-filter-repo.
#
# Features:
#   - Paths via positional args, --add-path, and/or --paths-file
#   - Optional glob expansion (git ls-files)
#   - Interactive confirmations
#   - Blob size enumeration (chain-of-custody digest)
#   - Dry run / list-only modes (no history rewrite)
#   - Post-rewrite verification + basic token pattern scan
#   - JSON machine-readable summary (--json-summary)
#   - Force push (lease or hard) with safety backup tag
#   - Can skip push (for inspection first)
#   - Allows but discourages dirty tree override
#
# Exit codes:
#   0 success
#   1 argument / environment / verification failure
#
# Dependencies: git, git-filter-repo, jq (optional for JSON summary), sha256sum|shasum
#
set -euo pipefail

VERSION="1.0.0"

# Color handling (only if TTY)
if [[ -t 1 ]]; then
    RED=$'\e[31m'
    GREEN=$'\e[32m'
    YELLOW=$'\e[33m'
    BOLD=$'\e[1m'
    DIM=$'\e[2m'
    RESET=$'\e[0m'
else
    RED=""
    GREEN=""
    YELLOW=""
    BOLD=""
    DIM=""
    RESET=""
fi

log() { echo "${GREEN}[*]${RESET} $*"; }
warn() { echo "${YELLOW}[!]${RESET} $*"; }
err() { echo "${RED}[x]${RESET} $*" >&2; }
note() { echo "${BOLD}[-]${RESET} $*"; }
die() {
    err "$*"
    exit 1
}

ask() {
    local prompt="$1"
    local default="${2:-y}"
    local answer
    if [[ "$INTERACTIVE" -eq 0 ]]; then
        return 0
    fi
    if [[ "$default" == "y" ]]; then
        read -rp "$prompt [Y/n] " answer
        answer=${answer:-y}
    else
        read -rp "$prompt [y/N] " answer
        answer=${answer:-n}
    fi
    [[ "$answer" =~ ^[Yy]$ ]]
}

# Defaults
BRANCH=""
FORCE_MODE="lease" # or "force"
DO_VERIFY=1
DO_PUSH=1
DRY_RUN=0
EXPAND_GLOBS=0
INTERACTIVE=0
SKIP_SIZE_SCAN=0
TOKEN_SCAN=1
LIST_ONLY=0
ALLOW_DIRTY=0
JSON_SUMMARY=0
BACKUP_TAG=""
PATHS_FILE=""
EXTRA_PATHS=()
POSITIONAL=()
PRINT_COMMAND=0

usage() {
    cat <<'EOF'
Usage:
  history-purge.sh --branch <branch> [paths ...] [options]

Path Sources:
  Positional arguments              Direct file paths
  --add-path <path>                 Add one path (repeatable)
  --paths-file <file>               File with one path/glob per line (# and blank ignored)

Options:
  --branch <name>                   Branch to rewrite (required)
  --expand-globs                    Expand wildcards via 'git ls-files'
  --interactive                     Prompt at key steps
  --skip-push                       Do not push after rewrite
  --force                           Use hard force push (+ref) instead of --force-with-lease
  --no-verify                       Skip post-removal verification
  --skip-size-scan                  Skip blob size enumeration
  --no-scan                         Skip token pattern scan
  --dry-run                         Show actions; do nothing
  --list-only                       Enumerate blobs & exit (implies --dry-run, no rewrite)
  --allow-dirty                     Allow running with uncommitted changes (discouraged)
  --backup-tag <name>               Custom safety tag (default auto timestamp)
  --json-summary                    Emit JSON summary to stdout (requires jq)
  --add-path <path>                 Add path (repeatable)
  --paths-file <file>               Include additional paths
  --print-command                   Print constructed git filter-repo command
  --version                         Print version
  -h, --help                        This help

Examples:
  history-purge.sh --branch feature/zsh-refactor-configuration \
    support-evidence/capture-TS/control.log

  history-purge.sh --branch feat \
    --paths-file purge-list.txt --expand-globs --interactive

  history-purge.sh --branch feat \
    --paths-file purge-list.txt --expand-globs --list-only

Exit codes: 0 success, 1 failure
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    --branch)
        BRANCH="${2:-}"
        shift 2
        ;;
    --expand-globs)
        EXPAND_GLOBS=1
        shift
        ;;
    --interactive)
        INTERACTIVE=1
        shift
        ;;
    --skip-push)
        DO_PUSH=0
        shift
        ;;
    --force)
        FORCE_MODE="force"
        shift
        ;;
    --no-verify)
        DO_VERIFY=0
        shift
        ;;
    --skip-size-scan)
        SKIP_SIZE_SCAN=1
        shift
        ;;
    --no-scan)
        TOKEN_SCAN=0
        shift
        ;;
    --dry-run)
        DRY_RUN=1
        shift
        ;;
    --list-only)
        LIST_ONLY=1
        DRY_RUN=1
        DO_PUSH=0
        shift
        ;;
    --allow-dirty)
        ALLOW_DIRTY=1
        shift
        ;;
    --backup-tag)
        BACKUP_TAG="${2:-}"
        shift 2
        ;;
    --json-summary)
        JSON_SUMMARY=1
        shift
        ;;
    --add-path)
        EXTRA_PATHS+=("${2:-}")
        shift 2
        ;;
    --paths-file)
        PATHS_FILE="${2:-}"
        shift 2
        ;;
    --print-command)
        PRINT_COMMAND=1
        shift
        ;;
    --version)
        echo "$VERSION"
        exit 0
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    --)
        shift
        break
        ;;
    -*)
        die "Unknown option: $1"
        ;;
    *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done || true

# Validate
[[ -n "$BRANCH" ]] || die "--branch is required"
command -v git >/dev/null || die "git not found"
command -v git-filter-repo >/dev/null 2>&1 || die "git-filter-repo not installed (brew install git-filter-repo)"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    die "Not inside a git repository"
fi

if ! git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
    die "Branch '${BRANCH}' not found locally; checkout or fetch it first"
fi

DIRTY=$(git status --porcelain)
if [[ -n "$DIRTY" && $ALLOW_DIRTY -eq 0 ]]; then
    die "Working tree dirty. Commit/stash or use --allow-dirty (not recommended)"
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "$BRANCH" ]]; then
    log "Checking out branch '$BRANCH'"
    git checkout "$BRANCH"
fi

# Aggregate paths
RAW_PATHS=()
RAW_PATHS+=("${POSITIONAL[@]}")
RAW_PATHS+=("${EXTRA_PATHS[@]}")

if [[ -n "$PATHS_FILE" ]]; then
    [[ -f "$PATHS_FILE" ]] || die "Paths file not found: $PATHS_FILE"
    while IFS= read -r line || [[ -n "$line" ]]; do
        trimmed="${line#"${line%%[![:space:]]*}"}"
        [[ -z "$trimmed" ]] && continue
        [[ "$trimmed" =~ ^# ]] && continue
        RAW_PATHS+=("$trimmed")
    done <"$PATHS_FILE"
fi

[[ ${#RAW_PATHS[@]} -gt 0 ]] || die "No paths specified."

# Expand globs if requested
FINAL_PATHS=()
if [[ $EXPAND_GLOBS -eq 1 ]]; then
    note "Expanding globs via git ls-files"
    for p in "${RAW_PATHS[@]}"; do
        if [[ "$p" == *'*'* || "$p" == *'?'* ]]; then
            matches=$(git ls-files -- "$p" || true)
            if [[ -z "$matches" ]]; then
                warn "No match for pattern: $p"
            else
                while IFS= read -r m; do FINAL_PATHS+=("$m"); done <<<"$matches"
            fi
        else
            FINAL_PATHS+=("$p")
        fi
    done
else
    FINAL_PATHS=("${RAW_PATHS[@]}")
fi

# Deduplicate
mapfile -t FINAL_PATHS < <(printf "%s\n" "${FINAL_PATHS[@]}" | awk '!seen[$0]++')
[[ ${#FINAL_PATHS[@]} -gt 0 ]] || die "After expansion, no paths remain."

note "Paths targeted for removal (${#FINAL_PATHS[@]}):"
for p in "${FINAL_PATHS[@]}"; do
    echo "  - $p"
done

if [[ $LIST_ONLY -eq 1 ]]; then
    note "--list-only active: history will not be rewritten."
fi

ask "Proceed with these paths?" || die "Aborted by user."

# Blob enumeration / chain-of-custody
declare -A BLOB_SEEN
BLOB_ROWS=()

enumerate_blobs() {
    for path in "${FINAL_PATHS[@]}"; do
        while IFS=' ' read -r sha rest; do
            [[ -z "$sha" ]] && continue
            if [[ -z "${BLOB_SEEN[$sha]:-}" ]]; then
                size=$(git cat-file -s "$sha" 2>/dev/null || echo "?")
                BLOB_SEEN["$sha"]="$path|$size"
                BLOB_ROWS+=("$sha|$size|$path")
            fi
        done < <(git rev-list --objects --all | awk -v tgt="$path" '$2==tgt')
    done
}

if [[ $SKIP_SIZE_SCAN -eq 0 ]]; then
    note "Enumerating blob objects (may take time)..."
    enumerate_blobs
    printf "\n%-12s %-10s %s\n" "SIZE(bytes)" "SHA" "PATH"
    for row in "${BLOB_ROWS[@]}"; do
        IFS='|' read -r sha sz path <<<"$row"
        printf "%-12s %-10.10s %s\n" "$sz" "$sha" "$path"
    done
    echo "Unique blob count: ${#BLOB_ROWS[@]}"
    ask "Continue after blob review?" || die "Aborted after blob enumeration."
else
    note "Skipping blob size scan (--skip-size-scan)"
fi

if [[ $LIST_ONLY -eq 1 ]]; then
    log "List-only enumeration complete."
    if [[ $JSON_SUMMARY -eq 1 ]]; then
        if command -v jq >/dev/null; then
            jq -n --arg branch "$BRANCH" \
                --arg mode "list-only" \
                --argjson path_count "${#FINAL_PATHS[@]}" \
                --argjson blob_count "${#BLOB_ROWS[@]}" \
                --argjson paths "$(printf '%s\n' "${FINAL_PATHS[@]}" | jq -R . | jq -s .)" \
                '{branch:$branch, mode:$mode, paths:$paths, path_count:$path_count, blob_count:$blob_count}'
        else
            warn "jq not found; JSON summary skipped."
        fi
    fi
    exit 0
fi

# Construct filter-repo command
FILTER_ARGS=()
for p in "${FINAL_PATHS[@]}"; do
    FILTER_ARGS+=(--path "$p")
done
FILTER_ARGS+=(--invert-paths)

if [[ $PRINT_COMMAND -eq 1 || $DRY_RUN -eq 1 ]]; then
    note "git filter-repo command:"
    printf '  %q' git filter-repo "${FILTER_ARGS[@]}"
    echo
fi

if [[ $DRY_RUN -eq 1 ]]; then
    warn "Dry run: no rewrite performed."
    if [[ $JSON_SUMMARY -eq 1 ]]; then
        if command -v jq >/dev/null; then
            jq -n --arg branch "$BRANCH" --arg mode "dry-run" \
                --argjson path_count "${#FINAL_PATHS[@]}" \
                --argjson paths "$(printf '%s\n' "${FINAL_PATHS[@]}" | jq -R . | jq -s .)" \
                '{branch:$branch, mode:$mode, paths:$paths, path_count:$path_count}'
        else
            warn "jq not found; JSON summary skipped."
        fi
    fi
    exit 0
fi

# Safety tag
if [[ -z "$BACKUP_TAG" ]]; then
    BACKUP_TAG="pre-secret-purge-$(date -u +%Y%m%dT%H%M%SZ)"
fi
log "Creating safety tag: $BACKUP_TAG"
git tag "$BACKUP_TAG"

ask "Execute history rewrite now?" || die "Aborted before git-filter-repo."

log "Running git-filter-repo..."
git filter-repo "${FILTER_ARGS[@]}"

log "Expiring reflogs & running aggressive gc"
git reflog expire --expire=now --all || true
git gc --prune=now --aggressive || true

# Verification
REMOVED_COUNT=0
if [[ $DO_VERIFY -eq 1 ]]; then
    note "Verifying removal..."
    FAIL=0
    for p in "${FINAL_PATHS[@]}"; do
        if git log --name-only --all | grep -F -q "$p"; then
            echo "${RED}STILL PRESENT:${RESET} $p"
            FAIL=1
        else
            echo "${GREEN}REMOVED:${RESET} $p"
            ((REMOVED_COUNT++))
        fi
    done
    [[ $FAIL -eq 0 ]] || die "Verification failed (one or more paths remain)."
else
    warn "Skipping verification (--no-verify)"
fi

# Token scan
TOKEN_FINDINGS=0
if [[ $TOKEN_SCAN -eq 1 ]]; then
    note "Scanning for obvious GitHub token patterns (ghp_, github_pat_)"
    set +e
    hits=$(git grep -I -n -E 'ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]+' 2>/dev/null)
    rc=$?
    set -e
    if [[ $rc -ne 0 || -z "$hits" ]]; then
        log "No basic token patterns found."
    else
        warn "Potential token patterns still present:"
        echo "$hits" | sed 's/^/  /'
        TOKEN_FINDINGS=$(printf "%s\n" "$hits" | wc -l | tr -d ' ')
    fi
else
    warn "Skipping token scan (--no-scan)"
fi

# Push
if [[ $DO_PUSH -eq 1 ]]; then
    ask "Force push rewritten branch '$BRANCH'?" || die "Aborted before push."
    if [[ "$FORCE_MODE" == "force" ]]; then
        warn "Using HARD force push."
        git push origin "+${BRANCH}"
    else
        log "Using --force-with-lease."
        git push --force-with-lease origin "${BRANCH}"
    fi
    log "Push complete."
else
    warn "Skipping push (--skip-push)"
fi

log "Done. Instruct collaborators to:"
echo "  git fetch origin"
echo "  git checkout ${BRANCH}"
echo "  git reset --hard origin/${BRANCH}"
echo "  git gc --prune=now"

# JSON summary
if [[ $JSON_SUMMARY -eq 1 ]]; then
    if command -v jq >/dev/null; then
        jq -n \
            --arg branch "$BRANCH" \
            --arg backup_tag "$BACKUP_TAG" \
            --arg force_mode "$FORCE_MODE" \
            --arg pushed "$([[ $DO_PUSH -eq 1 ]] && echo true || echo false)" \
            --argjson path_count "${#FINAL_PATHS[@]}" \
            --argjson removed_count "$REMOVED_COUNT" \
            --argjson token_findings "$TOKEN_FINDINGS" \
            --argjson paths "$(printf '%s\n' "${FINAL_PATHS[@]}" | jq -R . | jq -s .)" \
            '{
        branch:$branch,
        backup_tag:$backup_tag,
        force_mode:$force_mode,
        pushed:($pushed=="true"),
        paths:$paths,
        path_count:$path_count,
        removed_verified:$removed_count,
        token_findings:$token_findings
      }'
    else
        warn "jq not found; JSON summary skipped."
    fi
fi
