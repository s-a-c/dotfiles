#!/usr/bin/env bash
# enforce-tdd.sh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# Purpose:
#   Lightweight heuristic gate (G10) to enforce Test-Driven Development discipline.
#   Scans recent commits to ensure functional (non-test) module changes are
#   preceded by a related test-only commit that establishes / updates failing or
#   missing tests for the same logical module.
#
# Heuristics (intentionally simple, fast, no external deps except git):
#   1. "Test-only commit": ALL changed paths are inside a tests/ directory (contain '/tests/')
#      or match *test*.zsh (to allow ad-hoc single-file additions under new dirs).
#   2. "Functional commit": Any commit with at least one changed path NOT classified as test path.
#   3. Module Name Extraction (Functional):
#        - For changed module files under:
#            .zshrc.pre-plugins.d.REDESIGN/*.zsh
#            .zshrc.d.REDESIGN/*.zsh
#            tools/*.zsh  (infrastructure scripts that may need tests)
#        - Base name stripped of extension + numeric prefix (e.g. "00-path-safety.zsh" → "path-safety").
#   4. Module Tokens (Test commit):
#        - From each changed test filename: split on [-_./] and keep tokens length ≥3 (to reduce noise).
#        - Also record entire test filename stem.
#   5. Coverage Condition:
#        For each functional commit & each of its module base names:
#          - There MUST exist a prior (earlier in history) test-only commit within a
#            configurable window (default 15 commits) where:
#              * A test token is a substring of the module name OR
#              * The module name is a substring of a test token OR
#              * Commit message of the test commit contains the module name
#          - AND there is no OTHER functional commit for that module name between the test commit
#            and the current functional commit (prevents re-using stale test commits).
#
# Exit Codes:
#   0  Success (all functional commits covered)
#   10 Not a git repository
#   11 Git not available
#   12 Violations detected
#   13 Usage / argument error
#
# Options:
#   -n <N> / --window <N>    Number of recent commits to analyze (default: 50)
#   -w <W> / --distance <W>  Max commit distance allowed between test and functional (default: 15)
#   --json                   Emit JSON report to stdout
#   --since-ref <ref>        Use commits since (exclusive) given ref instead of fixed count
#   --help                   Show help
#
# Notes:
#   - This is a heuristic aid, not a formal proof of TDD. It is meant to raise
#     friction when a pattern of "code before test" emerges.
#   - A single commit that adds both tests and code is considered SELF-COVERED.
#   - Future enhancements could integrate diff-based semantic mapping or coverage traces.
#
# Example:
#   tools/enforce-tdd.sh -n 80 --json
#
set -euo pipefail

script_name="${0##*/}"

die() {
    echo "[$script_name] $*" >&2
    exit "${2:-13}"
}

command -v git >/dev/null 2>&1 || die "git not found in PATH" 11
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not inside a git repository" 10

WINDOW=50
DISTANCE=15
JSON=0
SINCE_REF=""
ARGS=()

print_help() {
    cat <<EOF
$script_name - Heuristic TDD enforcement (Gate G10)

Usage:
  $script_name [options]

Options:
  -n, --window <N>       Number of recent commits to scan (default: 50)
  -w, --distance <N>     Max allowed commit distance between test and functional (default: 15)
  --since-ref <ref>      Analyze commits since (exclusive) a given ref instead of fixed window
  --json                 Output JSON report
  --help                 Show this help

Exit codes:
  0  All functional commits covered by preceding test commits
  10 Not a git repository
  11 git missing
  12 Violations found
  13 Usage error

Heuristic Summary:
  Ensures each functional commit touching redesign modules or tools is preceded
  (or self-contained) with a related test-only commit that references same module.

EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    -n | --window)
        WINDOW="${2:-}"
        shift 2 || die "Missing value for --window"
        ;;
    -w | --distance)
        DISTANCE="${2:-}"
        shift 2 || die "Missing value for --distance"
        ;;
    --since-ref)
        SINCE_REF="${2:-}"
        shift 2 || die "Missing value for --since-ref"
        ;;
    --json)
        JSON=1
        shift
        ;;
    --help)
        print_help
        exit 0
        ;;
    *)
        ARGS+=("$1")
        shift
        ;;
    esac
done

[[ ${#ARGS[@]} -eq 0 ]] || die "Unexpected argument(s): ${ARGS[*]} (see --help)" 13
[[ "$WINDOW" =~ ^[0-9]+$ ]] || die "Window must be integer" 13
[[ "$DISTANCE" =~ ^[0-9]+$ ]] || die "Distance must be integer" 13

# Acquire commit list
if [[ -n $SINCE_REF ]]; then
    git rev-parse --verify "$SINCE_REF" >/dev/null 2>&1 || die "since-ref '$SINCE_REF' not found" 13
    commits_raw=$(git log --reverse --name-only --pretty=format:'---%H%n%s' "$SINCE_REF"..HEAD)
else
    commits_raw=$(git log -n "$WINDOW" --reverse --name-only --pretty=format:'---%H%n%s')
fi

# Data structures
# Arrays of commit hashes in chronological order (oldest → newest)
declare -a commits subjects
declare -A commit_index
declare -A is_test_only is_functional self_covered
declare -A commit_files
declare -A module_last_test_commit # module -> commit hash of last covering test
declare -A module_last_functional_commit
declare -A violations_for_commit # commit hash -> aggregated violation messages (string)

# Helper: classify path
is_test_path() {
    local f="$1"
    [[ "$f" == *"/tests/"* || "$f" == tests/* || "$f" == *test*.zsh ]]
}

# Helper: extract module name from filename
# Strips numeric prefix (e.g. 00-, 05-) and .zsh extension
extract_module_name() {
    local b="${1##*/}"
    b="${b%.zsh}"
    b="${b#[0-9][0-9]-}" # remove leading NN-
    echo "$b"
}

# Parse commits
current_hash=""
current_subject=""
current_files=()

while IFS= read -r line; do
    if [[ "$line" == ---* ]]; then
        # flush previous
        if [[ -n $current_hash ]]; then
            commits+=("$current_hash")
            subjects+=("$current_subject")
            commit_index["$current_hash"]=$((${#commits[@]} - 1))
            commit_files["$current_hash"]="$(printf '%s\n' "${current_files[@]}")"
        fi
        current_hash="${line#---}"
        IFS= read -r current_subject || current_subject=""
        current_files=()
    elif [[ -n $current_hash ]]; then
        [[ -z "$line" ]] && continue
        current_files+=("$line")
    fi
done <<<"$commits_raw"

# Flush last
if [[ -n $current_hash ]]; then
    commits+=("$current_hash")
    subjects+=("$current_subject")
    commit_index["$current_hash"]=$((${#commits[@]} - 1))
    commit_files["$current_hash"]="$(printf '%s\n' "${current_files[@]}")"
fi

# Classification
for i in "${!commits[@]}"; do
    h="${commits[$i]}"
    files="${commit_files[$h]}"
    # Skip merge commits quickly
    if [[ -z "$files" ]]; then
        is_test_only["$h"]=0
        is_functional["$h"]=0
        continue
    fi
    local_all_test=1
    local_has_non_test=0
    while IFS= read -r f; do
        [[ -z $f ]] && continue
        if is_test_path "$f"; then
            :
        else
            local_all_test=0
            local_has_non_test=1
        fi
    done <<<"$files"
    if ((local_all_test == 1)); then
        is_test_only["$h"]=1
    else
        is_test_only["$h"]=0
    fi
    if ((local_has_non_test == 1)); then
        is_functional["$h"]=1
    else
        is_functional["$h"]=0
    fi
    # Self covered if commit has BOTH test paths and non-test (mixed)
    if ((is_functional["$h"] == 1)) && ((is_test_only["$h"] == 0)); then
        # Determine if there is at least one test file in the set
        has_test=0
        while IFS= read -r f; do
            [[ -z $f ]] && continue
            if is_test_path "$f"; then
                has_test=1
                break
            fi
        done <<<"$files"
        self_covered["$h"]=$has_test
    else
        self_covered["$h"]=0
    fi
done

# Build test token sets and process coverage
declare -A test_commit_tokens # commit hash -> space-delimited tokens

tokenize_test_file() {
    local f="$1"
    local base="${f##*/}"
    base="${base%.*}"
    # Split on delimiters
    echo "$base" | tr '._/-' ' ' | awk 'length($0)>=3 {print}'
}

# Iterate chronological
for i in "${!commits[@]}"; do
    h="${commits[$i]}"
    subj="${subjects[$i]}"
    files="${commit_files[$h]}"

    if ((is_test_only["$h"] == 1)); then
        # Collect tokens
        tokens=()
        while IFS= read -r f; do
            [[ -z $f ]] && continue
            if is_test_path "$f"; then
                while IFS= read -r tk; do
                    tokens+=("$tk")
                done < <(tokenize_test_file "$f")
            fi
        done <<<"$files"
        # Also add module-like words from subject
        while IFS= read -r tk; do
            [[ ${#tk} -ge 3 ]] && tokens+=("$tk")
        done < <(echo "$subj" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' ' ')

        # Deduplicate
        declare -A seen_tok=()
        final_tokens=()
        for t in "${tokens[@]}"; do
            t_l=$(echo "$t" | tr '[:upper:]' '[:lower:]')
            [[ -z $t_l ]] && continue
            [[ -n ${seen_tok[$t_l]:-} ]] && continue
            seen_tok[$t_l]=1
            final_tokens+=("$t_l")
        done
        test_commit_tokens["$h"]="${final_tokens[*]}"

        # Update last test mapping opportunistically: we don't yet know which modules,
        # so we defer until functional commits reference them (will scan back).
    fi

    if ((is_functional["$h"] == 1)); then
        # Gather module names for this functional commit
        modules=()
        while IFS= read -r f; do
            [[ -z $f ]] && continue
            case "$f" in
            .zshrc.pre-plugins.d.REDESIGN/*.zsh | .zshrc.d.REDESIGN/*.zsh | tools/*.zsh)
                mod=$(extract_module_name "$f" | tr '[:upper:]' '[:lower:]')
                [[ -n $mod ]] && modules+=("$mod")
                ;;
            esac
        done <<<"$files"

        # Skip if no tracked modules (e.g., only docs or other)
        ((${#modules[@]} == 0)) && continue

        # Self-covered commit with tests included passes automatically
        if ((self_covered["$h"] == 1)); then
            continue
        fi

        # For each module determine if there exists a suitable prior test-only commit
        for mod in "${modules[@]}"; do
            covered=0
            # Traverse backwards up to distance cap
            search_start=$((i - 1))
            lower_bound=$((i - DISTANCE))
            ((lower_bound < 0)) && lower_bound=0
            for ((j = search_start; j >= lower_bound; j--)); do
                prev_hash="${commits[$j]}"
                # If we encounter another functional commit touching same module before a test commit, we break (stale tests).
                if ((is_functional["$prev_hash"] == 1)); then
                    # Did it touch same module?
                    prev_files="${commit_files[$prev_hash]}"
                    touched_same=0
                    while IFS= read -r pf; do
                        [[ -z $pf ]] && continue
                        case "$pf" in
                        .zshrc.pre-plugins.d.REDESIGN/*.zsh | .zshrc.d.REDESIGN/*.zsh | tools/*.zsh)
                            pmod=$(extract_module_name "$pf" | tr '[:upper:]' '[:lower:]')
                            [[ $pmod == "$mod" ]] && {
                                touched_same=1
                                break
                            }
                            ;;
                        esac
                    done <<<"$prev_files"
                    if ((touched_same == 1)); then
                        # Stale test chain broken
                        break
                    fi
                fi
                # Consider only test-only commits
                if ((is_test_only["$prev_hash"] == 1)); then
                    tokens="${test_commit_tokens[$prev_hash]:-}"
                    # Quick token search
                    subj_prev="${subjects[$j],,}"
                    if [[ -n $tokens ]]; then
                        for tk in $tokens; do
                            if [[ "$mod" == *"$tk"* || "$tk" == *"$mod"* ]]; then
                                covered=1
                                module_last_test_commit["$mod"]="$prev_hash"
                                break
                            fi
                        done
                    fi
                    # Subject fallback
                    if ((covered == 0)) && [[ "$subj_prev" == *"$mod"* ]]; then
                        covered=1
                        module_last_test_commit["$mod"]="$prev_hash"
                    fi
                    ((covered == 1)) && break
                fi
            done

            if ((covered == 0)); then
                violations_for_commit["$h"]+="${violations_for_commit[$h]:+; }module '$mod' lacks preceding test commit (distance≤${DISTANCE})"
            else
                module_last_functional_commit["$mod"]="$h"
            fi
        done
    fi
done

# Prepare report
violations_total=0
for h in "${commits[@]}"; do
    if [[ -n ${violations_for_commit[$h]:-} ]]; then
        ((violations_total++))
    fi
done

if ((JSON == 1)); then
    printf '{\n'
    printf '  "window": %d,\n' "$WINDOW"
    printf '  "distance_limit": %d,\n' "$DISTANCE"
    printf '  "commit_count": %d,\n' "${#commits[@]}"
    printf '  "violations": [\n'
    first=1
    for h in "${commits[@]}"; do
        v="${violations_for_commit[$h]:-}"
        [[ -z $v ]] && continue
        if ((first)); then first=0; else printf ',\n'; fi
        subj="${subjects[${commit_index[$h]}]}"
        # Escape quotes
        esc_v=${v//\"/\\\"}
        esc_subj=${subj//\"/\\\"}
        printf '    {"commit":"%s","subject":"%s","details":"%s"}' "$h" "$esc_subj" "$esc_v"
    done
    printf '\n  ],\n'
    printf '  "violation_count": %d,\n' "$violations_total"
    printf '  "status": "%s"\n' $((violations_total == 0)) && echo "pass" || echo "fail"
    printf '}\n'
else
    echo "TDD Enforcement Report (window=${WINDOW}, distance=${DISTANCE})"
    echo "----------------------------------------------------------------"
    if ((violations_total == 0)); then
        echo "OK: All functional commits within scope have preceding/self tests (heuristic pass)."
    else
        echo "Violations:"
        for h in "${commits[@]}"; do
            v="${violations_for_commit[$h]:-}"
            [[ -z $v ]] && continue
            subj="${subjects[${commit_index[$h]}]}"
            echo "  - Commit: $h"
            echo "    Subject: $subj"
            IFS=';' read -r -a parts <<<"$v"
            for part in "${parts[@]}"; do
                echo "    * ${part# }"
            done
        done
    fi
fi

if ((violations_total > 0)); then
    exit 12
fi
exit 0
