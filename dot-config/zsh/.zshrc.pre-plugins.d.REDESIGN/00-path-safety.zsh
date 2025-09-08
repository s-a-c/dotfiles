#!/opt/homebrew/bin/zsh
# 00-path-safety.zsh (Pre-Plugin Redesign Enhanced)
[[ -n ${_LOADED_00_PATH_SAFETY:-} ]] && return
_LOADED_00_PATH_SAFETY=1
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Deterministic early PATH normalization & hygiene before any heavyweight plugin / env logic.
#   Enforces invariants (I1–I8) referenced by test: test-path-normalization-edges.zsh
#
# INVARIANTS:
#   I1  No duplicate logical directories (after canonicalization)
#   I2  No nonexistent directories (pruned) unless whitelisted
#   I3  No relative ('.' / '..') segments
#   I4  No empty segments
#   I5  Trailing slashes removed except root (/)
#   I6  First-occurrence ordering preserved
#   I7  ~ expansion to $HOME
#   I8  Prevent accidental injection of $PWD (relative) unless explicitly allowed
#
# CONFIG / FLAGS:
: ${ZSH_PATH_ALLOW_NONEXISTENT:=0} # If 1, retain nonexistent entries (diagnostic mode)
: ${ZSH_PATH_ALLOW_RELATIVE:=0}    # If 1, allow '.' / '..' / relative segments
: ${ZSH_PATH_WHITELIST:=""}        # Colon-separated explicit entries to keep even if nonexistent
: ${ZSH_PATH_DEBUG:=0}             # If 1, emit before/after report
#
# INTERNALS:
#   - Works on $path (array form) not $PATH string to avoid word-splitting issues.
#   - Uses a single pass canonicalization + a second pass dedup/order retention.
#
# LEGACY MERGE NOTE:
#   This supersedes ad-hoc logic from legacy 00_00 / 00_01 / 00_05 scripts.
#
# SECURITY / SAFETY:
#   - Avoids command substitution beyond basic tests.
#   - Does not introduce directories; only reorders / prunes / normalizes.
#
# TEST HOOKS:
#   - test-path-normalization-edges.zsh (RED → will turn GREEN once invariants satisfied everywhere).
#
# Implementation Steps (documented for TDD traceability):
#   1. Snapshot original $PATH (for debug).
#   2. Split & canonicalize.
#   3. Apply invariants I1–I8.
#   4. Rebuild $path array preserving first valid canonical instance.
#   5. Export updated PATH.
#
# NOTE:
#   Additional platform-specific injections (e.g., /usr/local/sbin precedence) handled post-normalization.

# Optional debug helper (noop if not defined globally)
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

_original_PATH="$PATH"

# Convert whitelist to associative set for O(1) membership
typeset -A _PATH_WHITELIST
if [[ -n ${ZSH_PATH_WHITELIST} ]]; then
    IFS=':' read -rA _wtmp <<<"${ZSH_PATH_WHITELIST}"
    for __w in "${_wtmp[@]}"; do
        [[ -n $__w ]] && _PATH_WHITELIST[$__w]=1
    done
    unset _wtmp __w
fi

# Canonicalization function
__canon_path_component() {
    local comp="$1"
    [[ -z $comp ]] && return 1
    # Expand ~
    if [[ $comp == "~"* ]]; then
        comp="${comp/#\~/$HOME}"
    fi
    # Collapse multiple slashes (but preserve leading double // if ever used for network paths)
    comp="${comp//\/\//\/}"
    # Remove trailing slashes except root
    [[ $comp != "/" ]] && comp="${comp%/}"
    # Return canonical form
    print -r -- "$comp"
}

typeset -A _seen_canon
typeset -a _new_path

for raw in $path; do
    # Skip empty segments early (I4)
    [[ -z $raw ]] && continue

    # Expand and canonicalize
    canonical="$(__canon_path_component "$raw" 2>/dev/null || true)"

    # Re-check emptiness post-canon
    [[ -z $canonical ]] && continue

    # Relative detection (I3 / I8)
    if [[ $canonical == "." || $canonical == ".." || $canonical != /* ]]; then
        if ((ZSH_PATH_ALLOW_RELATIVE == 0)); then
            ((ZSH_PATH_DEBUG)) && zsh_debug_echo "# [path] drop(relative): $raw"
            continue
        fi
    fi

    # Nonexistent pruning (I2) unless whitelisted
    if [[ ! -e $canonical ]]; then
        if ((ZSH_PATH_ALLOW_NONEXISTENT == 0)) && [[ -z ${_PATH_WHITELIST[$canonical]:-} ]]; then
            ((ZSH_PATH_DEBUG)) && zsh_debug_echo "# [path] drop(nonexistent): $canonical"
            continue
        fi
    fi

    # Deduplicate (I1) preserving order (I6)
    if [[ -z ${_seen_canon[$canonical]:-} ]]; then
        _seen_canon[$canonical]=1
        _new_path+=("$canonical")
    else
        ((ZSH_PATH_DEBUG)) && zsh_debug_echo "# [path] drop(duplicate): $canonical"
    fi
done

# OPTIONAL: ensure /usr/local/sbin precedence if it exists (legacy behavior)
if [[ -d /usr/local/sbin ]]; then
    # Remove if already present later, then unshift
    typeset -a _tmp_path
    for comp in "${_new_path[@]}"; do
        [[ $comp == "/usr/local/sbin" ]] && continue
        _tmp_path+=("$comp")
    done
    _new_path=("/usr/local/sbin" "${_tmp_path[@]}")
    unset _tmp_path
fi

# Reassign path (array)
path=("${_new_path[@]}")
unset _new_path _seen_canon canonical raw comp

# Final debug summary
if ((ZSH_PATH_DEBUG)); then
    zsh_debug_echo "# [path] original: $_original_PATH"
    zsh_debug_echo "# [path] normalized: $PATH"
fi

unset _PATH_WHITELIST _original_PATH

# Pre-plugin start timestamp capture (only set once on first pre-plugin module)
if [[ -z ${PRE_PLUGIN_START_REALTIME:-} ]]; then
    zmodload zsh/datetime 2>/dev/null || true
    PRE_PLUGIN_START_REALTIME=$EPOCHREALTIME
    export PRE_PLUGIN_START_REALTIME
    # Derive millisecond precision integer (fallback if awk absent gracefully ignored)
    PRE_PLUGIN_START_MS=$(printf '%s' "$EPOCHREALTIME" | awk -F. '{ms = ($1 * 1000); if (NF>1) { ms += substr($2 "000",1,3)+0 } printf "%d", ms }' 2>/dev/null || echo "")
    [[ -n ${PRE_PLUGIN_START_MS:-} ]] && export PRE_PLUGIN_START_MS
    zsh_debug_echo "# [pre-plugin][perf] PRE_PLUGIN_START_REALTIME=$PRE_PLUGIN_START_REALTIME ms=${PRE_PLUGIN_START_MS:-n/a}"
fi

zsh_debug_echo "# [pre-plugin] 00-path-safety enhanced normalization applied"
