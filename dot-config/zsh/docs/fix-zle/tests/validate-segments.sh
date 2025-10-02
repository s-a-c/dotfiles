#!/usr/bin/env bash
#
# validate-segments.sh - Segment Instrumentation Schema Validator
#
# Validates a segment instrumentation JSON document against the draft/stable
# schema defined in segment-schema.md (Rules R-001 through R-010).
#
# Features:
#   * Prefer jq if available (robust parsing).
#   * Fallback "grep/awk" heuristic parser (best-effort) when jq absent.
#   * Rule-by-rule reporting with pass/fail counts.
#   * Optional strict mode (treat warnings as errors).
#   * Optional stats summary.
#
# Usage:
#   ./validate-segments.sh path/to/segments.json
#   ./validate-segments.sh --strict --stats segments.sample.json
#
# Options:
#   --strict        Fail on any warning (default: warnings do not fail).
#   --stats         Print aggregate stats after validation.
#   --jq-only       Require jq (fail if jq not present).
#   --quiet         Suppress per-rule output (only exit code).
#   --help          Show help.
#
# Exit Codes:
#   0  All required rules passed.
#   1  Validation failure (one or more required rules violated).
#   2  Fatal error (file unreadable / JSON parse impossible).
#
# Rules (summary):
#   R-001 schema_version semver
#   R-002 segment.order strictly increasing
#   R-003 duration_ms == end_ms - start_ms per segment
#   R-004 aggregate.segment_count == number of segments
#   R-005 aggregate status counts match segment statuses
#   R-006 status=fail => errors array length > 0
#   R-007 aggregate.total_duration_ms == latest_end_ms - earliest_start_ms
#   R-008 checksum: if sha256: prefix then 64 hex chars
#   R-009 widget_delta informational (never fails; warns if inconsistent form)
#   R-010 segment.id format seg-###-kebab
#   R-011 parent_id must reference an earlier segment id
#   R-012 depth consistency (root depth=0; child depth=parent+1; depth=0 only for roots)
#   R-013 rss_delta_kb consistency (rss_end_kb - rss_start_kb)
#   R-014 rss_delta_kb cannot appear unless both rss_start_kb & rss_end_kb present
#   R-015 mem_class enumerated (neutral|cache_growth|expected_increase|leak_suspect)
#   R-016 depth monotonic derivation (advisory unless --strict)
#
# Notes:
#   * Fallback parser is heuristic; for authoritative CI gating, install jq.
#   * This validator does not attempt full JSON Schema validation— only the
#     explicitly enumerated semantic rules needed by project policy.
#
# -----------------------------------------------------------------------------

set -euo pipefail

STRICT=0
STATS=0
JQ_ONLY=0
QUIET=0
FILE=""

_color() {
  local code="$1"; shift
  if [[ -t 1 ]]; then printf "\033[%sm%s\033[0m" "$code" "$*"; else printf "%s" "$*"; fi
}

ok()    { ((QUIET)) || printf "%s %s\n" "$(_color 32 '✔')" "$*"; }
warn()  { ((QUIET)) || printf "%s %s\n" "$(_color 33 '⚠')" "$*"; }
fail()  { ((QUIET)) || printf "%s %s\n" "$(_color 31 '✖')" "$*"; }

usage() {
  grep '^# ' "$0" | sed 's/^# //'
}

while (($#)); do
  case "$1" in
    --strict) STRICT=1 ;;
    --stats) STATS=1 ;;
    --jq-only) JQ_ONLY=1 ;;
    --quiet) QUIET=1 ;;
    --help|-h)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
    *)
      FILE="$1"
      ;;
  esac
  shift
done

[[ -n "$FILE" ]] || { echo "No input file provided." >&2; exit 2; }
[[ -f "$FILE" ]] || { echo "File not found: $FILE" >&2; exit 2; }

HAVE_JQ=0
if command -v jq >/dev/null 2>&1; then
  HAVE_JQ=1
else
  if (( JQ_ONLY )); then
    echo "jq required but not found (use --jq-only to force requirement)." >&2
    exit 2
  fi
fi

# Collect results
FAILED=0
WARNED=0
RULES_CHECKED=0

# Utilities for jq path
if (( HAVE_JQ )); then
  # Basic validity
  if ! jq -e . "$FILE" >/dev/null 2>&1; then
    fail "FATAL: JSON parse failure (jq)."
    exit 2
  fi
fi

# Helper functions
record_fail() {
  ((FAILED++))
  fail "$1"
}
record_warn() {
  ((WARNED++))
  warn "$1"
}
record_ok() {
  ok "$1"
}
inc_rule() { ((RULES_CHECKED++)); }

# -----------------------------------------------------------------------------
# JQ IMPLEMENTATION
# -----------------------------------------------------------------------------
if (( HAVE_JQ )); then
  # R-001: schema_version semver
  inc_rule
  SCHEMA_VERSION=$(jq -r '.schema_version // empty' "$FILE")
  if [[ -z "$SCHEMA_VERSION" ]]; then
    record_fail "R-001: schema_version missing"
  elif [[ "$SCHEMA_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9._-]+)?$ ]]; then
    record_ok "R-001: schema_version='$SCHEMA_VERSION'"
  else
    record_fail "R-001: schema_version '$SCHEMA_VERSION' invalid semver format"
  fi

  # Extract segments as an array length
  SEG_COUNT=$(jq -r '.segments | length' "$FILE" 2>/dev/null || echo 0)

  # R-002: segment.order strictly increasing
  inc_rule
  ORDERS=($(jq -r '.segments[]?.order' "$FILE" 2>/dev/null || true))
  if (( ${#ORDERS[@]} == 0 )); then
    record_ok "R-002: no segments (vacuous pass)"
  else
    PREV=-1
    STRICT_OK=1
    for o in "${ORDERS[@]}"; do
      if ! [[ "$o" =~ ^[0-9]+$ ]]; then
        STRICT_OK=0; record_fail "R-002: non-integer order '$o'"; break
      fi
      if (( o <= PREV )); then
        STRICT_OK=0; record_fail "R-002: order not strictly increasing (prev=$PREV current=$o)"; break
      fi
      PREV=$o
    done
    ((STRICT_OK)) && record_ok "R-002: order strictly increasing"
  fi

  # R-003: duration_ms == end_ms - start_ms
  inc_rule
  DUR_MISMATCH=$(jq -r '
    [.segments[]? |
      select( (.duration_ms // -1) != ((.end_ms // 0) - (.start_ms // 0)) ) |
      .id] | length' "$FILE")
  if [[ "$DUR_MISMATCH" =~ ^[0-9]+$ ]] && (( DUR_MISMATCH == 0 )); then
    record_ok "R-003: all segment durations consistent"
  else
    BAD_IDS=$(jq -r '
      [.segments[]? |
        select( (.duration_ms // -1) != ((.end_ms // 0) - (.start_ms // 0)) ) |
        .id] | join(",")' "$FILE")
    record_fail "R-003: duration mismatch for segments: ${BAD_IDS:-(unlisted)}"
  fi

  # R-004: aggregate.segment_count matches
  inc_rule
  AGG_COUNT=$(jq -r '.aggregate.segment_count // empty' "$FILE")
  if [[ -z "$AGG_COUNT" ]]; then
    record_fail "R-004: aggregate.segment_count missing"
  elif ! [[ "$AGG_COUNT" =~ ^[0-9]+$ ]]; then
    record_fail "R-004: aggregate.segment_count not integer"
  elif (( AGG_COUNT != SEG_COUNT )); then
    record_fail "R-004: mismatch aggregate.segment_count=$AGG_COUNT actual=$SEG_COUNT"
  else
    record_ok "R-004: segment_count consistent ($SEG_COUNT)"
  fi

  # R-005: status counts match
  inc_rule
  OKS=$(jq '[.segments[]? | select(.status=="ok")] | length' "$FILE")
  PARTIALS=$(jq '[.segments[]? | select(.status=="partial")] | length' "$FILE")
  FAILS=$(jq '[.segments[]? | select(.status=="fail")] | length' "$FILE")

  AGG_OK=$(jq -r '.aggregate.ok_segments // -1' "$FILE")
  AGG_PAR=$(jq -r '.aggregate.partial_segments // -1' "$FILE")
  AGG_FAIL=$(jq -r '.aggregate.failed_segments // -1' "$FILE")

  if (( OKS == AGG_OK && PARTIALS == AGG_PAR && FAILS == AGG_FAIL )); then
    record_ok "R-005: status counts match (ok=$OKS partial=$PARTIALS fail=$FAILS)"
  else
    record_fail "R-005: mismatch agg(ok=$AGG_OK partial=$AGG_PAR fail=$AGG_FAIL) actual(ok=$OKS partial=$PARTIALS fail=$FAILS)"
  fi

  # R-006: fail segments must have non-empty errors
  inc_rule
  BAD_FAILS=$(jq -r '
    [.segments[]? |
      select(.status=="fail") |
      select( (.errors | type != "array") or ((.errors | length) == 0) ) |
      .id] | length' "$FILE")
  if (( BAD_FAILS == 0 )); then
    record_ok "R-006: all fail segments have non-empty errors"
  else
    IDS=$(jq -r '
      [.segments[]? |
        select(.status=="fail") |
        select( (.errors | type != "array") or ((.errors | length)==0) ) |
        .id] | join(",")' "$FILE")
    record_fail "R-006: failing segments missing errors: ${IDS:-(none listed)}"
  fi

  # R-007: total_duration consistency
  inc_rule
  if (( SEG_COUNT == 0 )); then
    # Accept aggregate values as either zero or present; trivial pass
    record_ok "R-007: no segments (vacuous pass)"
  else
    CALC=$(jq -r '
      (([.segments[]?.start_ms] | min) // 0) as $min
      | (([.segments[]?.end_ms] | max) // 0) as $max
      | ($max - $min)' "$FILE")
    AGG_TOTAL=$(jq -r '.aggregate.total_duration_ms // -1' "$FILE")
    if ! [[ "$CALC" =~ ^-?[0-9]+$ && "$AGG_TOTAL" =~ ^-?[0-9]+$ ]]; then
      record_fail "R-007: invalid numeric values for total duration (calc=$CALC agg=$AGG_TOTAL)"
    elif (( CALC == AGG_TOTAL )); then
      record_ok "R-007: total_duration_ms consistent ($AGG_TOTAL)"
    else
      record_fail "R-007: total_duration_ms mismatch (calc=$CALC agg=$AGG_TOTAL)"
    fi
  fi

  # R-008: checksum format if sha256:
  inc_rule
  CHECKSUM=$(jq -r '.integrity.checksum // empty' "$FILE")
  if [[ -z "$CHECKSUM" ]]; then
    record_warn "R-008: checksum missing (allowed in draft)"
  elif [[ "$CHECKSUM" =~ ^sha256:([0-9a-fA-F]{64})$ ]]; then
    record_ok "R-008: checksum sha256 format valid"
  elif [[ "$CHECKSUM" == "sha256:NOT_COMPUTED" ]]; then
    record_warn "R-008: placeholder checksum (draft acceptable)"
  else
    record_fail "R-008: checksum invalid format '$CHECKSUM'"
  fi

  # R-009: widget_delta informational
  inc_rule
  WDELTA=$(jq -r '.aggregate.widget_delta // empty' "$FILE")
  if [[ -n "$WDELTA" && ! "$WDELTA" =~ ^-?[0-9]+$ && "$WDELTA" != "null" ]]; then
    record_warn "R-009: widget_delta not integer/null ($WDELTA)"
  else
    record_ok "R-009: widget_delta format acceptable"
  fi

  # R-010: segment id pattern
  inc_rule
  BAD_IDS=$(jq -r '
    [.segments[]? |
      select( (.id // "") | test("^seg-[0-9]{3}-[a-z0-9-]+$") | not ) |
      .id] | length' "$FILE")
  if (( BAD_IDS == 0 )); then
    record_ok "R-010: all segment ids match pattern"
  else
    IDS=$(jq -r '
      [.segments[]? |
        select( (.id // "") | test("^seg-[0-9]{3}-[a-z0-9-]+$") | not ) |
        .id] | join(",")' "$FILE")
    record_fail "R-010: invalid segment id(s): ${IDS:-(unlisted)}"
  fi

  # -------------------------
  # D14 Draft Rules (R-011..R-016)
  # -------------------------

  # R-011: parent_id must reference an earlier segment id
  inc_rule
  PARENT_VIOLATIONS=$(jq -r '
    ( [ ] ) as $seen
    | [ foreach .segments[]? as $s ( {seen:[],bad:[]} ;
          .seen += [ $s.id ]
          | if ( ($s.parent_id? // "") != "" and ( (.saw // []) | length ) == -1 ) then . else . end
        )
      ]
    ' "$FILE" 2>/dev/null || echo "")
  # Simpler second pass (explicit):
  PARENT_BAD=$(jq -r '
    ([] ) as $acc
    | reduce range(0; (.segments|length)) as $i (
        {bad:[], prior:[]} ;
        .seg = (.segments[$i])
        | .bad += ( if (.seg.parent_id? // "") != "" and ( (.prior | index(.seg.parent_id)) | not ) then [ .seg.id ] else [] end )
        | .prior += [ .seg.id ]
      ) | .bad | join(",")
  ' "$FILE")
  if [[ -z "$PARENT_BAD" ]]; then
    record_ok "R-011: parent_id references valid earlier ids"
  else
    record_fail "R-011: invalid parent reference(s): $PARENT_BAD"
  fi

  # Build maps for depth / memory rules
  SEG_WITH_META_JSON=$(jq -c '.segments[]? | {id, parent_id, depth, rss_start_kb, rss_end_kb, rss_delta_kb, mem_class}' "$FILE")
  declare -A DEPTH_MAP
  while IFS= read -r row; do
    sid=$(echo "$row" | jq -r '.id')
    dval=$(echo "$row" | jq -r '.depth // ""')
    [[ "$dval" != "" && "$dval" != "null" ]] && DEPTH_MAP["$sid"]="$dval"
  done <<<"$SEG_WITH_META_JSON"

  # R-012: depth consistency
  inc_rule
  D12_FAILS=()
  while IFS= read -r row; do
    sid=$(echo "$row" | jq -r '.id')
    parent=$(echo "$row" | jq -r '.parent_id // ""')
    depth=$(echo "$row" | jq -r '.depth // ""')
    if [[ -n "$depth" ]]; then
      if [[ -z "$parent" && "$depth" != "0" ]]; then
        D12_FAILS+=("$sid")
      elif [[ -n "$parent" ]]; then
        pdepth="${DEPTH_MAP[$parent]:-}"
        if [[ -n "$pdepth" && "$depth" != "$((pdepth+1))" ]]; then
          D12_FAILS+=("$sid")
        fi
      fi
    fi
  done <<<"$SEG_WITH_META_JSON"
  if (( ${#D12_FAILS[@]} == 0 )); then
    record_ok "R-012: depth consistency satisfied"
  else
    record_fail "R-012: depth inconsistency in: ${D12_FAILS[*]}"
  fi

  # R-013: rss_delta_kb consistency
  inc_rule
  D13_FAILS=$(jq -r '
    [ .segments[]? |
      select( (.rss_start_kb? != null) and (.rss_end_kb? != null) and (.rss_delta_kb? != null)
              and (.rss_delta_kb != (.rss_end_kb - .rss_start_kb)) ) |
      .id ] | join(",")' "$FILE")
  if [[ -z "$D13_FAILS" ]]; then
    record_ok "R-013: rss_delta_kb consistency ok"
  else
    record_fail "R-013: rss_delta_kb mismatch in: $D13_FAILS"
  fi

  # R-014: rss_delta_kb only if both start & end present
  inc_rule
  D14_FAILS=$(jq -r '
    [ .segments[]? |
      select( (.rss_delta_kb? != null) and ( (.rss_start_kb? == null) or (.rss_end_kb? == null) ) ) |
      .id ] | join(",")' "$FILE")
  if [[ -z "$D14_FAILS" ]]; then
    record_ok "R-014: rss_delta_kb presence valid"
  else
    record_fail "R-014: rss_delta_kb present without both endpoints (segments: $D14_FAILS)"
  fi

  # R-015: mem_class enumeration
  inc_rule
  D15_FAILS=$(jq -r '
    [ .segments[]? |
      select( .mem_class? != null and (.mem_class | test("^(neutral|cache_growth|expected_increase|leak_suspect)$") | not) ) |
      .id ] | join(",")' "$FILE")
  if [[ -z "$D15_FAILS" ]]; then
    record_ok "R-015: mem_class enumeration valid"
  else
    record_fail "R-015: invalid mem_class in: $D15_FAILS"
  fi

  # R-016: depth monotonic derivation (advisory unless --strict)
  inc_rule
  D16_WARN=$(jq -r '
    ( [] ) as $prior
    | reduce .segments[]? as $s (
        {warn:[], stack:[], map:{}} ;
        .map[$s.id] = ($s.depth // null)
        | .warn += (
            if ($s.parent_id? // "") != "" and
               ( ($s.depth? // null) != null ) and
               ( ($s.parent_id as $p | .map[$p]? // null) != null ) and
               ( ($s.depth) != (.map[$s.parent_id]+1) )
            then [ $s.id ] else [] end
          )
      ) | .warn | join(",")
  ' "$FILE")
  if [[ -z "$D16_WARN" ]]; then
    record_ok "R-016: depth derivation satisfied"
  else
    if (( STRICT == 1 )); then
      record_fail "R-016: depth derivation advisory violation (strict fail): $D16_WARN"
    else
      record_warn "R-016: depth derivation advisory warning: $D16_WARN"
    fi
  fi

else
# -----------------------------------------------------------------------------
# FALLBACK HEURISTIC IMPLEMENTATION (NO jq)
# -----------------------------------------------------------------------------
  warn "jq not found; using heuristic fallback parser (reduced reliability)."

  JSON=$(cat "$FILE")

  # Helper: extract values by naive regex (line-insensitive)
  _extract_all() {
    # $1 pattern
    echo "$JSON" | grep -Eo "$1" || true
  }

  # R-001
  inc_rule
  if echo "$JSON" | grep -qi '"schema_version"'; then
    VER=$(echo "$JSON" | grep -Eo '"schema_version"[[:space:]]*:[[:space:]]*"[^"]+"' | head -n1 | sed -E 's/.*"schema_version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    if [[ "$VER" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9._-]+)?$ ]]; then
      record_ok "R-001: schema_version='$VER'"
    else
      record_fail "R-001: schema_version invalid ($VER)"
    fi
  else
    record_fail "R-001: schema_version missing"
  fi

  # Approx segment blocks
  SEG_IDS=($(echo "$JSON" | grep -Eo '"id"[[:space:]]*:[[:space:]]*"seg-[^"]+"' | sed -E 's/.*"id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'))
  ORDERS=($(echo "$JSON" | grep -Eo '"order"[[:space:]]*:[[:space:]]*[0-9]+' | sed -E 's/.*"order"[[:space:]]*:[[:space:]]*([0-9]+)/\1/'))
  DURATIONS=($(echo "$JSON" | grep -Eo '"duration_ms"[[:space:]]*:[[:space:]]*-?[0-9]+' | sed -E 's/.*"duration_ms"[[:space:]]*:[[:space:]]*(-?[0-9]+)/\1/'))
  STARTS=($(echo "$JSON" | grep -Eo '"start_ms"[[:space:]]*:[[:space:]]*-?[0-9]+' | sed -E 's/.*"start_ms"[[:space:]]*:[[:space:]]*(-?[0-9]+)/\1/'))
  ENDS=($(echo "$JSON" | grep -Eo '"end_ms"[[:space:]]*:[[:space:]]*-?[0-9]+' | sed -E 's/.*"end_ms"[[:space:]]*:[[:space:]]*(-?[0-9]+)/\1/'))

  # R-002
  inc_rule
  if (( ${#ORDERS[@]} == 0 )); then
    record_ok "R-002: no segments (vacuous pass)"
  else
    PREV=-1; OK_INC=1
    for o in "${ORDERS[@]}"; do
      if (( o <= PREV )); then OK_INC=0; record_fail "R-002: non-increasing order at $o"; break; fi
      PREV=$o
    done
    ((OK_INC)) && record_ok "R-002: order strictly increasing"
  fi

  # R-003 (heuristic: align arrays; may mismatch if JSON not uniform)
  inc_rule
  if (( ${#STARTS[@]} == ${#ENDS[@]} && ${#ENDS[@]} == ${#DURATIONS[@]} )); then
    BAD=0
    for ((i=0;i<${#DURATIONS[@]};i++)); do
      calc=$((ENDS[i]-STARTS[i]))
      if (( calc != DURATIONS[i] )); then BAD=1; break; fi
    done
    if (( BAD == 0 )); then
      record_ok "R-003: durations consistent (heuristic)"
    else
      record_fail "R-003: duration mismatch detected (heuristic)"
    fi
  else
    record_warn "R-003: inconsistent arrays; skipping duration check"
  fi

  # R-004: count segments vs aggregate.segment_count
  inc_rule
  DECLARED=$(echo "$JSON" | grep -Eo '"segment_count"[[:space:]]*:[[:space:]]*[0-9]+' | sed -E 's/.*"segment_count"[[:space:]]*:[[:space:]]*([0-9]+)/\1/' | head -n1)
  ACTUAL=${#ORDERS[@]}
  if [[ -z "$DECLARED" ]]; then
    record_fail "R-004: aggregate.segment_count missing"
  elif (( DECLARED != ACTUAL )); then
    record_fail "R-004: segment_count mismatch declared=$DECLARED actual=$ACTUAL"
  else
    record_ok "R-004: segment_count consistent ($ACTUAL)"
  fi

  # R-005 heuristic (counts status occurrences)
  inc_rule
  S_OK=$(echo "$JSON" | grep -Eoc '"status"[[:space:]]*:[[:space:]]*"ok"') || true
  S_PAR=$(echo "$JSON" | grep -Eoc '"status"[[:space:]]*:[[:space:]]*"partial"') || true
  S_FAIL=$(echo "$JSON" | grep -Eoc '"status"[[:space:]]*:[[:space:]]*"fail"') || true
  A_OK=$(echo "$JSON" | grep -Eo '"ok_segments"[[:space:]]*:[[:space:]]*[0-9]+' | sed -E 's/.*"ok_segments"[[:space:]]*:[[:space:]]*([0-9]+)/\1/' | head -n1)
  A_PAR=$(echo "$JSON" | grep -Eo '"partial_segments"[[:space:]]*:[[:space:]]*[0-9]+' | sed -E 's/.*"partial_segments"[[:space:]]*:[[:space:]]*([0-9]+)/\1/' | head -n1)
  A_FAIL=$(echo "$JSON" | grep -Eo '"failed_segments"[[:space:]]*:[[:space:]]*[0-9]+' | sed -E 's/.*"failed_segments"[[:space:]]*:[[:space:]]*([0-9]+)/\1/' | head -n1)
  if [[ -z "$A_OK" || -z "$A_PAR" || -z "$A_FAIL" ]]; then
    record_fail "R-005: aggregate status fields missing"
  elif (( S_OK == A_OK && S_PAR == A_PAR && S_FAIL == A_FAIL )); then
    record_ok "R-005: status counts match"
  else
    record_fail "R-005: mismatch agg(ok=$A_OK partial=$A_PAR fail=$A_FAIL) actual(ok=$S_OK partial=$S_PAR fail=$S_FAIL)"
  fi

  # R-006 fail segments need errors (heuristic presence of '"status":"fail"' lines followed by '"errors"')
  inc_rule
  FAIL_SEG_LINES=$(echo "$JSON" | grep -n '"status"[[:space:]]*:[[:space:]]*"fail"' || true)
  MISSING=0
  while IFS=: read -r ln _; do
    [[ -z "$ln" ]] && continue
    # Search next ~10 lines for "errors":
    if ! sed -n "$((ln)),$((ln+10))p" "$FILE" | grep -q '"errors"[[:space:]]*:'; then
      MISSING=1; break
    fi
  done <<<"$FAIL_SEG_LINES"
  if (( MISSING == 0 )); then
    record_ok "R-006: fail segments have errors (heuristic)"
  else
    record_fail "R-006: missing errors for at least one fail segment (heuristic)"
  fi

  # R-007 total duration heuristic (skip if absent)
  inc_rule
  T_DUR=$(echo "$JSON" | grep -Eo '"total_duration_ms"[[:space:]]*:[[:space:]]*-?[0-9]+' | head -n1 | sed -E 's/.*"total_duration_ms"[[:space:]]*:[[:space:]]*(-?[0-9]+)/\1/')
  if (( ${#STARTS[@]} > 0 && ${#ENDS[@]} > 0 )); then
    MIN=${STARTS[0]}; MAX=${ENDS[0]}
    for s in "${STARTS[@]}"; do (( s < MIN )) && MIN=$s; done
    for e in "${ENDS[@]}"; do (( e > MAX )) && MAX=$e; done
    CALC=$((MAX - MIN))
    if [[ -z "$T_DUR" ]]; then
      record_fail "R-007: total_duration_ms missing"
    elif (( T_DUR == CALC )); then
      record_ok "R-007: total_duration_ms consistent (heuristic)"
    else
      record_fail "R-007: total_duration_ms mismatch (calc=$CALC agg=$T_DUR)"
    fi
  else
    record_ok "R-007: no segments / insufficient timing (vacuous)"
  fi

  # R-008 checksum
  inc_rule
  CK=$(echo "$JSON" | grep -Eo '"checksum"[[:space:]]*:[[:space:]]*"[^"]+"' | sed -E 's/.*"checksum"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' | head -n1)
  if [[ -z "$CK" ]]; then
    record_warn "R-008: checksum missing"
  elif [[ "$CK" == sha256:NOT_COMPUTED ]]; then
    record_warn "R-008: placeholder checksum"
  elif [[ "$CK" =~ ^sha256:[0-9a-fA-F]{64}$ ]]; then
    record_ok "R-008: checksum sha256 valid"
  else
    record_fail "R-008: invalid checksum format ($CK)"
  fi

  # R-009 widget_delta
  inc_rule
  WD=$(echo "$JSON" | grep -Eo '"widget_delta"[[:space:]]*:[[:space:]]*[^,} ]+' | head -n1 | sed -E 's/.*"widget_delta"[[:space:]]*:[[:space:]]*([^,} ]+).*/\1/')
  if [[ -n "$WD" && "$WD" != "null" && ! "$WD" =~ ^-?[0-9]+$ ]]; then
    record_warn "R-009: widget_delta not integer/null ($WD)"
  else
    record_ok "R-009: widget_delta format acceptable"
  fi

  # R-010 id pattern
  inc_rule
  BAD_ID=0
  for id in "${SEG_IDS[@]}"; do
    [[ "$id" =~ ^seg-[0-9]{3}-[a-z0-9-]+$ ]] || { BAD_ID=1; break; }
  done
  if (( BAD_ID == 0 )); then
    record_ok "R-010: segment ids match pattern (heuristic)"
  else
    record_fail "R-010: invalid segment id(s) detected"
  fi
fi

# -----------------------------------------------------------------------------
# Stats / Summary
# -----------------------------------------------------------------------------
if (( STATS && ! QUIET )); then
  echo ""
  echo "Validation Summary:"
  echo "  Rules Checked : $RULES_CHECKED"
  echo "  Failures      : $FAILED"
  echo "  Warnings      : $WARNED"
  echo "  Strict Mode   : $STRICT"
fi

# Strict mode escalates warnings
if (( STRICT && WARNED > 0 )); then
  FAILED=$((FAILED + WARNED))
fi

if (( FAILED > 0 )); then
  ((QUIET)) || echo "$(_color 31 'Result: FAIL')"
  exit 1
fi

((QUIET)) || echo "$(_color 32 'Result: PASS')"
exit 0
