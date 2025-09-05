#!/opt/homebrew/bin/zsh
# ============================================================================
# 05-interactive-options.zsh  (Stage 3 – Post-Plugin Core Scaffold)
#
# Responsibility:
#   - Centralize interactive shell option (setopt/unsetopt) & zstyle baseline.
#   - Apply history, directory navigation, globbing, job control, and safety
#     behaviors in a single idempotent location.
#   - Provide namespaced helpers to snapshot and diff option state for tests.
#   - Reserve (but do NOT invoke) completion / compinit related semantics
#     (single compinit is enforced later in Stage 5: 50-completion-history).
#
# Non-Goals (at this stage):
#   - Running `compinit` (explicitly deferred).
#   - Prompt / theme configuration (Stage 5).
#   - Async scheduling (Stage 5/80/90 modules).
#   - Advanced completion style tuning (introduced when compinit enabled).
#
# Invariants (I*):
#   I1: File is idempotent (re-sourcing does not reapply side-effects).
#   I2: No invocation of `compinit` (enforced by guard & optional test).
#   I3: Option baseline stable; test snapshot diff after re-source is empty.
#   I4: History configuration consistent & non-destructive.
#   I5: Namespaced helpers avoid leaking global generic function names.
#
# Exported Sentinel Variables:
#   ZSH_INTERACTIVE_OPTIONS_GUARD=1
#   ZSH_INTERACTIVE_OPTIONS_VERSION=1
#   ZSH_INTERACTIVE_OPTIONS_APPLIED=1
#
# Namespaced Functions (zf:: prefix):
#   zf::opt_snapshot      -> emit current option state (normalized)
#   zf::opt_apply_baseline -> apply (idempotent) curated option set
#   zf::opt_diff_snapshots <before> <after>
#
# Anticipated Tests:
#   - test-interactive-options-idempotent.zsh
#   - test-interactive-options-no-compinit.zsh
#   - test-interactive-options-history-config.zsh
#
# Performance Budget:
#   ≤1–2ms (pure shell; no external processes)
#
# Future Extension Points:
#   - zstyle completion fine-tuning (Stage 5)
#   - shell option profiles (strict vs relaxed) toggled by env
#   - dynamic adaptation for remote / non-interactive shells
# ============================================================================

# ----------------------------------------------------------------------------
# Idempotency Guard
# ----------------------------------------------------------------------------
if [[ -n "${ZSH_INTERACTIVE_OPTIONS_GUARD:-}" ]]; then
    if [[ "${ZSH_DEBUG:-0}" == "1" ]]; then
        print -u2 "[05-interactive-options] Re-source skipped (already initialized)."
    fi
    return 0
fi
export ZSH_INTERACTIVE_OPTIONS_GUARD=1
export ZSH_INTERACTIVE_OPTIONS_VERSION=1

# Internal flag set after baseline application
: "${ZSH_INTERACTIVE_OPTIONS_APPLIED:=0}"

# ----------------------------------------------------------------------------
# Lightweight Debug Logger
# ----------------------------------------------------------------------------
zf::opt_log() {
    [[ "${ZSH_DEBUG:-0}" == "1" ]] || return 0
    print -u2 "[05-interactive-options] $*"
}

# ----------------------------------------------------------------------------
# Snapshot Helpers
#   We normalize option state to a sorted list for stable diffs.
#   setopt (without args) prints enabled options one per line.
# ----------------------------------------------------------------------------
zf::opt_snapshot() {
    # Usage: zf::opt_snapshot > file OR capture as var
    # Output: sorted list of enabled option names (uppercase)
    setopt | LC_ALL=C sort
}

# Diff two snapshots (file paths or process substitution)
zf::opt_diff_snapshots() {
    # Usage: zf::opt_diff_snapshots before.txt after.txt
    local before="$1" after="$2"
    if [[ -z "$before" || -z "$after" ]]; then
        print -u2 "zf::opt_diff_snapshots: missing args" >&2
        return 2
    fi
    # Show lines only in after (additions) and only in before (removals)
    # Format: +ADDED_OPTION / -REMOVED_OPTION
    comm -13 "$before" "$after" | sed 's/^/+/'
    comm -23 "$before" "$after" | sed 's/^/-/'
}

# ----------------------------------------------------------------------------
# Baseline Option Set
#   This is intentionally conservative. Avoid contentious flags until
#   explicitly justified (each new flag should gain a test).
#
#   Approach:
#     - Ensure safety (noclobber, no_unset optionally)
#     - History behavior (ignore dups/spaces, extended timestamps)
#     - Navigation ergonomics (autopushd)
#     - Job control & pipefail situation remain default unless required
#
#   Optional stricter profile can be enabled via: ZSH_INTERACTIVE_OPTIONS_STRICT=1
# ----------------------------------------------------------------------------
zf::opt_apply_baseline() {
    [[ "${ZSH_INTERACTIVE_OPTIONS_APPLIED}" == "1" ]] && return 0

    # Safety / correctness
    setopt NO_CLOBBER            2>/dev/null || true   # Protect files from accidental truncation
    setopt EXTENDED_HISTORY      2>/dev/null || true   # Timestamp + additional metadata
    setopt HIST_IGNORE_DUPS      2>/dev/null || true
    setopt HIST_IGNORE_ALL_DUPS  2>/dev/null || true
    setopt HIST_IGNORE_SPACE     2>/dev/null || true
    setopt HIST_REDUCE_BLANKS    2>/dev/null || true

    # Directory navigation
    setopt AUTO_PUSHD            2>/dev/null || true
    setopt PUSHD_IGNORE_DUPS     2>/dev/null || true
    setopt PUSHD_SILENT          2>/dev/null || true

    # Globbing / expansion safety (avoid surprising failures in scripts)
    # NO_NOMATCH keeps unmatched globs literal; prefer until strict mode desired.
    setopt NO_NOMATCH            2>/dev/null || true

    # Optional stricter profile
    if [[ "${ZSH_INTERACTIVE_OPTIONS_STRICT:-0}" == "1" ]]; then
        # Fail references to unset parameters
        setopt NO_UNSET            2>/dev/null || true
        # Disallow ambiguous redirects (older zsh)
        setopt APPEND_HISTORY      2>/dev/null || true
    fi

    export ZSH_INTERACTIVE_OPTIONS_APPLIED=1
    zf::opt_log "Baseline options applied (strict=${ZSH_INTERACTIVE_OPTIONS_STRICT:-0})."
}

zf::opt_apply_baseline

# ----------------------------------------------------------------------------
# History & Environment Sanity
#   (Most core history variables anchored earlier in .zshenv; reinforce here
#    without overriding if user customized post-load.)
# ----------------------------------------------------------------------------
: "${HISTSIZE:=${HISTSIZE:-2000000}}"
: "${SAVEHIST:=${SAVEHIST:-2000200}}"
export HISTSIZE SAVEHIST

# Ensure interactive shells have a reasonable EDITOR fallback (do not override
# if already set earlier or by user environment).
if [[ -t 1 && -z "${EDITOR:-}" ]]; then
    for e in nvim vim nano; do
        command -v "$e" >/dev/null 2>&1 && { export EDITOR="$e"; break; }
    done
fi

# ----------------------------------------------------------------------------
# Completion Reservation
#   DO NOT RUN compinit here.
#   We only set a reservation marker ensuring a later module (50) owns the
#   single lawful compinit execution.
# ----------------------------------------------------------------------------
if [[ -n "${_COMPINIT_DONE:-}" ]]; then
    # If already done here, that would be a violation (shouldn’t happen in Stage 3).
    zf::opt_log "WARNING: _COMPINIT_DONE already set before Stage 5 (unexpected)."
else
    : "${ZSH_COMPINIT_RESERVED:=1}"
    export ZSH_COMPINIT_RESERVED
fi

# ----------------------------------------------------------------------------
# Re-source Verification (debug mode)
# ----------------------------------------------------------------------------
if [[ "${ZSH_DEBUG:-0}" == "1" ]]; then
    zf::opt_log "Guard=$ZSH_INTERACTIVE_OPTIONS_GUARD version=$ZSH_INTERACTIVE_OPTIONS_VERSION applied=$ZSH_INTERACTIVE_OPTIONS_APPLIED"
fi

# End of 05-interactive-options.zsh
