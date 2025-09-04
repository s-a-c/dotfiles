# 00-security-integrity.zsh
# Stage 3 – Security & Integrity (early skeleton)
# PURPOSE:
#   Provides early path hygiene + integrity sentinel without heavy hashing.
#   MUST remain idempotent (re-sourcing safe) and side-effect minimal.
#
# Responsibilities (current scope):
#   - Ensure this module only executes its initialization logic once.
#   - Capture original PATH snapshot (if not already captured).
#   - Provide helper to perform append-only PATH updates (no destructive rewrites).
#   - Export a minimal trust anchor map placeholder (no hashing yet).
#   - Register (stub) a deferred integrity check task for later Stage 5+ activation.
#
# Deferred (future stages):
#   - Full checksum verification
#   - Async security scans integration
#   - Policy checksum correlation
#
# Idempotency Contract:
#   Re-sourcing must NOT duplicate registrations or mutate PATH again.
#
# Sentinel:
#   _LOADED_00_SECURITY_INTEGRITY = 1 once core initialization complete.
#
# NOTE:
#   Keep changes in sync with IMPLEMENTATION.md Stage 3 task list.
#
if [[ -n "${_LOADED_00_SECURITY_INTEGRITY:-}" ]]; then
  return 0
fi
: ${_LOADED_00_SECURITY_INTEGRITY:=1}

# ---------------------------------------
# PATH Hygiene
# ---------------------------------------

# Snapshot original PATH once (if not already done by a prior early module)
: ${ZSH_ORIGINAL_PATH:=${PATH}}

# Internal: ensure append-only semantics when adding to PATH.
# Usage: _sec_path_append "/new/dir"
# - Skips if directory does not exist.
# - Skips if already present (exact component match).
# - Never removes or reorders existing components.
_sec_path_append() {
  local dir=$1
  [[ -z "$dir" ]] && return 0
  [[ -d "$dir" ]] || return 0
  case ":$PATH:" in
    *":$dir:"*) return 0 ;;
  esac
  PATH="${PATH:+$PATH:}$dir"
}

# Example (commented) potential future usage:
# _sec_path_append "/opt/some/minimal/tooling/bin"

# Export a public helper (namespaced) for other modules (optional use).
zf::path_append_secure() {
  _sec_path_append "$1"
}

# ---------------------------------------
# Minimal Trust Anchor Placeholder + Read Helpers
# ---------------------------------------
# Format: key=value pairs representing future checksum or policy anchors.
# Keep extremely small until hashing phase activates (Stage 5/6).
# Stage 3 Addition:
#   Introduce read‑only helper APIs for tests and later integrity/reporting logic:
#     - zf::trust_anchor_get <key>     -> echo value (no trailing newline change), return 0 if present else 1
#     - zf::trust_anchor_has <key>     -> return 0 if present else 1 (no output)
#     - zf::trust_anchor_keys          -> echo ordered list of keys (one per line)
#     - zf::trust_anchor_dump          -> echo key=value pairs (one per line, sorted)
#   These helpers MUST remain side‑effect free (never mutating ZF_TRUST_ANCHORS).
typeset -gA ZF_TRUST_ANCHORS
if [[ -z "${ZF_TRUST_ANCHORS_INITIALIZED:-}" ]]; then
  ZF_TRUST_ANCHORS_INITIALIZED=1
  # Placeholder anchors (add real entries later)
  ZF_TRUST_ANCHORS[policy_version]="v0"
  ZF_TRUST_ANCHORS[mode]="observe"
fi

# Return 0 if anchor exists, 1 otherwise (no output)
zf::trust_anchor_has() {
  local k="$1"
  [[ -n "$k" && -n "${ZF_TRUST_ANCHORS[$k]:-}" ]]
}

# Echo value if present, return 0; return 1 (no output) if missing
zf::trust_anchor_get() {
  local k="$1"
  if [[ -z "$k" || -z "${ZF_TRUST_ANCHORS[$k]:-}" ]]; then
    return 1
  fi
  print -r -- "${ZF_TRUST_ANCHORS[$k]}"
  return 0
}

# List keys (sorted) one per line
zf::trust_anchor_keys() {
  printf '%s\n' ${(on)${(k)ZF_TRUST_ANCHORS}}
}

# Dump key=value pairs sorted by key
zf::trust_anchor_dump() {
  local k
  for k in ${(on)${(k)ZF_TRUST_ANCHORS}}; do
    print -r -- "${k}=${ZF_TRUST_ANCHORS[$k]}"
  done
}

# ---------------------------------------
# Deferred Integrity Task Registration (Stub)
# ---------------------------------------
# Future: push an async task into a dispatcher queue. For now we
# just record intent in an array to allow tests to verify single registration.
typeset -gA ZF_DEFERRED_TASKS
if [[ -z "${ZF_DEFERRED_TASKS[security_integrity_check]:-}" ]]; then
  ZF_DEFERRED_TASKS[security_integrity_check]="registered"
fi

# Public no-op function to be populated later.
zf::integrity_check_deferred() {
  # Placeholder: real implementation will perform checksum / policy validation.
  return 0
}

# ---------------------------------------
# Diagnostics (optional verbose mode)
# ---------------------------------------
if [[ -n "${ZF_SEC_DEBUG:-}" ]]; then
  print "[00-security-integrity] loaded (idempotent) PATH_len=${#PATH} anchors=${#ZF_TRUST_ANCHORS[@]}"
fi
