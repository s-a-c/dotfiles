#!/usr/bin/env zsh
# ==============================================================================
# ZSH Feature Status / Self-Check Command
# File: feature-status.zsh
#
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# Purpose:
#   Provide a unified user + CI facing command to inspect current feature
#   layer registration, enablement, dependency ordering, and basic invariants.
#
# Capabilities:
#   - Human-readable table (default)
#   - Raw pipe-friendly listing (--raw)
#   - JSON document (--json)
#   - Summary only (--summary)
#   - Detailed per-feature metadata (--verbose)
#   - Exit non‑zero on registry structural issues
#
# Exit Codes:
#   0 = Success
#   1 = Registry not found / not initialized
#   2 = Option parsing error
#   3 = Self-check failure
#
# Sensitive Actions:
#   - None. No external processes spawned, filesystem writes, nor PATH mutation.
#
# NOTE:
#   This script is safe to source multiple times; functions are idempotent.
# ==============================================================================

# Guard (allow re-sourcing without side effects)
if [[ -n "${__ZSH_FEATURE_STATUS_GUARD:-}" ]]; then
  return 0
fi
__ZSH_FEATURE_STATUS_GUARD=1

# ------------------------------------------------------------------------------
# Resolve base directory (attempt to infer registry path if not already loaded)
# ------------------------------------------------------------------------------
__zfs_this="${0:A}"
__zfs_dir="${__zfs_this:h}"
# Expect registry at ../feature/registry/feature-registry.zsh relative to this file
__zfs_root="${__zfs_dir:h}"
__zfs_registry="${__zfs_root}/registry/feature-registry.zsh"

# Attempt lazy load of registry only if not already present
if ! typeset -f feature_registry_list >/dev/null 2>&1; then
  if [[ -f "${__zfs_registry}" ]]; then
    source "${__zfs_registry}"
  fi
fi

# ------------------------------------------------------------------------------
# Utility: print to stderr
# ------------------------------------------------------------------------------
_zfs_err() { print -u2 -- "[feature-status][error] $*"; }
_zfs_warn() { print -u2 -- "[feature-status][warn]  $*"; }
_zfs_info() { print -u2 -- "[feature-status][info]  $*"; }

# ------------------------------------------------------------------------------
# Detect registry availability
# ------------------------------------------------------------------------------
_zfs_registry_available() {
  typeset -f feature_registry_list >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# Fetch ordered feature names (enabled only). If resolution fails (cycles),
# we still attempt to present partial data.
# ------------------------------------------------------------------------------
_zfs_resolved_order() {
  if ! _zfs_registry_available; then
    return 1
  fi
  local out
  if out="$(feature_registry_resolve_order 2>/dev/null)"; then
    print -- "$out"
    return 0
  else
    # Fallback: un-ordered list (may contain cycle participants)
    print -- "${ZSH_FEATURE_REGISTRY_NAMES[@]}"
    return 0
  fi
}

# ------------------------------------------------------------------------------
# JSON escaping helper (minimal; handles quotes, backslash, newlines, tabs)
# ------------------------------------------------------------------------------
_zfs_json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  print -- "$s"
}

# ------------------------------------------------------------------------------
# Collect metadata for a feature (best effort)
# ------------------------------------------------------------------------------
_zfs_feature_metadata() {
  local name="$1"
  local enabled="no"
  if feature_registry_is_enabled "$name"; then enabled="yes"; fi
  local phase="${ZSH_FEATURE_REGISTRY_PHASE[$name]:-?}"
  local depends="${ZSH_FEATURE_REGISTRY_DEPENDS[$name]:-}"
  local deferred="${ZSH_FEATURE_REGISTRY_DEFERRED[$name]:-no}"
  local category="${ZSH_FEATURE_REGISTRY_CATEGORY[$name]:-misc}"
  local desc="${ZSH_FEATURE_REGISTRY_DESCRIPTION[$name]:-}"
  local guid="${ZSH_FEATURE_REGISTRY_GUID[$name]:-}"
  print -- "$name|$phase|$enabled|$deferred|$category|$depends|$guid|$desc"
}

# ------------------------------------------------------------------------------
# Output: Table
# ------------------------------------------------------------------------------
_zfs_output_table() {
  local names=("$@")
  printf "%-24s %-5s %-8s %-8s %-16s %-20s %s\n" "FEATURE" "PHASE" "ENABLED" "DEFER" "CATEGORY" "DEPENDS" "DESC"
  printf "%-24s %-5s %-8s %-8s %-16s %-20s %s\n" "-------" "-----" "-------" "-----" "--------" "-------" "----"
  local line name phase enabled deferred category depends guid desc
  for name in "${names[@]}"; do
    line="$(_zfs_feature_metadata "$name")"
    IFS='|' read -r name phase enabled deferred category depends guid desc <<<"$line"
    printf "%-24s %-5s %-8s %-8s %-16s %-20s %s\n" \
      "$name" "$phase" "$enabled" "$deferred" "$category" "${depends:-.}" "${desc:-.}"
  done
}

# ------------------------------------------------------------------------------
# Output: Raw (pipe-friendly)
# Format: name|phase|enabled|deferred|category|depends|guid|description
# ------------------------------------------------------------------------------
_zfs_output_raw() {
  local names=("$@") line
  for n in "${names[@]}"; do
    _zfs_feature_metadata "$n"
  done
}

# ------------------------------------------------------------------------------
# Output: JSON
# ------------------------------------------------------------------------------
_zfs_output_json() {
  local names=("$@") first=1
  print -- "["
  local line name phase enabled deferred category depends guid desc
  for name in "${names[@]}"; do
    line="$(_zfs_feature_metadata "$name")"
    IFS='|' read -r name phase enabled deferred category depends guid desc <<<"$line"
    if (( ! first )); then print -- ","; fi
    first=0
    print -n -- "  {"
    print -n -- "\"name\":\"$(_zfs_json_escape "$name")\","
    print -n -- "\"phase\":$(( ${phase:-0} )),"
    print -n -- "\"enabled\":\"$enabled\","
    print -n -- "\"deferred\":\"$deferred\","
    print -n -- "\"category\":\"$(_zfs_json_escape "$category")\","
    print -n -- "\"depends\":["
    local d first_dep=1
    for d in $depends; do
      if (( ! first_dep )); then print -n -- ","; fi
      first_dep=0
      print -n -- "\"$(_zfs_json_escape "$d")\""
    done
    print -n -- "],"
    print -n -- "\"guid\":\"$(_zfs_json_escape "$guid")\","
    print -n -- "\"description\":\"$(_zfs_json_escape "$desc")\""
    print -- "}"
  done
  print -- "]"
}

# ------------------------------------------------------------------------------
# Output: Summary
# ------------------------------------------------------------------------------
_zfs_output_summary() {
  local total enabled disabled deferred
  local n name line phase en def cat dep guid desc
  total=0; enabled=0; disabled=0; deferred=0
  for name in "$@"; do
    (( total++ ))
    line="$(_zfs_feature_metadata "$name")"
    IFS='|' read -r n phase en def cat dep guid desc <<<"$line"
    if [[ "$en" == "yes" ]]; then (( enabled++ )); else (( disabled++ )); fi
    if [[ "$def" == "yes" ]]; then (( deferred++ )); fi
  done
  print -- "Features: total=$total enabled=$enabled disabled=$disabled deferred=$deferred"
}

# ------------------------------------------------------------------------------
# Self-check (lightweight invariants)
# ------------------------------------------------------------------------------
_zfs_self_check() {
  local failures=0 name
  for name in "${ZSH_FEATURE_REGISTRY_NAMES[@]}"; do
    if [[ -z "${ZSH_FEATURE_REGISTRY_PHASE[$name]:-}" ]]; then
      _zfs_err "Missing phase for feature '$name'"
      (( failures++ ))
    fi
    if [[ -z "${ZSH_FEATURE_REGISTRY_CATEGORY[$name]:-}" ]]; then
      _zfs_err "Missing category for feature '$name'"
      (( failures++ ))
    fi
  done
  return $failures
}

# ------------------------------------------------------------------------------
# Main dispatcher
# ------------------------------------------------------------------------------
zsh_features_status() {
  local mode="table"
  local want_summary=0
  local want_selfcheck=1
  local verbose=0

  while (( $# > 0 )); do
    case "$1" in
      --json) mode="json" ;;
      --raw) mode="raw" ;;
      --table) mode="table" ;;
      --summary) want_summary=1 ;;
      --no-self-check) want_selfcheck=0 ;;
      --verbose|-v) verbose=1 ;;
      --help|-h)
        cat <<'EOF'
Usage: zsh-features status [options]

Options:
  --table           Table output (default)
  --raw             Raw pipe-friendly lines
  --json            JSON output
  --summary         Append summary line/counts
  --no-self-check   Skip registry self-check validation
  --verbose         Include extra metadata (GUID) in table
  --help            Show this help

Exit Codes:
  0 success
  1 registry unavailable
  2 option parsing error
  3 self-check failed

EOF
        return 0
        ;;
      *)
        _zfs_err "Unknown option: $1"
        return 2
        ;;
    esac
    shift
  done

  if ! _zfs_registry_available; then
    _zfs_err "Feature registry not loaded or unavailable"
    return 1
  fi

  # Acquire resolved ordering (enabled prioritized via registry algorithm)
  local ordered=()
  local raw_order
  raw_order="$(_zfs_resolved_order)"
  ordered=(${=raw_order})

  # Build full superset list (use registration order for display baseline)
  local names=("${ZSH_FEATURE_REGISTRY_NAMES[@]}")

  case "$mode" in
    table)
      _zfs_output_table "${names[@]}"
      if (( verbose )); then
        print ""
        printf "%-24s %s\n" "GUID" "FEATURE"
        printf "%-24s %s\n" "----" "-------"
        local g n
        for n in "${names[@]}"; do
          g="${ZSH_FEATURE_REGISTRY_GUID[$n]:-}"
          printf "%-24s %s\n" "${g:-.}" "$n"
        done
      fi
      ;;
    raw)
      _zfs_output_raw "${names[@]}"
      ;;
    json)
      _zfs_output_json "${names[@]}"
      ;;
  esac

  if (( want_summary )); then
    _zfs_output_summary "${names[@]}"
  fi

  if (( want_selfcheck )); then
    if ! _zfs_self_check; then
      _zfs_err "Self-check failed"
      return 3
    fi
  fi

  return 0
}

# ------------------------------------------------------------------------------
# Public entry alias (subcommand style)
# ------------------------------------------------------------------------------
zsh-features() {
  local sub="${1:-status}"
  if [[ "$sub" == "status" ]]; then
    shift
    zsh_features_status "$@"
  else
    _zfs_err "Unknown subcommand: $sub"
    print -u2 -- "Try: zsh-features status --help"
    return 2
  fi
}

# End of feature-status.zsh
# ==============================================================================
