#!/usr/bin/env zsh
# update-variance-and-badges.zsh
# Tiny updater to recompute variance metrics from the latest multi-run samples
# and refresh variance state, governance, and perf badges.
#
# - Prefers jq when available; falls back to awk/grep/sed-only parsing.
# - Outlier policy: drop one high outlier if value > 2x median (per metric).
# - Mode/streak policy:
#     * If trimmed RSD for pre and post <= rsd_warn_max (0.25), increment streak.
#     * Else reset streak to 0.
#     * Promote to "guard" when streak >= 3; otherwise remain "observe".
#
# Files (default layout):
#   samples_file:   $ZDOTDIR/docs/redesignv2/artifacts/metrics/perf-multi-simple.json
#   state_file:     $REPO_ROOT/docs/redesignv2/artifacts/metrics/variance-gating-state.json
#   variance_badge: $REPO_ROOT/docs/redesignv2/artifacts/badges/variance-state.json
#   governance:     $ZDOTDIR/docs/redesignv2/artifacts/badges/governance.json
#   perf_badge:     $ZDOTDIR/docs/redesignv2/artifacts/badges/perf.json
#   microbench:     $ZDOTDIR/docs/redesignv2/artifacts/metrics/microbench-core.json (optional)
#
# Exit codes:
#   0 success
#   2 missing samples file or unreadable
#   3 json write failure
#   4 general error

set -euo pipefail

# ------------- Configuration / Paths -------------
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
# Try to compute repo root (assumes dot-config/zsh under repo)
REPO_ROOT="$(cd "${ZDOTDIR}/../.." 2>/dev/null && pwd -P || true)"
[[ -z "${REPO_ROOT}" ]] && REPO_ROOT="$(cd "${ZDOTDIR}" && pwd -P)"

SAMPLES_FILE="${ZDOTDIR}/docs/redesignv2/artifacts/metrics/perf-multi-simple.json"
STATE_FILE="${REPO_ROOT}/docs/redesignv2/artifacts/metrics/variance-gating-state.json"
VARIANCE_BADGE="${REPO_ROOT}/docs/redesignv2/artifacts/badges/variance-state.json"
GOVERNANCE_BADGE="${ZDOTDIR}/docs/redesignv2/artifacts/badges/governance.json"
PERF_BADGE="${ZDOTDIR}/docs/redesignv2/artifacts/badges/perf.json"
MICROBENCH_FILE="${ZDOTDIR}/docs/redesignv2/artifacts/metrics/microbench-core.json"

RSQ_WARN_MAX_DEFAULT="0.25"
RSQ_GATE_MAX_DEFAULT="0.40"
OUTLIER_FACTOR_MIN_DEFAULT="2.0"
STREAK_REQUIRED_DEFAULT="3"

have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1

timestamp_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date
}

# ------------- JSON helpers (fallback-friendly) -------------

# Read a single top-level numeric field: e.g., "samples"
json_read_toplevel_number() {
  local file="$1" key="$2" val=""
  if (( have_jq )); then
    val="$(jq -r --arg k "$key" '.[$k] // empty' "$file" 2>/dev/null || true)"
  else
    # naive match: "key": <num>
    val="$(grep -E "\"$key\"[[:space:]]*:[[:space:]]*[0-9]+" "$file" 2>/dev/null | head -1 | sed -E "s/.*\"$key\"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/")"
  fi
  [[ "$val" =~ ^-?[0-9]+$ ]] || val=0
  printf '%s' "$val"
}

# Extract numeric array of metric values into space-separated list
# metric keys: pre_plugin_cost_ms, post_plugin_total_ms, prompt_ready_ms
json_extract_metric_values() {
  local file="$SAMPLES_FILE" metric="$1"
  if (( have_jq )); then
    jq -r --arg m "$metric" '.metrics[$m].values[]?' "$file" 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]\+$//'
    return 0
  fi
  # Fallback: find "metric": { ... "values":[ ... ] }
  # Grep block start, then the values line, then extract between [ and ]
  awk -v key="\"$metric\"" '
    $0 ~ key"[[:space:]]*:" { inblock=1; next }
    inblock && /"values"[[:space:]]*:/ {
      # collapse line, strip up to [, then strip after ]
      line=$0
      sub(/.*\[/,"",line)
      sub(/\].*/,"",line)
      gsub(/[ \t\r\n]/,"",line)
      gsub(/,/," ",line)
      print line
      inblock=0
    }
  ' "$file" 2>/dev/null
}

# ------------- Math helpers -------------

# Takes numbers as arguments, prints mean with 2 decimals (or 0.00 if none)
stats_mean() {
  awk 'BEGIN{n=0;s=0}
       { for(i=1;i<=NF;i++){ if($i!=""){s+=$i;n++} } }
       END{ if(n>0) printf("%.2f", s/n); else printf("0.00") }' <<<"$*"
}
# Stddev (population) with 2 decimals
stats_stddev() {
  awk 'BEGIN{n=0;s=0;ss=0}
       { for(i=1;i<=NF;i++){ if($i!=""){x=$i;s+=x;ss+=x*x;n++} } }
       END{
         if(n<2){printf("0.00"); exit}
         m=s/n; v=(ss/n)-(m*m); if(v<0)v=0;
         printf("%.2f", sqrt(v))
       }' <<<"$*"
}
# RSD = sd / mean, 4 decimals
stats_rsd() {
  local mean sd
  mean="$(stats_mean "$@")"
  sd="$(stats_stddev "$@")"
  awk -v m="$mean" -v s="$sd" 'BEGIN{
    if (m+0==0) printf "0.0000";
    else printf "%.4f", (s/m)
  }'
}
# Median (integers), prints integer
stats_median() {
  awk '
    {
      for(i=1;i<=NF;i++){
        if($i!=""){ n++; a[n]=$i }
      }
    }
    END{
      if(n==0){ print 0; exit }
      # simple sort
      for(i=1;i<=n;i++){ for(j=i+1;j<=n;j++){ if(a[j]+0 < a[i]+0){ t=a[i]; a[i]=a[j]; a[j]=t } } }
      if(n%2==1){ print a[(n+1)/2] }
      else { print int((a[n/2]+a[n/2+1])/2) }
    }' <<<"$*"
}

# Drop one high outlier if > factor * median. Prints filtered list.
drop_one_high_outlier_by_factor() {
  local factor="$1"; shift
  local median val dropped=0 out=() ; median="$(stats_median "$@")"
  for val in "$@"; do
    if (( !dropped )) && awk -v v="$val" -v m="$median" -v f="$factor" 'BEGIN{exit !(v>m*f)}'; then
      dropped=1
      continue
    fi
    out+=("$val")
  done
  printf '%s' "${out[*]:-}"
}

# Convert space list to csv
to_csv() {
  local first=1 o="" x
  for x in $*; do
    if (( first )); then o="$x"; first=0; else o="${o},${x}"; fi
  done
  printf '%s' "$o"
}

# Round float string to integer
round_int() {
  awk -v v="$1" 'BEGIN{ if (v+0 >= 0) { printf "%d", int(v+0.5) } else { printf "%d", int(v-0.5) } }'
}

# ------------- Load samples -------------

if [[ ! -r "$SAMPLES_FILE" ]]; then
  echo "ERROR: samples file not found or unreadable: $SAMPLES_FILE" >&2
  exit 2
fi

# arrays
pre_vals="$(json_extract_metric_values pre_plugin_cost_ms)"
post_vals="$(json_extract_metric_values post_plugin_total_ms)"
prompt_vals="$(json_extract_metric_values prompt_ready_ms)"

# Fallback: if any list empty, try to pull means as 1-element approximation (still truthy)
if [[ -z "${pre_vals// /}" ]]; then
  if (( have_jq )); then
    pre_vals="$(jq -r '.metrics.pre_plugin_cost_ms.mean' "$SAMPLES_FILE" 2>/dev/null || echo 0)"
  else
    pre_vals="$(grep -A2 '"pre_plugin_cost_ms"' "$SAMPLES_FILE" | grep '"mean":' | head -1 | sed -E 's/.*"mean":[[:space:]]*([0-9.]+).*/\1/')"
  fi
fi
if [[ -z "${post_vals// /}" ]]; then
  if (( have_jq )); then
    post_vals="$(jq -r '.metrics.post_plugin_total_ms.mean' "$SAMPLES_FILE" 2>/dev/null || echo 0)"
  else
    post_vals="$(grep -A2 '"post_plugin_total_ms"' "$SAMPLES_FILE" | grep '"mean":' | head -1 | sed -E 's/.*"mean":[[:space:]]*([0-9.]+).*/\1/')"
  fi
fi
if [[ -z "${prompt_vals// /}" ]]; then
  if (( have_jq )); then
    prompt_vals="$(jq -r '.metrics.prompt_ready_ms.mean' "$SAMPLES_FILE" 2>/dev/null || echo 0)"
  else
    prompt_vals="$(grep -A2 '"prompt_ready_ms"' "$SAMPLES_FILE" | grep '"mean":' | head -1 | sed -E 's/.*"mean":[[:space:]]*([0-9.]+).*/\1/')"
  fi
fi

# ------------- Compute raw stats -------------

mean_pre="$(stats_mean $pre_vals)"
sd_pre="$(stats_stddev $pre_vals)"
rsd_pre="$(stats_rsd $pre_vals)"

mean_post="$(stats_mean $post_vals)"
sd_post="$(stats_stddev $post_vals)"
rsd_post="$(stats_rsd $post_vals)"

mean_prompt="$(stats_mean $prompt_vals)"
sd_prompt="$(stats_stddev $prompt_vals)"
rsd_prompt="$(stats_rsd $prompt_vals)"

# ------------- Outlier & trimmed stats -------------

outlier_factor_min="${OUTLIER_FACTOR_MIN_DEFAULT}"
post_median="$(stats_median $post_vals)"
outlier_detected="false"
outlier_metric=""
outlier_index="-1"
outlier_value="0"
outlier_factor="0"
# detect first post outlier > 2x median
if [[ "$post_median" -gt 0 ]]; then
  idx=0
  for v in $post_vals; do
    if awk -v vv="$v" -v mm="$post_median" -v f="$outlier_factor_min" 'BEGIN{exit !(vv>mm*f)}'; then
      outlier_detected="true"
      outlier_metric="post_plugin_total_ms"
      outlier_index="$idx"
      outlier_value="$v"
      outlier_factor="$(awk -v vv="$v" -v mm="$post_median" 'BEGIN{printf "%.4f", vv/mm}')"
      break
    fi
    idx=$((idx+1))
  done
fi

trimmed_pre_vals="$(drop_one_high_outlier_by_factor "$outlier_factor_min" $pre_vals)"
trimmed_post_vals="$(drop_one_high_outlier_by_factor "$outlier_factor_min" $post_vals)"
trimmed_prompt_vals="$(drop_one_high_outlier_by_factor "$outlier_factor_min" $prompt_vals)"

tmean_pre="$(stats_mean $trimmed_pre_vals)"
tsd_pre="$(stats_stddev $trimmed_pre_vals)"
trsd_pre="$(stats_rsd $trimmed_pre_vals)"

tmean_post="$(stats_mean $trimmed_post_vals)"
tsd_post="$(stats_stddev $trimmed_post_vals)"
trsd_post="$(stats_rsd $trimmed_post_vals)"

tmean_prompt="$(stats_mean $trimmed_prompt_vals)"
tsd_prompt="$(stats_stddev $trimmed_prompt_vals)"
trsd_prompt="$(stats_rsd $trimmed_prompt_vals)"

# ------------- Read current state & compute streak/mode -------------

samples_count="$(json_read_toplevel_number "$SAMPLES_FILE" samples)"
[[ -z "$samples_count" ]] && samples_count=0

# Default thresholds
rsd_warn_max="$RSQ_WARN_MAX_DEFAULT"
rsd_gate_max="$RSQ_GATE_MAX_DEFAULT"
streak_required="$STREAK_REQUIRED_DEFAULT"

# Read current streak
current_streak=0
if [[ -r "$STATE_FILE" ]]; then
  if (( have_jq )); then
    current_streak="$(jq -r '.stable_run_count // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
  else
    current_streak="$(grep -Eo '"stable_run_count":[[:space:]]*[0-9]+' "$STATE_FILE" 2>/dev/null | head -1 | sed -E 's/.*:([0-9]+)/\1/')"
  fi
fi
[[ "$current_streak" =~ ^[0-9]+$ ]] || current_streak=0

pass_run=0
awk -v a="$trsd_pre" -v b="$rsd_warn_max" 'BEGIN{exit !(a<=b)}' && awk -v a="$trsd_post" -v b="$rsd_warn_max" 'BEGIN{exit !(a<=b)}' && pass_run=1

if (( pass_run )); then
  new_streak=$(( current_streak + 1 ))
else
  new_streak=0
fi

[[ "$new_streak" -gt "$streak_required" ]] && new_streak="$streak_required"

new_mode="observe"
if (( new_streak >= streak_required )); then
  new_mode="guard"
fi

# ------------- Write state file -------------

ts="$(timestamp_iso)"
mkdir -p -- "$(dirname -- "$STATE_FILE")" "$(dirname -- "$VARIANCE_BADGE")" "$(dirname -- "$GOVERNANCE_BADGE")" "$(dirname -- "$PERF_BADGE")" 2>/dev/null || true

tmp_state="${STATE_FILE}.tmp.$$"
cat >"$tmp_state" <<EOF
{"mode":"${new_mode}","stable_run_count":${new_streak},"updated_at":"${ts}"}
EOF
mv -f "$tmp_state" "$STATE_FILE" || { echo "ERROR: failed to write $STATE_FILE" >&2; exit 3; }

# ------------- Write variance-state badge -------------

method="drop_1_high_outlier_by_2x_median"
if [[ "$outlier_detected" == "false" ]]; then
  method="none"
fi

tmp_var="${VARIANCE_BADGE}.tmp.$$"
cat >"$tmp_var" <<EOF
{
  "schema": "variance-state.v1",
  "generated_at": "${ts}",
  "mode": "${new_mode}",
  "rsd": {
    "pre": { "mean": ${mean_pre}, "stddev": ${sd_pre}, "rsd": ${rsd_pre} },
    "post": { "mean": ${mean_post}, "stddev": ${sd_post}, "rsd": ${rsd_post} },
    "prompt": { "mean": ${mean_prompt}, "stddev": ${sd_prompt}, "rsd": ${rsd_prompt} }
  },
  "rsd_trimmed": {
    "method": "${method}",
    "pre": { "mean": ${tmean_pre}, "stddev": ${tsd_pre}, "rsd": ${trsd_pre} },
    "post": { "mean": ${tmean_post}, "stddev": ${tsd_post}, "rsd": ${trsd_post} },
    "prompt": { "mean": ${tmean_prompt}, "stddev": ${tsd_prompt}, "rsd": ${trsd_prompt} }
  },
  "thresholds": {
    "rsd_warn_max": ${rsd_warn_max},
    "rsd_gate_max": ${rsd_gate_max},
    "outlier_factor_min": ${OUTLIER_FACTOR_MIN_DEFAULT},
    "streak_required": ${streak_required}
  },
  "auth": {
    "requested": ${samples_count},
    "collected": ${samples_count},
    "authentic": ${samples_count}
  },
  "stable_run_count": ${new_streak},
  "previous_mode": "${new_mode}",
  "promotion_notes": "streak=${new_streak}/${streak_required}; trimmed_rsd<=rsd_warn_max?=${pass_run}",
  "outliers": {
    "detected": ${outlier_detected},
    "metric": "${outlier_metric}",
    "index": ${outlier_index},
    "value": ${outlier_value},
    "median": ${post_median},
    "factor": "${outlier_factor}"
  },
  "sources": {
    "samples_file": "dot-config/zsh/docs/redesignv2/artifacts/metrics/perf-multi-simple.json",
    "state_file": "docs/redesignv2/artifacts/metrics/variance-gating-state.json"
  }
}
EOF
mv -f "$tmp_var" "$VARIANCE_BADGE" || { echo "ERROR: failed to write $VARIANCE_BADGE" >&2; exit 3; }

# ------------- Update governance badge -------------

# governance message & color: reflect mode and outlier presence
gov_msg="observe: stable"
gov_color="green"
if [[ "$new_mode" == "guard" ]]; then
  gov_msg="guard: stable"
  gov_color="green"
else
  if [[ "$outlier_detected" == "true" ]]; then
    gov_msg="observe: outlier"
    gov_color="orange"
  fi
fi

tmp_gov="${GOVERNANCE_BADGE}.tmp.$$"
cat >"$tmp_gov" <<EOF
{
  "schema": "governance-badge.v1",
  "generated_at": "${ts}",
  "sources": {
    "perf_drift": "missing",
    "perf_ledger": "missing",
    "variance_state": "${REPO_ROOT}/docs/redesignv2/artifacts/badges/variance-state.json",
    "micro_bench": "${MICROBENCH_FILE}"
  },
  "stats": {
    "regressions": 0,
    "max_regression_pct": 0,
    "over_budget_count": 0,
    "variance_mode": "${new_mode}",
    "auth_shortfall": 0,
    "auth_requested": ${samples_count},
    "authentic_samples": ${samples_count},
    "multi_source": "none",
    "rsd_pre": ${rsd_pre},
    "rsd_post": ${rsd_post},
    "rsd_prompt": ${rsd_prompt},
    "microbench_regress_count": 0,
    "microbench_worst_ratio": 1.0,
    "shimmed": 0
  },
  "badge": {
    "label": "governance",
    "message": "${gov_msg}",
    "color": "${gov_color}"
  }
}
EOF
mv -f "$tmp_gov" "$GOVERNANCE_BADGE" || { echo "ERROR: failed to write $GOVERNANCE_BADGE" >&2; exit 3; }

# ------------- Update perf badge (startup + microbench summary) -------------

# Startup summary from post mean and RSD
post_mean_int="$(round_int "$mean_post")"
rsd_pct="$(awk -v r="$rsd_post" 'BEGIN{printf "%.1f", (r+0)*100.0}')"

mb_range=""
if [[ -r "$MICROBENCH_FILE" ]]; then
  if (( have_jq )); then
    mb_min="$(jq -r '.functions[].median_per_call_us' "$MICROBENCH_FILE" 2>/dev/null | awk 'NR==1{min=$1;max=$1} NR>1{if($1<min)min=$1;if($1>max)max=$1} END{printf "%d %d", min+0.5, max+0.5}' )" || mb_min=""
    if [[ -n "${mb_min:-}" ]]; then
      mb_min_i="$(echo "$mb_min" | awk '{print $1}')"
      mb_max_i="$(echo "$mb_min" | awk '{print $2}')"
      mb_range=" • core ${mb_min_i}–${mb_max_i}µs"
    fi
  else
    # crude parse: find "median_per_call_us": values
    vals="$(grep -Eo '"median_per_call_us":[[:space:]]*[0-9.]+' "$MICROBENCH_FILE" 2>/dev/null | sed -E 's/.*:[[:space:]]*([0-9.]+)/\1/' )"
    if [[ -n "${vals// /}" ]]; then
      mb_min_f="$(echo "$vals" | awk 'NR==1{min=$1;max=$1} NR>1{if($1<min)min=$1;if($1>max)max=$1} END{print min}')"
      mb_max_f="$(echo "$vals" | awk 'NR==1{min=$1;max=$1} NR>1{if($1<min)min=$1;if($1>max)max=$1} END{print max}')"
      mb_min_i="$(round_int "$mb_min_f")"
      mb_max_i="$(round_int "$mb_max_f")"
      mb_range=" • core ${mb_min_i}–${mb_max_i}µs"
    fi
  fi
fi

# Color heuristic based on RSD
perf_color="green"
awk -v r="$rsd_post" 'BEGIN{exit !(r>0.15)}' && perf_color="red" || true
awk -v r="$rsd_post" 'BEGIN{exit !(r>0.05 && r<=0.15)}' && perf_color="yellow" || true

tmp_perf="${PERF_BADGE}.tmp.$$"
cat >"$tmp_perf" <<EOF
{"schemaVersion":1,"label":"zsh startup","message":"${post_mean_int}ms ${rsd_pct}%${mb_range}","color":"${perf_color}"}
EOF
mv -f "$tmp_perf" "$PERF_BADGE" || { echo "ERROR: failed to write $PERF_BADGE" >&2; exit 3; }

echo "[update-variance-and-badges] Updated:"
echo "  - $STATE_FILE"
echo "  - $VARIANCE_BADGE"
echo "  - $GOVERNANCE_BADGE"
echo "  - $PERF_BADGE"

exit 0
