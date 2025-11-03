#!/usr/bin/env zsh
# test-path-normalization-edges.zsh
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Placeholder (intentional failing) unit-style test capturing *edge case* PATH normalization
#   requirements for Stage 2 migration (TDD Gate G10). This test enumerates desired invariants
#   that are NOT yet fully implemented in `00-path-safety.zsh`.
#
# STATUS:
#   ACTIVE: Test passes when all invariants are satisfied; fails listing violations otherwise.
#
# DISABLING (temporary / local only):
#   Export TDD_ALLOW_FAIL_PATH_EDGES=1 to convert current failure into SKIP (never commit with it set).
#
# SCOPE:
#   Focuses on *pre-plugin* PATH canonicalization performed in `.zshrc.pre-plugins.d.REDESIGN/00-path-safety.zsh`.
#
# INVARIANTS (Target Behavior):
#   I1  No duplicate logical directories (tolerant of trailing slashes)              (/usr/local/bin == /usr/local/bin/)
#   I2  No directories that do not exist (prune nonexistent entries unless explicitly whitelisted)
#   I3  No relative path segments ('.', '..') – all entries absolute
#   I4  No redundant empty segments (caused by consecutive colons ::)
#   I5  Collapse superfluous trailing slashes except for root (/)
#   I6  Preserve first-occurrence ordering for unique directories after normalization
#   I7  Home expansion: leading ~ in entries becomes absolute $HOME form
#   I8  Prevent accidental injection of $PWD (relative) unless policy explicitly allows
#
# TEST STRATEGY:
#   1. Construct a controlled PATH fixture with deliberate violations.
#   2. Spawn a subshell sourcing `.zshenv` + `00-path-safety.zsh` (isolated) with injected PATH.
#   3. Capture resulting PATH and evaluate invariants.
#   4. Fail fast on first unmet invariant; list summary at end.
#
# NOTE:
#   This test intentionally fails RIGHT NOW (TDD "RED" phase) because the current implementation
#   only performs simple dedup by textual match and does not:
#     - Normalize trailing slashes
#     - Remove nonexistent dirs
#     - Expand ~
#     - Remove relative entries
#
# FUTURE IMPROVEMENT:
#   Split each invariant into its own granular test file once the base implementation passes.
#

set -euo pipefail

# Honor project debug echo if available after sourcing
zf::debug() { :; }

# Guard: allow temporary skip (never commit with this variable exported)
if [[ "${TDD_ALLOW_FAIL_PATH_EDGES:-0}" == 1 ]]; then
  echo "SKIP: Path normalization edge test intentionally skipped (TDD_ALLOW_FAIL_PATH_EDGES=1)"
  exit 0
fi

# Locate repo root (assumes file position within dot-config/zsh tree)
if typeset -f zf::script_dir >/dev/null 2>&1; then
REPO_ROOT="$(cd "$(zf::script_dir "${(%):-%N}")/../../../.." && pwd -P)"
else
REPO_ROOT="$(cd "${(%):-%N:h}/../../../.." && pwd -P)"
fi

# Build a synthetic PATH with edge issues:
# - Duplicate via trailing slash
# - Nonexistent directory
# - Relative directory (.)
# - Empty segment
# - Home reference
# - Duplicate after normalization (~/bin vs $HOME/bin)
SYN_PATH="/usr/local/bin:/usr/local/bin/:${HOME}/bin:~/bin:.:/does/not/exist::/usr/bin:/usr//bin///:/usr/local/bin"

# Subshell executes the path safety module in isolation.
# We assume .zshenv sets ZDOTDIR etc; we short-circuit heavy plugin sourcing by not invoking full login.
RESULT_PATH="$(
  PATH="$SYN_PATH" \
  ZDOTDIR="$REPO_ROOT" \
  HOME="$HOME" \
  zsh -c '
    set -euo pipefail
    # Source minimal environment (if present)
    [[ -f ./.zshenv ]] && source ./.zshenv
    # Source ONLY the target path safety module (guarded)
    if [[ -f ./.zshrc.pre-plugins.d.REDESIGN/00-path-safety.zsh ]]; then
      source ./.zshrc.pre-plugins.d.REDESIGN/00-path-safety.zsh
    else
      echo "ERROR: path safety module missing" >&2
      exit 97
    fi
    print -r -- "$PATH"
  ' 2>/dev/null
)"

if [[ -z "${RESULT_PATH:-}" ]]; then
  echo "FAIL: Resulting PATH is empty or module failed to output"
  exit 1
fi

violations=()

split_path() {
  local p="$1"
  local -a parts
  parts=(${(s/:/)p})
  echo "${parts[@]}"
}

# Collect entries
original_entries=(${(s/:/)SYN_PATH})
normalized_entries=(${(s/:/)RESULT_PATH})

# Helper: normalize for comparison (collapse trailing slashes except root)
canon_entry() {
  local e="$1"
  [[ -z $e ]] && { echo ""; return; }
  # Expand ~ to $HOME (shell likely did not if literal ~ persisted)
  if [[ $e == "~"* ]]; then
    e="${e/#\~/$HOME}"
  fi
  # Remove duplicate slashes (except leading double for network paths which we don't expect)
  e="${e//\/\/*/\/}"
  # Remove trailing slash except root
  [[ $e != "/" ]] && e="${e%/}"
  echo "$e"
}

# I1 & I5 & I7: Detect duplicates after canonical normalization
typeset -A seen
for entry in "${normalized_entries[@]}"; do
  [[ -z $entry ]] && continue
  ce=$(canon_entry "$entry")
  if [[ -n ${seen[$ce]:-} ]]; then
    violations+="+ Duplicate logical directory after normalization: $ce"
  else
    seen[$ce]=1
  fi
done

# I2: Nonexistent directories should be removed
for bad in "/does/not/exist"; do
  if [[ "$RESULT_PATH" == *"$bad"* ]]; then
    violations+="+ Nonexistent directory retained: $bad"
  fi
done

# I3: Relative segments '.' or '..' should not remain
if [[ "$RESULT_PATH" == *":.:"* || "$RESULT_PATH" == .*":" || "$RESULT_PATH" == *":." || "$RESULT_PATH" == "." ]]; then
  violations+="+ Relative '.' segment present"
fi
if [[ "$RESULT_PATH" == *"..:"* || "$RESULT_PATH" == *":.."* || "$RESULT_PATH" == ".." ]]; then
  violations+="+ Relative '..' segment present"
fi

# I4: Empty segments (leading, trailing, or ::) should be eliminated
if [[ "$RESULT_PATH" == *"::"* || "$RESULT_PATH" == :*:* || "$RESULT_PATH" == *: || "$RESULT_PATH" == :* ]]; then
  # Check precisely by splitting
  for e in "${normalized_entries[@]}"; do
    [[ -z $e ]] && { violations+="+ Empty PATH segment remains"; break; }
  done
fi

# I6: Ordering preservation check (first occurrence of unique canonical directories)
# Build first-seen order from original (canonical)
orig_order=()
typeset -A orig_seen
for e in "${original_entries[@]}"; do
  ce=$(canon_entry "$e")
  [[ -z $ce ]] && continue
  if [[ -z ${orig_seen[$ce]:-} ]]; then
    orig_seen[$ce]=1
    orig_order+="$ce"
  fi
done

norm_order=()
typeset -A norm_seen
for e in "${normalized_entries[@]}"; do
  ce=$(canon_entry "$e")
  [[ -z $ce ]] && continue
  if [[ -z ${norm_seen[$ce]:-} ]]; then
    norm_seen[$ce]=1
    norm_order+="$ce"
  fi
done

# Compare ordering up to length of norm_order (since legitimate pruning can reduce size)
for ((i=1; i<=${#norm_order[@]}; i++)); do
  if [[ "${norm_order[$i]}" != "${orig_order[$i]}" ]]; then
    violations+="+ Ordering drift at position $i: expected '${orig_order[$i]}' got '${norm_order[$i]}'"
    break
  fi
done

# I7: Ensure any ~ forms expanded (if any survived)
if print -r -- "${normalized_entries[@]}" | grep -q '^[~]'; then
  violations+="+ Home tilde not expanded"
fi

# Final evaluation
if (( ${#violations[@]} == 0 )); then
  echo "PASS: Path normalization edge invariants satisfied"
  exit 0
fi

echo "FAIL: Path normalization edge invariants not satisfied:"
for v in "${violations[@]}"; do
  echo "  $v"
done
exit 1
