#!/usr/bin/env zsh
# 40-aliases-keybindings.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Provide a minimal, strictly delimited set of quality-of-life aliases and a few
#   safe navigation / keybinding helpers for the redesigned post‑plugin layer.
#   Introduces granular performance segment probes required by Sprint 2:
#     SEGMENT name=safety/aliases    ms=<delta> phase=post_plugin sample=<context>
#     SEGMENT name=navigation/cd     ms=<delta> phase=post_plugin sample=<context>
#
#   These names MUST stay stable (referenced by tests: test-granular-segments.zsh).
#
# SCOPE (allowed):
#   - Pure shell aliases (ls variants, safety wrappers, grep defaults)
#   - Non‑blocking navigation helpers (directory shortcuts / cd wrapper)
#   - Lightweight keybinding adjustments (bindkey) without external IO
#
# OUT OF SCOPE (defer to later feature modules):
#   - Git prompt / VCS heavy logic
#   - FZF advanced widgets
#   - Network, hashing, or toolchain initialization
#
# PERFORMANCE INSTRUMENTATION:
#   - Emits exactly one SEGMENT line per probe (idempotent guarded).
#   - Emits JSON sidecar entries when ZSH_LOG_STRUCTURED=1 (privacy allowlisted fields only).
#   - Adds near‑zero overhead (pure arithmetic + a few aliases).
#
# PRIVACY:
#   - Only timing metadata: name, ms, phase, sample, ts (epoch ms).
#   - No PII / filesystem paths / command arguments recorded.
#
# SAFETY & GOVERNANCE:
#   - Sentinel prevents double sourcing.
#   - All modifications are reversible (aliases/keymaps can be unset later).
#   - No mutation of PATH or environment beyond aliases / keybindings.
#
# FLAGS:
#   ZSH_DISABLE_ALIASES_KEYBINDINGS=1  → skip defining aliases/keybindings (segments still emitted).
#
# ---------------------------------------------------------------------------

# Sentinel
[[ -n "${_LOADED_40_ALIASES_KEYBINDINGS:-}" ]] && return 0
_LOADED_40_ALIASES_KEYBINDINGS=1
readonly _LOADED_40_ALIASES_KEYBINDINGS=1

# Optional debug logger (namespaced). Reuse zf::debug if present.
if ! typeset -f zf::debug >/dev/null 2>&1; then
  zf::debug() { :; }
fi

# Ensure we have high‑resolution clock if available
zmodload zsh/datetime 2>/dev/null || true

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

__ak_now_ms() {
  # Prefer EPOCHREALTIME (float seconds) → integer ms
  if [[ -n ${EPOCHREALTIME:-} ]]; then
    awk -v t="${EPOCHREALTIME}" 'BEGIN{split(t,a,"."); printf "%s%03d", a[1], substr(a[2]"000",1,3)}'
  else
    # Fallback coarse; still monotonic enough for sub‑second segments
    (date +%s 2>/dev/null || printf 0) | awk '{printf "%d000",$1}'
  fi
}

__ak_emit_segment() {
  # __ak_emit_segment <name> <ms>
  local _name="$1" _ms="$2" _sample="${PERF_SAMPLE_CONTEXT:-unknown}"
  [[ -n "${PERF_SEGMENT_LOG:-}" && -w "${PERF_SEGMENT_LOG:-/dev/null}" ]] || return 0
  print "SEGMENT name=${_name} ms=${_ms} phase=post_plugin sample=${_sample}" >> "${PERF_SEGMENT_LOG}" 2>/dev/null || true

  # Structured telemetry JSON (zero overhead if flag off)
  if [[ "${ZSH_LOG_STRUCTURED:-0}" == "1" ]]; then
    local _ts
    if [[ -n ${EPOCHREALTIME:-} ]]; then
      _ts=$(awk -v t="${EPOCHREALTIME}" 'BEGIN{split(t,a,"."); printf "%s%03d", a[1], substr(a[2]"000",1,3)}')
    else
      _ts="$(date +%s 2>/dev/null || printf 0)000"
    fi
    local _json_target="${PERF_SEGMENT_JSON_LOG:-${PERF_SEGMENT_LOG}}"
    [[ -w "${_json_target}" ]] && print -- "{\"type\":\"segment\",\"name\":\"${_name}\",\"ms\":${_ms},\"phase\":\"post_plugin\",\"sample\":\"${_sample}\",\"ts\":${_ts}}" >> "${_json_target}" 2>/dev/null || true
  fi
}

# Guard variables to prevent re‑emission
typeset -g __AK_SEG_EMITTED_ALIASES=0
typeset -g __AK_SEG_EMITTED_CD=0

__ak_span_measure_and_emit() {
  # __ak_span_measure_and_emit <marker_var> <segment_name> <function_body...>
  # Executes inline function body (passed as code string) while timing.
  local _marker_var="$1" _seg_name="$2"; shift 2
  # shellcheck disable=SC2086
  [[ "${(P)_marker_var:-0}" -eq 1 ]] && return 0
  local _start _end _delta
  _start="$(__ak_now_ms)"
  # Execute body (no subshell to keep minimal overhead)
  eval "$@" 2>/dev/null || true
  _end="$(__ak_now_ms)"
  (( _delta = _end - _start ))
  (( _delta < 0 )) && _delta=0
  __ak_emit_segment "${_seg_name}" "${_delta}"
  typeset -g "${_marker_var}=1"
  zf::debug "aliases-keybindings seg=${_seg_name} ms=${_delta}"
}

# ---------------------------------------------------------------------------
# Alias Definitions (timed)
# ---------------------------------------------------------------------------

__ak_define_aliases() {
  # Safety / informative aliases
  alias ll='ls -lah'
  alias la='ls -A'
  alias l='ls -1'
  alias lt='ls -ltrh'
  alias lsd='ls -d */ 2>/dev/null'
  # Grep safer defaults (color if available)
  if command -v grep >/dev/null 2>&1; then
    alias grep='grep --color=auto'
  fi
  # Safe remove - move to trash (placeholder – simple no-op wrapper)
  if command -v rm >/dev/null 2>&1; then
    alias rm='rm -i'
  fi
  # Safer cp/mv prompts
  alias cp='cp -i'
  alias mv='mv -i'
}

# ---------------------------------------------------------------------------
# Navigation Helpers (timed)
# ---------------------------------------------------------------------------

__ak_define_navigation() {
  # Quick jump aliases (examples; extremely lightweight)
  alias ..='cd ..'
  alias ...='cd ../..'
  alias ....='cd ../../..'

  # Wrapper around cd to record last directory in a variable.
  if ! typeset -f cd >/dev/null 2>&1; then
    # Only wrap if not already custom (avoid double logic).
    builtin typeset -f __ak_orig_cd >/dev/null 2>&1 || eval "__ak_orig_cd() { builtin cd \"\$@\"; }"
    cd() {
      local target="$1"
      __ak_orig_cd "$@" || return $?
      export ZSH_LAST_DIR="$PWD"
      return 0
    }
  fi
}

# ---------------------------------------------------------------------------
# Keybindings (NOT timed; negligible & optional)
# ---------------------------------------------------------------------------

__ak_apply_keybindings() {
  # Only if zle is available (interactive); skip in non-interactive shells
  [[ -o interactive ]] || return 0
  autoload -Uz bindkey 2>/dev/null || true
  # Common Emacs-style enhancements if line editor active
  if [[ -n "${ZLE_LINE_EDITOR:-}" || -t 0 ]]; then
    bindkey -e 2>/dev/null || true
    # History substring search (if widget present later)
    zle -A history-incremental-search-backward _ak_hist_search_back 2>/dev/null || true
  fi
}

# ---------------------------------------------------------------------------
# Conditional Execution
# ---------------------------------------------------------------------------

# We ALWAYS emit segments (even if aliases disabled) to keep perf ledger consistent.
if [[ "${ZSH_DISABLE_ALIASES_KEYBINDINGS:-0}" == "1" ]]; then
  __ak_span_measure_and_emit __AK_SEG_EMITTED_ALIASES "safety/aliases" ': # aliases disabled'
  __ak_span_measure_and_emit __AK_SEG_EMITTED_CD "navigation/cd" ': # navigation disabled'
else
  __ak_span_measure_and_emit __AK_SEG_EMITTED_ALIASES "safety/aliases" "__ak_define_aliases"
  __ak_span_measure_and_emit __AK_SEG_EMITTED_CD "navigation/cd" "__ak_define_navigation"
  __ak_apply_keybindings
fi

# ---------------------------------------------------------------------------
# Idempotency Verification (debug mode only)
# ---------------------------------------------------------------------------
if [[ -n "${ZF_DEBUG:-}" ]]; then
  zf::debug "aliases-keybindings loaded (segments aliases=${__AK_SEG_EMITTED_ALIASES} cd=${__AK_SEG_EMITTED_CD})"
fi

# End of 40-aliases-keybindings.zsh
