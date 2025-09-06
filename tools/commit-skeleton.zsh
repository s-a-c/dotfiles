#!/usr/bin/env zsh
# commit-skeleton.zsh
# Generate a suggested branch name, git add, and commit command(s) for a redesign task.
# It parses docs/redesign/planning/implementation-plan.md TDD & Git matrix.
#
# Usage:
#     tools/commit-skeleton.zsh <task-id-or-keyword> [--type <feat|refactor|chore|docs|ci|test|perf>] [--dry]
# Examples:
#     tools/commit-skeleton.zsh 5
#     tools/commit-skeleton.zsh "Phase 2" --type refactor
#     tools/commit-skeleton.zsh promotion --dry
#
# Output: Suggested commands (never runs git unless you pipe | sh manually).
# Safe: Read-only; does not modify repository.
set -euo pipefail

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
PLAN_FILE="$ROOT_DIR/docs/redesign/planning/implementation-plan.md"
[[ -f $PLAN_FILE ]] || { echo "[commit-skeleton] Plan file not found: $PLAN_FILE" >&2; exit 1; }

task_query="${1:-}" || true
[[ -z $task_query ]] && { echo "Usage: $0 <task-id-or-keyword> [--type TYPE] [--dry]" >&2; exit 1; }
shift || true

custom_type=""
dry=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            custom_type="$2"; shift 2 ;;
        --dry)
            dry=1; shift ;;
        *)
            echo "[commit-skeleton] Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Normalize query (strip brackets if someone passes [5])
q_norm=${task_query//[/}
q_norm=${q_norm//]/}

# Function: extract matching matrix row (Section 1A table)
# We identify rows that start with a literal pipe then optional space and a number or bracketed number in column 2.
row=$(awk -v q="$q_norm" 'BEGIN{FS="|"; OFS="|"} /^\|/ { # candidate row
    # columns: $1 empty (leading pipe), $2 id (maybe bracketed), $3 scope summary, last col git cmds
    id=$2; gsub(/^[ \[]+|[] ]+$/,"",id);
    if (id==q || tolower($3) ~ tolower(q)) {print; exit}
}' "$PLAN_FILE") || true

if [[ -z $row ]]; then
    echo "[commit-skeleton] No task row matched query: $task_query" >&2
    exit 2
fi

# Parse fields
IFS='|' read -r _col0 col_id col_scope col_tdd _mid1 _mid2 col_git <<<"$row"
# Clean up
col_id=${col_id//[[]/}
col_id=${col_id//]/}
col_id=${col_id// /}
col_scope=$(echo $col_scope | sed 's/^ *//; s/ *$//')
col_git=$(echo $col_git | sed 's/^ *//; s/ *$//')

# Derive default commit type from row content if not provided
if [[ -z $custom_type ]]; then
    if [[ $col_git == *"feat("* ]]; then custom_type="feat";
    elif [[ $col_git == *"refactor("* ]]; then custom_type="refactor";
    elif [[ $col_git == *"chore("* ]]; then custom_type="chore";
    elif [[ $col_git == *"docs("* ]]; then custom_type="docs";
    elif [[ $col_git == *"ci:"* || $col_git == *"ci("* ]]; then custom_type="ci";
    elif [[ $col_git == *"test("* ]]; then custom_type="test";
    else custom_type="chore"; fi
fi

# Suggested scope: derive from scope summary (first word lowercased, strip punctuation)
scope_guess=$(echo "$col_scope" | awk '{print tolower($1)}' | sed 's/[^a-z0-9_-]//g')
[[ -z $scope_guess ]] && scope_guess="refactor"

branch_base() {
    local id="$1"; local s="$2"; echo "$custom_type/${id}-${s}" | tr ' ' '-' | tr -cs 'a-zA-Z0-9_-/.' '-'
}
branch_name=$(branch_base "$col_id" "$scope_guess")

# Expand git commands column into multi-line suggestions; preserve original but also offer generic fallback.
# col_git may already contain full commands separated by semicolons.
IFS=';' read -A steps <<<"$col_git"

print_header() {
    echo "# Commit Skeleton for Task $col_id"
    echo "# Scope: $col_scope"
    echo "# Detected Type: $custom_type"
    echo "# Branch: $branch_name"
    echo
}

print_steps() {
    echo "# Suggested Steps"
    echo "git checkout -b $branch_name"
    # Provide placeholder add if not explicit
    local has_add=0 has_commit=0
    for s in "${steps[@]}"; do
        s_trim=$(echo $s | sed 's/^ *//; s/ *$//')
        [[ -z $s_trim ]] && continue
        echo "# From matrix: $s_trim"
        [[ $s_trim == git\ add* ]] && has_add=1
        [[ $s_trim == git\ commit* ]] && has_commit=1
    done
    if (( ! has_add )); then
        echo "git add <paths>"
    fi
    commit_msg="$custom_type($scope_guess): $col_scope"
    if (( ! has_commit )); then
        echo "git commit -m \"$commit_msg\""
    fi
    echo "git push -u origin $branch_name"
    echo
    echo "# Alternate (amend after staged changes)"
    echo "# git commit --amend --no-edit"
}

print_message_template() {
    echo "# Commit Message Template"
    echo "$custom_type($scope_guess): $col_scope"
    echo
    echo "# Body (why / what / how)"
    echo "# - Context:"
    echo "# - Changes:"
    echo "# - Validation: tests pass, perf threshold unaffected"
    echo
    echo "# Footer (issues / refs)"
    echo "# Ref: task-$col_id"
}

print_header
print_steps
print_message_template

if (( dry )); then
    exit 0
fi

# Offer quick copy helper
cat <<EOF
# To create branch & initial commit skeleton (edit paths first):
#     tools/commit-skeleton.zsh $task_query --dry | sed 's/^# //' > /dev/null
EOF
