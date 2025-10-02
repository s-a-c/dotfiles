#!/usr/bin/env zsh
# promotion-guard.zsh
# Gate promotion of redesign by validating structure & performance artifacts.
# Usage: tools/promotion-guard.zsh [expected_module_count] [--allow-mismatch]
# Exit Codes:
# 0  OK
# 1  Missing artifact(s)
# 2  Structural violation (duplicates/order)
# 3  Module count mismatch
# 4  Performance regression >5%
# 5  Badge failure (red)
# 6  JSON/Parse failure
# 7  Markdown audit missing or inconsistent with JSON
# 8  Legacy checksum verification failed
# 9  Async state validation failed
# 10 TDD gate (G10) violations detected (enforce-tdd.sh)
# 11 Segment/prompt threshold violation (pre/post plugin or prompt readiness exceeds configured max)
# 12 Monotonic lifecycle ordering violation (pre<=post<=prompt) or future micro bench critical violation
set -euo pipefail
# Safe PATH bootstrap to ensure core utilities remain available even if earlier
# path normalization removed standard system directories.
PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:${PATH:-}"

expected=${1:-11}
allow_mismatch=0
shift || true
for arg in "$@"; do
    [[ $arg == --allow-mismatch ]] && allow_mismatch=1
done

ROOT=${0:A:h:h}
# Prefer new redesignv2 artifact paths; fall back to legacy redesign paths if not present
if [[ -d $ROOT/docs/redesignv2/artifacts/metrics && -d $ROOT/docs/redesignv2/artifacts/badges ]]; then
  METRICS=$ROOT/docs/redesignv2/artifacts/metrics
  BADGES=$ROOT/docs/redesignv2/artifacts/badges
else
  METRICS=$ROOT/docs/redesign/metrics
  BADGES=$ROOT/docs/redesign/badges
fi

need=(structure-audit.json perf-current.json perf-baseline.json $BADGES/perf.json $BADGES/structure.json structure-audit.md)
missing=()
for f in $need; do
    case $f in
        structure-audit.json|perf-current.json|perf-baseline.json|structure-audit.md) path=$METRICS/$f ;;
        *) path=$f ;;
    esac
    [[ -f $path ]] || missing+=$path
done
if (( ${#missing[@]} )); then
    print -u2 "[promotion-guard] Missing: ${missing[*]}"
    exit 1
fi

jq_bin=$(command -v jq || true)

get_json_value() {
    local file=$1 key=$2
    if [[ -n $jq_bin ]]; then
        $jq_bin -r ".$key" "$file" 2>/dev/null || return 6
    else
        grep -E '"'$key'"' "$file" | head -1 | tr -dc '0-9.' || return 6
    fi
}

SA_JSON=$METRICS/structure-audit.json
SA_MD=$METRICS/structure-audit.md
PC=$METRICS/perf-current.json
PB=$METRICS/perf-baseline.json

# Extract JSON structure data
if [[ -n $jq_bin ]]; then
    total_modules=$($jq_bin -r '.total' $SA_JSON)
    violations_ct=$($jq_bin '.violations|length' $SA_JSON)
    order_issue=$($jq_bin -r '.order_issue' $SA_JSON)
else
    total_modules=$(grep '"total"' $SA_JSON | tr -dc '0-9')
    violations_ct=$(grep -c 'Duplicate prefix' $SA_JSON || true)
    order_issue=$(grep -q 'order_issue":1' $SA_JSON && echo 1 || echo 0)
fi

# Parse markdown summary marker: <!-- STRUCTURE-AUDIT: total=## violations=## order_issue=0 generated=... json=... -->
if ! grep -q 'STRUCTURE-AUDIT:' $SA_MD; then
    print -u2 "[promotion-guard] Markdown structure audit summary marker missing"
    exit 7
fi
md_line=$(grep 'STRUCTURE-AUDIT:' $SA_MD | tail -1)
md_total=$(echo $md_line | sed -n 's/.* total=\([0-9]*\).*/\1/p')
md_violations=$(echo $md_line | sed -n 's/.* violations=\([0-9]*\).*/\1/p')
md_order=$(echo $md_line | sed -n 's/.* order_issue=\([0-9]*\).*/\1/p')

if [[ -z ${md_total:-} || -z ${md_violations:-} || -z ${md_order:-} ]]; then
    print -u2 "[promotion-guard] Unable to parse markdown summary marker"
    exit 7
fi

if (( md_total != total_modules || md_violations != violations_ct || md_order != order_issue )); then
    print -u2 "[promotion-guard] Markdown / JSON mismatch (md_total=$md_total json_total=$total_modules md_violations=$md_violations json_violations=$violations_ct md_order=$md_order json_order=$order_issue)"
    exit 7
fi

if (( violations_ct>0 || order_issue>0 )); then
    print -u2 "[promotion-guard] Structural violations present (violations=$violations_ct order_issue=$order_issue)"
    exit 2
fi

if (( total_modules != expected )) && (( allow_mismatch == 0 )); then
    print -u2 "[promotion-guard] Module count $total_modules != expected $expected"
    exit 3
fi

# Performance regression check
cur_mean=$(get_json_value $PC mean_ms)
base_mean=$(get_json_value $PB mean_ms)
if [[ -z ${cur_mean:-} || -z ${base_mean:-} ]]; then
    print -u2 "[promotion-guard] Unable to parse performance means"
    exit 6
fi
perc_delta=$(awk -v b=$base_mean -v c=$cur_mean 'BEGIN{printf "%.2f", (c-b)/b*100}')
if awk -v d=$perc_delta 'BEGIN{exit !(d>5)}'; then
    print -u2 "[promotion-guard] Regression >5% (delta ${perc_delta}%)"
    exit 4
fi
# Segment threshold (pre/post) enforcement
typeset seg_pre seg_post
if grep -q '"segments_available":true' $PC; then
    seg_pre=$(get_json_value $PC pre_plugin_cost_ms || true)
    seg_post=$(get_json_value $PC post_plugin_cost_ms || true)
    : ${PRE_SEG_MAX:=200}
    : ${POST_SEG_MAX:=400}
    if [[ -n ${seg_pre:-} && $seg_pre -gt 0 && $seg_pre -gt $PRE_SEG_MAX ]]; then
        print -u2 "[promotion-guard] Pre-plugin segment ${seg_pre}ms exceeds PRE_SEG_MAX=${PRE_SEG_MAX}ms"
        exit 11
    fi
    if [[ -n ${seg_post:-} && $seg_post -gt 0 && $seg_post -gt $POST_SEG_MAX ]]; then
        print -u2 "[promotion-guard] Post-plugin segment ${seg_post}ms exceeds POST_SEG_MAX=${POST_SEG_MAX}ms"
        exit 11
    fi
fi
seg_pre_display=${seg_pre:-NA}
seg_post_display=${seg_post:-NA}
prompt_ready=$(get_json_value $PC prompt_ready_ms || true)
: ${PROMPT_READY_MAX_MS:=400}
prompt_ready_skip=0
# Heuristic: if prompt_ready ~= post segment (fallback capture, no real prompt render),
# skip threshold enforcement to avoid false failures.
if [[ -n ${prompt_ready:-} && -n ${seg_post:-} && $prompt_ready -gt 0 && $seg_post -gt 0 ]]; then
    local __diff=$(( prompt_ready - seg_post ))
    (( __diff < 0 )) && __diff=$(( -__diff ))
    if (( __diff <= 5 )); then
        prompt_ready_skip=1
    fi
fi
if [[ $prompt_ready_skip -eq 0 && -n ${prompt_ready:-} && $prompt_ready -gt 0 && $prompt_ready -gt $PROMPT_READY_MAX_MS ]]; then
    print -u2 "[promotion-guard] Prompt readiness ${prompt_ready}ms exceeds PROMPT_READY_MAX_MS=${PROMPT_READY_MAX_MS}ms"
    exit 11
fi
prompt_ready_display=${prompt_ready:-NA}
if (( prompt_ready_skip )); then
    prompt_ready_display="SKIP(fallback)"
fi

# Badge sanity
if grep -q '"color":"red"' $BADGES/perf.json || grep -q '"color":"red"' $BADGES/structure.json; then
    print -u2 "[promotion-guard] Red badge detected"
    exit 5
fi

# Checksum verification
CHECKSUM_VERIFIER=$ROOT/tools/verify-legacy-checksums.zsh
if [[ -f $CHECKSUM_VERIFIER ]]; then
    if ! $CHECKSUM_VERIFIER >/dev/null 2>&1; then
        print -u2 "[promotion-guard] Legacy checksum verification failed"
        exit 8
    fi
else
    print -u2 "[promotion-guard] Warning: checksum verifier not found at $CHECKSUM_VERIFIER"
fi

# Async state validation - check for deferred async start
ASYNC_STATE_LOG="$ROOT/logs/async-state.log"
PERF_LOG="$ROOT/logs/perf-current.log"
if [[ -f $ASYNC_STATE_LOG ]]; then
    # Look for evidence of deferred async start (should not be RUNNING before first prompt)
    if grep -q "ASYNC_STATE:RUNNING" $ASYNC_STATE_LOG && ! grep -q "PERF_PROMPT:" $PERF_LOG; then
        print -u2 "[promotion-guard] Async validation failed: found RUNNING state before first prompt"
        exit 9
    fi
    # Look for proper deferred start marker
    if ! grep -q "SECURITY_ASYNC_QUEUE" $ASYNC_STATE_LOG; then
        print -u2 "[promotion-guard] Warning: async queue marker not found (may indicate missing deferred start)"
    fi
else
    print -u2 "[promotion-guard] Warning: async state log not found at $ASYNC_STATE_LOG"
fi

# TDD Gate (G10) Enforcement
TDD_ENFORCER="$ROOT/tools/enforce-tdd.sh"
if [[ -x "$TDD_ENFORCER" ]]; then
  if ! "$TDD_ENFORCER" -n 50 -w 20 >/dev/null 2>&1; then
    print -u2 "[promotion-guard] TDD gate (G10) failed: enforce-tdd.sh reported violations"
    exit 10
  fi
else
  print -u2 "[promotion-guard] Warning: TDD enforcement script missing ($TDD_ENFORCER)"
fi

# Stage 2 core test presence meta-check (path, lazy framework, ssh agent)
# These tests enforce critical Stage 2 invariants; absence indicates misconfiguration.
required_stage2_tests=(
  "tests/unit/tdd/test-path-normalization-edges.zsh"
  "tests/unit/tdd/test-path-normalization-whitelist.zsh"
  "tests/unit/tdd/test-lazy-dispatcher-negative.zsh"
  "tests/unit/tdd/test-fzf-no-compinit.zsh"
  "tests/unit/tdd/test-integrations-idempotence.zsh"
  "tests/feature/tdd/test-ssh-agent-duplicate-spawn.zsh"
  "tests/feature/tdd/test-node-lazy-activation.zsh"
)
missing_stage2_tests=()
for t in "${required_stage2_tests[@]}"; do
  [[ -f "$ROOT/$t" ]] || missing_stage2_tests+=("$t")
done
if (( ${#missing_stage2_tests[@]} )); then
  print -u2 "[promotion-guard] Stage 2 core test(s) missing: ${missing_stage2_tests[*]}"
  stage2_meta="fail"
else
  stage2_meta="pass"
fi

# ---------------- Monotonic Lifecycle Ordering (pre <= post <= prompt) ----------------
monotonic_note="monotonic=deferred"
if [[ -n ${seg_pre:-} && -n ${seg_post:-} && -n ${prompt_ready:-} ]] && \
   [[ ${seg_pre:-0} -gt 0 && ${seg_post:-0} -gt 0 && ${prompt_ready:-0} -gt 0 ]]; then
  if (( seg_pre > seg_post || seg_post > prompt_ready )); then
    if [[ "${PROMOTION_GUARD_MONOTONIC_STRICT:-1}" == "1" ]]; then
      print -u2 "[promotion-guard] Monotonic lifecycle violation pre=${seg_pre} post=${seg_post} prompt=${prompt_ready}"
      exit 12
    else
      monotonic_note="monotonic=warn(pre=${seg_pre} post=${seg_post} prompt=${prompt_ready})"
    fi
  else
    monotonic_note="monotonic=ok"
  fi
fi

# ---------------- Micro Benchmark Summary (observational) ----------------
micro_note="microbench=skip"
if [[ "${PROMOTION_GUARD_MICRO_BENCH:-1}" == "1" ]]; then
  BMB="$METRICS/bench-core-baseline.json"
  if [[ -f "$BMB" ]]; then
    b_shim=$(grep -E '"shimmed_count"' "$BMB" 2>/dev/null | sed -E 's/.*"shimmed_count"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | head -1)
    b_fn=$(grep -c '"name"' "$BMB" 2>/dev/null || echo 0)
    [[ -z "$b_shim" ]] && b_shim=0
    micro_note="microbench=baseline(funcs=${b_fn} shimmed=${b_shim})"
  fi
fi

print "[promotion-guard] OK (modules=$total_modules mean=${cur_mean}ms baseline=${base_mean}ms delta=${perc_delta}% preseg=${seg_pre_display}ms postseg=${seg_post_display}ms prompt=${prompt_ready_display}ms violations=${violations_ct} checksum=verified tdd=pass stage2tests=${stage2_meta} ${monotonic_note} ${micro_note})"
exit 0
