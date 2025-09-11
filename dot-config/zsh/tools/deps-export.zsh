#!/usr/bin/env zsh
# dotfiles/dot-config/zsh/tools/deps-export.zsh
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Export a normalized view of the redesign dependency graph (modules + features)
#   in JSON or DOT (Graphviz) format for auditing, visualization, and CI drift detection.
#
# SCOPE (Sprint 2 – Initial Skeleton):
#   - Supports module dependency extraction via ZF_MODULE_DEPENDENCIES (02-module-hardening).
#   - Supports feature registry extraction if feature layer registry functions are present
#     (e.g., feature_registry_list / feature_registry_resolve_order).
#   - Provides unified export function: zf::deps::export [--format=json|dot] [--output <file>|-]
#       [--include-disabled] [--no-header] [--only=modules|features|all]
#   - Disabled node detection by sentinel / feature enable status (best‑effort).
#
# NOT YET IMPLEMENTED (Future Enhancements):
#   - Rich edge metadata (runtime / build / optional / cycle flags).
#   - Cycle annotation (will invoke detector once integrated).
#   - Delta mode (compare previous snapshot).
#   - Integrity hash / signature emission.
#
# OUTPUT CONTRACT (Version 1):
#   JSON:
#     {
#       "version": 1,
#       "generated_at": "<iso8601>",
#       "source": "deps-export.zsh",
#       "filters": { ... },
#       "nodes": [
#         {"id":"10-core-functions","kind":"module","enabled":true,"group":"module"},
#         {"id":"noop","kind":"feature","enabled":true,"group":"feature"}
#       ],
#       "edges": [
#         {"from":"20-essential-plugins","to":"10-core-functions","kind":"declared","group":"module"},
#         {"from":"featureX","to":"noop","kind":"feature_dep","group":"feature"}
#       ]
#     }
#   DOT:
#     digraph zsh_deps {
#       rankdir=LR;
#       node [shape=box,fontsize=11];
#       "20-essential-plugins" -> "10-core-functions";
#     }
#
# PRIVACY / CONTENT:
#   - Only emits identifiers and static dependency declarations (no PII).
#
# EXIT CODES:
#   0 success
#   1 generic failure (bad args / write error)
#
# TEST PLAN (Outline):
#   - Unit: json format contains version=1, nodes length >0, edges parse.
#   - Unit: dot format header lines present.
#   - Unit: --only=modules excludes feature nodes (and vice versa).
#   - Unit: disabled modules show enabled=false (simulate by clearing sentinel).
#   - Unit: --include-disabled retains disabled nodes; default excludes? (initial default: include all, flag reserved).
#
# USAGE EXAMPLES:
#   zf::deps::export --format=json --output deps.json
#   zf::deps::export --format=dot  > deps.dot
#   ZSH_LOG_STRUCTURED=1 zsh tools/deps-export.zsh --format=json
#
# ------------------------------------------------------------------------------
# Guard re-sourcing (noop if already loaded as a library)
if [[ -n "${_LOADED_DEPS_EXPORT_TOOL:-}" ]]; then
  return 0
fi
_LOADED_DEPS_EXPORT_TOOL=1

# -----------------------------
# Utility / Support Functions
# -----------------------------

__deps_iso8601() {
  # Portable ISO8601 (fallback if date -Iseconds missing)
  local ts
  ts=$(date -Iseconds 2>/dev/null) || ts="$(date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || echo 0)"
  print -- "$ts"
}

__deps_echo_err() {
  print -- "[deps-export][err] $*" >&2
}

__deps_debug() {
  [[ -n "${DEPS_EXPORT_DEBUG:-}" ]] || return 0
  print -- "[deps-export][dbg] $*" >&2
}

# -----------------------------
# Graph Collection (Modules)
# -----------------------------
#
# Source of truth: ZF_MODULE_DEPENDENCIES (associative: module -> space separated deps)
# Enabled detection: sentinel variable _LOADED_<UPPER_NAME_WITH_DASHES_AS_UNDERSCORES>
#

__deps_collect_modules() {
  local -a nodes edges
  nodes=()
  edges=()

  # Bail early if associative not declared
  if ! typeset -p ZF_MODULE_DEPENDENCIES >/dev/null 2>&1; then
    __deps_debug "ZF_MODULE_DEPENDENCIES not declared – skipping module graph"
    print -r -- "" # first line nodes string
    print -r -- "" # second line edges string
    return 0
  fi

  local k deps sentinel sentinel_u enabled dep
  for k in ${(k)ZF_MODULE_DEPENDENCIES}; do
    deps="${ZF_MODULE_DEPENDENCIES[$k]}"
    sentinel="_LOADED_${k//-/_}"
    sentinel_u="${(U)sentinel}"
    if typeset -p "${sentinel_u}" >/dev/null 2>&1; then
      enabled=true
    else
      enabled=false
    fi
    nodes+=("${k}::${enabled}")

    for dep in ${=deps}; do
      [[ -n "$dep" ]] || continue
      edges+=("${k}::${dep}")
    done
  done

  print -r -- "${(j:,:)nodes}"
  print -r -- "${(j:,:)edges}"
}

# -----------------------------
# Graph Collection (Features)
# -----------------------------
#
# Feature registry (if present):
#   Expect helper: feature_registry_list -> prints one feature id per line
#                   feature_registry_metadata <id> -> outputs key=value lines (phase=, deps=)
# Optional dependencies key: deps="a b c"
#

__deps_collect_features() {
  local -a nodes edges
  nodes=()
  edges=()

  if ! whence -w feature_registry_list >/dev/null 2>&1; then
    __deps_debug "Feature registry not present – skipping feature graph"
    print -r -- ""
    print -r -- ""
    return 0
  fi

  local fid meta deps enabled dep status_line
  while IFS= read -r fid; do
    [[ -z "$fid" ]] && continue
    # Discover metadata
    if whence -w feature_registry_metadata >/dev/null 2>&1; then
      meta="$(feature_registry_metadata "$fid" 2>/dev/null || true)"
      deps="$(print -r -- "$meta" | awk -F= '/^deps=/{sub(/^deps=/,"");print}')"
      enabled="$(print -r -- "$meta" | awk -F= '/^enabled=/{sub(/^enabled=/,"");print}')"
      [[ -z "$enabled" ]] && enabled="unknown"
    else
      deps=""
      enabled="unknown"
    fi
    nodes+=("${fid}::${enabled}")

    for dep in ${=deps}; do
      [[ -n "$dep" ]] || continue
      edges+=("${fid}::${dep}")
    done
  done < <(feature_registry_list 2>/dev/null || true)

  print -r -- "${(j:,:)nodes}"
  print -r -- "${(j:,:)edges}"
}

# -----------------------------
# Export Builders
# -----------------------------

__deps_emit_json() {
  local only="$1" include_disabled="$2"
  shift 2
  local -a modules_nodes features_nodes modules_edges features_edges
  local m_nodes_line m_edges_line f_nodes_line f_edges_line

  m_nodes_line="$1"; m_edges_line="$2"; f_nodes_line="$3"; f_edges_line="$4"

  local iso; iso="$(__deps_iso8601)"

  print -- "{"
  print -- "  \"version\": 1,"
  print -- "  \"generated_at\": \"${iso}\","
  print -- "  \"source\": \"deps-export.zsh\","
  print -- "  \"filters\": {\"only\":\"${only}\",\"include_disabled\":${include_disabled}},"
  print -- "  \"nodes\": ["

  local first=1
  if [[ "$only" != "features" && -n "$m_nodes_line" ]]; then
    for pair in ${(s:,:)m_nodes_line}; do
      local id="${pair%%::*}"
      local en="${pair##*::}"
      if [[ "$include_disabled" != "1" && "$en" == "false" ]]; then
        continue
      fi
      (( first )) || print -- ","
      print -r -- "    {\"id\":\"$id\",\"kind\":\"module\",\"group\":\"module\",\"enabled\":${en}}"
      first=0
    done
  fi

  if [[ "$only" != "modules" && -n "$f_nodes_line" ]]; then
    for pair in ${(s:,:)f_nodes_line}; do
      local id="${pair%%::*}"
      local en="${pair##*::}"
      if [[ "$include_disabled" != "1" && "$en" == "false" ]]; then
        continue
      fi
      (( first )) || print -- ","
      # Normalize unknown -> null in JSON (emit true/false/null)
      if [[ "$en" == "unknown" ]]; then
        print -r -- "    {\"id\":\"$id\",\"kind\":\"feature\",\"group\":\"feature\",\"enabled\":null}"
      else
        print -r -- "    {\"id\":\"$id\",\"kind\":\"feature\",\"group\":\"feature\",\"enabled\":\"$en\"}"
      fi
      first=0
    done
  fi

  print -- "  ],"
  print -- "  \"edges\": ["

  first=1
  if [[ "$only" != "features" && -n "$m_edges_line" ]]; then
    for pair in ${(s:,:)m_edges_line}; do
      local from="${pair%%::*}"
      local to="${pair##*::}"
      (( first )) || print -- ","
      print -r -- "    {\"from\":\"$from\",\"to\":\"$to\",\"kind\":\"declared\",\"group\":\"module\"}"
      first=0
    done
  fi
  if [[ "$only" != "modules" && -n "$f_edges_line" ]]; then
    for pair in ${(s:,:)f_edges_line}; do
      local from="${pair%%::*}"
      local to="${pair##*::}"
      (( first )) || print -- ","
      print -r -- "    {\"from\":\"$from\",\"to\":\"$to\",\"kind\":\"feature_dep\",\"group\":\"feature\"}"
      first=0
    done
  fi

  print -- "  ]"
  print -- "}"
}

__deps_sanitize_id() {
  # Escape quotes minimally for DOT (IDs are double-quoted)
  local s="$1"
  s="${s//\"/\\\"}"
  print -- "$s"
}

__deps_emit_dot() {
  local only="$1" include_disabled="$2"
  shift 2
  local m_nodes_line="$1" m_edges_line="$2" f_nodes_line="$3" f_edges_line="$4"

  print -- "digraph zsh_deps {"
  print -- "  rankdir=LR;"
  print -- "  node [shape=box,fontsize=11];"

  local declare_node
  declare_node() {
    local id="$1" enabled="$2" group="$3"
    local color fill
    if [[ "$enabled" == "false" ]]; then
      color="gray50"; fill="gray90"
    elif [[ "$enabled" == "unknown" || "$enabled" == "null" ]]; then
      color="goldenrod"; fill="lemonchiffon"
    else
      color="black"; fill="white"
    fi
    local safe_id="$(__deps_sanitize_id "$id")"
    print -- "  \"$safe_id\" [style=filled,fillcolor=\"$fill\",color=\"$color\",label=\"$safe_id\\n($group)\"];"
  }

  local pair id en
  if [[ "$only" != "features" && -n "$m_nodes_line" ]]; then
    for pair in ${(s:,:)m_nodes_line}; do
      id="${pair%%::*}"
      en="${pair##*::}"
      if [[ "$include_disabled" != "1" && "$en" == "false" ]]; then
        continue
      fi
      declare_node "$id" "$en" "module"
    done
  fi

  if [[ "$only" != "modules" && -n "$f_nodes_line" ]]; then
    for pair in ${(s:,:)f_nodes_line}; do
      id="${pair%%::*}"
      en="${pair##*::}"
      if [[ "$include_disabled" != "1" && "$en" == "false" ]]; then
        continue
      fi
      declare_node "$id" "$en" "feature"
    done
  fi

  local emit_edge
  emit_edge() {
    local from="$1" to="$2" kind="$3"
    print -- "  \"${from//\"/\\\"}\" -> \"${to//\"/\\\"}\" [label=\"$kind\",fontsize=9];"
  }

  local p from to
  if [[ "$only" != "features" && -n "$m_edges_line" ]]; then
    for p in ${(s:,:)m_edges_line}; do
      from="${p%%::*}"
      to="${p##*::}"
      emit_edge "$from" "$to" "decl"
    done
  fi
  if [[ "$only" != "modules" && -n "$f_edges_line" ]]; then
    for p in ${(s:,:)f_edges_line}; do
      from="${p%%::*}"
      to="${p##*::}"
      emit_edge "$from" "$to" "feat"
    done
  fi

  print -- "}"
}

# -----------------------------
# Public API
# -----------------------------

zf::deps::export() {
  local format="json"
  local output="-"
  local include_disabled=1   # (future: allow filtering)
  local only="all"
  local no_header=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --format=*)
        format="${1#*=}"
        ;;
      --format)
        shift; format="$1"
        ;;
      --output=*)
        output="${1#*=}"
        ;;
      --output|-o)
        shift; output="$1"
        ;;
      --include-disabled)
        include_disabled=1
        ;;
      --exclude-disabled)
        include_disabled=0
        ;;
      --only=*)
        only="${1#*=}"
        ;;
      --only)
        shift; only="$1"
        ;;
      --no-header)
        no_header=1
        ;;
      -h|--help)
        print "Usage: zf::deps::export [--format=json|dot] [--output <file>|-] [--only=modules|features|all]"
        print "                         [--include-disabled|--exclude-disabled] [--no-header]"
        return 0
        ;;
      *)
        __deps_echo_err "Unknown argument: $1"
        return 1
        ;;
    esac
    shift
  done

  case "$format" in
    json|dot) ;;
    *)
      __deps_echo_err "Unsupported format: $format"
      return 1
      ;;
  esac

  if [[ "$only" != "modules" && "$only" != "features" && "$only" != "all" ]]; then
    __deps_echo_err "Invalid value for --only (expected modules|features|all): $only"
    return 1
  fi

  local m_nodes m_edges f_nodes f_edges
  # Removed duplicate invocations of __deps_collect_modules (was called twice).
  # Collection now performed once in the block below.
  # Optimization: capture once
  {
    read -r m_nodes_line
    read -r m_edges_line
  } < <(__deps_collect_modules || true)
  m_nodes="$m_nodes_line"
  m_edges="$m_edges_line"

  {
    read -r f_nodes_line
    read -r f_edges_line
  } < <(__deps_collect_features || true)
  f_nodes="$f_nodes_line"
  f_edges="$f_edges_line"

  local tmp out_target="$output"
  if [[ "$out_target" != "-" ]]; then
    tmp="$(mktemp 2>/dev/null || mktemp -t deps_export)"
  fi

  if [[ "$format" == "json" ]]; then
    __deps_emit_json "$only" "$include_disabled" "$m_nodes" "$m_edges" "$f_nodes" "$f_edges" > "${tmp:-/dev/stdout}"
  else
    if (( no_header == 0 )); then
      print -- "/* deps-export format=dot generated_at=$(__deps_iso8601) */" > "${tmp:-/dev/stdout}"
    fi
    __deps_emit_dot "$only" "$include_disabled" "$m_nodes" "$m_edges" "$f_nodes" "$f_edges" >> "${tmp:-/dev/stdout}"
  fi

  if [[ "$out_target" != "-" ]]; then
    if ! mv "${tmp}" "$out_target" 2>/dev/null; then
      __deps_echo_err "Failed to write output to $out_target"
      rm -f "${tmp}" 2>/dev/null || true
      return 1
    fi
    print -- "[deps-export] wrote ${format} graph to ${out_target}"
  fi

  return 0
}

# -----------------------------
# CLI Entry Point (if executed)
# -----------------------------
if [[ "${(%):-%N}" == *"deps-export.zsh" ]] && [[ "${BASH_SOURCE:-$0}" == *"deps-export.zsh" ]]; then
  # If sourced into an environment with zf::deps::export already defined,
  # calling directly ensures consistent UX:
  zf::deps::export "$@"
fi

# EOF
