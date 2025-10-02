#!/usr/bin/env zsh
# ============================================================================
# 00-security-integrity.zsh    (Stage 3 – Post-Plugin Core Scaffold)
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
# Responsibility:
#     - Lightweight environment & security hardening primitives.
#     - Enforce PATH append-not-overwrite semantics (validated earlier in .zshenv).
#     - Register (but DO NOT EXECUTE) a deferred integrity scan scheduler stub.
#     - Provide a namespaced, idempotent API surface for later stages (Stage 5/6).
#
# Non-Goals (now):
#     - Performing deep hashing / integrity diff (Stage 5/6).
#     - Plugin trust scoring or signature verification (future enhancement).
#     - Async execution (80-security-validation will trigger actual jobs).
#
# Invariants (I*):
#     I1: Sourcing this file is idempotent (no duplicate side-effects).
#     I2: Integrity scheduler registration occurs exactly once.
#     I3: PATH is not destructively reordered; only inspected / optionally dedup’d.
#     I4: Core hardening setopts are applied only once (and are observable).
#     I5: No blocking operations > ~5ms (no heavy hashing, file walks, network).
#
# Exported Indicators:
#     ZSH_SEC_INTEGRITY_GUARD=1                                - Sentinel: file sourced at least once.
#     ZSH_SEC_INTEGRITY_VERSION=1                            - Increment if contract changes.
#     ZSH_SEC_INTEGRITY_SCHEDULER_REGISTERED=1 - Integrity scan scheduler stubbed.
#     ZSH_SEC_HARDEN_APPLIED=1                                 - Hardening setopts applied.
#
# Test Hooks (anticipated):
#     - test-security-scheduler-single.zsh:
#             Ensures variable ZSH_SEC_INTEGRITY_SCHEDULER_REGISTERED == 1 and re-source does not increase counter.
#     - test-path-hygiene.zsh:
#             Launch subshell with trimmed PATH, source .zshenv + this module; assert required core dirs present.
#     - test-hardening-idempotent.zsh:
#             Capture setopt snapshot before/after re-source -> no drift.
#
# Performance Budget (module self):
#     Target ≤1ms incremental cost (excluding shell startup already consumed).
#
# Future Extension Points (Stage 5/6):
#     - zf::integrity_queue_scan
#     - zf::integrity_run_now (manual override)
#     - Async event emission / segment markers (security_scan_start / _complete)
# ============================================================================

# Sentinel (idempotency guard)
if [[ -n "${ZSH_SEC_INTEGRITY_GUARD:-}" ]]; then
    # Optional verbose signal (only if debug explicitly enabled)
    if [[ "${ZSH_DEBUG:-0}" == "1" ]]; then
        print -u2 "[00-security-integrity] Re-source skipped (already initialized)."
    fi
    return 0
fi
export ZSH_SEC_INTEGRITY_GUARD=1
export ZSH_SEC_INTEGRITY_VERSION=1

# ----------------------------------------------------------------------------
# Lightweight Logging Helper (namespaced)
# ----------------------------------------------------------------------------
zf::sec_log() {
    # Only log when ZSH_DEBUG=1 to avoid clutter
    [[ "${ZSH_DEBUG:-0}" == "1" ]] || return 0
    print -u2 "[00-security-integrity] $*"
}

# ----------------------------------------------------------------------------
# PATH Hygiene (non-destructive verification)
#     - Confirms presence of required baseline dirs (as appended earlier).
#     - Optionally performs a *safe* dedup (preserve-first) if not already done.
# ----------------------------------------------------------------------------
zf::sec_path_hygiene() {
    local required_dirs=(
        /usr/bin /bin /usr/sbin /sbin
        /usr/local/bin /usr/local/sbin
        /opt/homebrew/bin
    )
    local missing=()
    local d
    for d in "${required_dirs[@]}"; do
        [[ -d "$d" ]] || continue
        case ":$PATH:" in
        *:"$d":*) ;; # present
        *) missing+=("$d") ;;
        esac
    done

    if ((${#missing[@]})); then
        # Append missing (preserves existing ordering)
        local m
        for m in "${missing[@]}"; do
            PATH="${PATH:+$PATH:}$m"
        done
        export PATH
        zf::sec_log "Appended missing core dirs: ${missing[*]}"
    fi

    # Perform dedup only if PATH_DEDUP_DONE not already set
    if [[ -z "${PATH_DEDUP_DONE:-}" && "${ZSH_SEC_DISABLE_AUTO_DEDUP:-0}" != "1" ]]; then
        # Simple preserve-first dedup (POSIX-lean)
        local IFS=:
        local seen=""
        local seg new_path=""
        for seg in $PATH; do
            [[ -z "$seg" ]] && continue
            case ":$seen:" in
            *:"$seg":*) continue ;;
            *)
                seen="${seen:+$seen:}$seg"
                new_path="${new_path:+$new_path:}$seg"
                ;;
            esac
        done
        if [[ "$new_path" != "$PATH" ]]; then
            PATH="$new_path"
            export PATH
            zf::sec_log "PATH deduplicated."
        fi
        export PATH_DEDUP_DONE=1
    fi
}

zf::sec_path_hygiene

# ----------------------------------------------------------------------------
# Core Hardening (minimal; no controversial flags)
#     - These should be stable & idempotent; avoid altering user expectation.
#     - Extended sets can be added later (tracked by tests).
# ----------------------------------------------------------------------------
zf::sec_apply_hardening() {
    [[ -n "${ZSH_SEC_HARDEN_APPLIED:-}" ]] && return 0

    # Defensive shell options (safe baseline)
    # noclobber: avoid accidental > file truncation
    setopt noclobber 2>/dev/null || true
    # hist_ignore_dups & hist_ignore_space typically set later; avoid duplication here.

    export ZSH_SEC_HARDEN_APPLIED=1
    zf::sec_log "Hardening applied."
}
zf::sec_apply_hardening

# ----------------------------------------------------------------------------
# Integrity Scheduler Stub
#     - Registers that a deferred integrity scan *will* be queued later (Stage 5/6).
#     - Does NOT perform any I/O or hashing here.
# ----------------------------------------------------------------------------
zf::register_integrity_scheduler() {
    [[ -n "${ZSH_SEC_INTEGRITY_SCHEDULER_REGISTERED:-}" ]] && return 0
    # Create a lightweight manifest placeholder recording registration time.
    # This is intentionally minimal (no deep scan metadata yet).
    local _cache_base="${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-${HOME}/.cache}/zsh}"
    local _manifest="${_cache_base}/integrity-scheduler-manifest.json"
    mkdir -p "${_cache_base}" 2>/dev/null || true
    local _ts
    _ts="$(date +%Y%m%dT%H%M%S 2>/dev/null || echo unknown)"
    printf '{ "schema":"integrity-scheduler.v1", "registered_at":"%s", "version":1 }\n' "${_ts}" >"${_manifest}" 2>/dev/null || true
    export ZSH_SEC_INTEGRITY_MANIFEST="${_manifest}"
    export ZSH_SEC_INTEGRITY_SCHEDULER_REGISTERED=1
    zf::sec_log "Integrity scheduler stub registered (manifest=${_manifest})."
}
zf::register_integrity_scheduler

# ----------------------------------------------------------------------------
# Public (future) API Placeholders
# ----------------------------------------------------------------------------
zf::integrity_status() {
    # Simple status reporter (expand with richer states later)
    printf 'integrity_scheduler_registered=%s hardening=%s\n' \
        "${ZSH_SEC_INTEGRITY_SCHEDULER_REGISTERED:-0}" \
        "${ZSH_SEC_HARDEN_APPLIED:-0}"
}

zf::integrity_queue_scan() {
    # Placeholder (Stage 5/6): queue a deep scan job; currently no-op
    zf::sec_log "integrity_queue_scan (noop placeholder)"
    return 0
}

zf::integrity_run_now() {
    # Placeholder immediate execution (will eventually dispatch async job)
    zf::sec_log "integrity_run_now (noop placeholder)"
    return 0
}

# ----------------------------------------------------------------------------
# Re-source Verification (self-check)
# ----------------------------------------------------------------------------
if [[ "${ZSH_DEBUG:-0}" == "1" ]]; then
    zf::sec_log "Initialized: scheduler=${ZSH_SEC_INTEGRITY_SCHEDULER_REGISTERED:-0} hardening=${ZSH_SEC_HARDEN_APPLIED:-0}"
fi

# End of 00-security-integrity.zsh
