#!/usr/bin/env zsh
# ============================================================================
# test-preplugin-variance-eval.zsh
#
# Purpose:
#   Exercise tools/preplugin-variance-eval.zsh against any available
#   Stage 3 baseline artifacts and validate shape + core invariants of output.
#
# Behavior:
#   - SKIP (exit 0) if:
#       * Tool script missing
#       * Metrics directory missing
#       * No Stage 3 baseline files yet (developer has not captured)
#   - PASS if all assertions satisfied
#   - FAIL (exit 1) on assertion failure / malformed JSON
#
# Assertions (A*):
#   A1: Tool executable and produces JSON containing required schema
#   A2: analyzed_files >= discovered Stage 3 file count
#   A3: total_samples > 0
#   A4: aggregate_mean_ms is a positive number
#   A5: aggregate_rsd parsed, non-negative, < 1.5 (sanity upper bound)
#   A6: recommended_guard_pct in {5,7,10}
#   A7: Guard recommendation internally consistent with rsd + sample counts
#
# Style: 4-space indentation
# ============================================================================

set -euo pipefail

_pass=()
_fail=()

pass() { _pass+=("$1"); }
fail() { _fail+=("$1"); }

SCRIPT_DIR="$(cd -- "$(dirname -- "${(%):-%N}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd -P)"
ZSH_DIR="${REPO_ROOT}/dot-config/zsh"
ZDOTDIR="${ZSH_DIR}"

TOOL="${ZDOTDIR}/tools/preplugin-variance-eval.zsh"
METRICS_DIR="${ZDOTDIR}/docs/redesignv2/artifacts/metrics"
GLOB_PATTERN="preplugin-baseline-stage3*.json"

# -------------------- Precondition / Skip Handling ---------------------------
if [[ ! -x "$TOOL" ]]; then
    echo "SKIP: variance evaluation tool missing ($TOOL)"
    exit 0
fi

if [[ ! -d "$METRICS_DIR" ]]; then
    echo "SKIP: metrics directory missing ($METRICS_DIR)"
    exit 0
fi

setopt nullglob 2>/dev/null || true
stage3_files=("${METRICS_DIR}"/${GLOB_PATTERN}(N))
unsetopt nullglob 2>/dev/null || true
stage3_count=${#stage3_files[@]}

if (( stage3_count == 0 )); then
    echo "SKIP: no Stage 3 baseline artifacts yet (pattern=$GLOB_PATTERN)"
    exit 0
fi

# -------------------- Execute Tool ------------------------------------------
RAW_JSON="$("$TOOL" --dir "$METRICS_DIR" --glob "$GLOB_PATTERN" --json 2>/dev/null || true)"

if [[ -z "$RAW_JSON" ]]; then
    fail "A1: tool-output-empty"
else
    if print -- "$RAW_JSON" | grep -q '"schema"[[:space:]]*:[[:space:]]*"preplugin-variance-eval.v1"'; then
        pass "A1: schema"
    else
        fail "A1: schema-missing"
    fi
fi

# Helper: extract numeric value (first occurrence) or empty
extract_num() {
    local key="$1"
    print -- "$RAW_JSON" | \
        grep -E "\"$key\"" | head -1 | \
        sed -E 's/.*"'$key'"[[:space:]]*:[[:space:]]*([-+]?[0-9]+(\.[0-9]+)?).*/\1/' | \
        grep -E '^-?[0-9]+(\.[0-9]+)?$' || true
}

analyzed_files="$(extract_num analyzed_files)"
total_samples="$(extract_num total_samples)"
aggregate_mean_ms="$(extract_num aggregate_mean_ms)"
aggregate_stdev_ms="$(extract_num aggregate_stdev_ms)"
aggregate_rsd="$(extract_num aggregate_rsd)"
recommended_guard_pct="$(extract_num recommended_guard_pct)"

# A2: analyzed_files >= discovered Stage 3 file count
if [[ -n "$analyzed_files" && "$analyzed_files" =~ ^[0-9]+$ && $analyzed_files -ge $stage3_count ]]; then
    pass "A2: analyzed-files"
else
    fail "A2: analyzed-files (val='${analyzed_files:-<empty>}' expected >= $stage3_count)"
fi

# A3: total_samples > 0
if [[ -n "$total_samples" && "$total_samples" =~ ^[0-9]+$ && $total_samples -gt 0 ]]; then
    pass "A3: total-samples"
else
    fail "A3: total-samples (val='${total_samples:-<empty>}')"
fi

# A4: aggregate_mean_ms positive
if [[ -n "$aggregate_mean_ms" ]]; then
    # Accept float > 0
    if awk -v m="$aggregate_mean_ms" 'BEGIN{exit !(m>0)}'; then
        pass "A4: mean-positive"
    else
        fail "A4: mean-positive (val=$aggregate_mean_ms)"
    fi
else
    fail "A4: mean-missing"
fi

# A5: aggregate_rsd sane (>=0 and <1.5)
if [[ -n "$aggregate_rsd" ]]; then
    if awk -v r="$aggregate_rsd" 'BEGIN{exit !((r>=0)&&(r<1.5))}'; then
        pass "A5: rsd-range"
    else
        fail "A5: rsd-range (val=$aggregate_rsd)"
    fi
else
    fail "A5: rsd-missing"
fi

# A6: recommended_guard_pct in {5,7,10}
if [[ "$recommended_guard_pct" =~ ^(5|7|10)$ ]]; then
    pass "A6: guard-set"
else
    fail "A6: guard-set (val='${recommended_guard_pct:-<empty>}')"
fi

# A7: Guard recommendation consistent (heuristic)
if [[ -n "$aggregate_rsd" && -n "$total_samples" && -n "$recommended_guard_pct" ]]; then
    rsd_ok=0
    case "$recommended_guard_pct" in
        5)
            # Expect rsd <= ~0.055 and samples >= 15 (tool uses >=20, allow slight leniency so test doesn't overfail early)
            if awk -v r="$aggregate_rsd" -v n="$total_samples" 'BEGIN{exit !((r<=0.055)&&(n>=15))}'; then
                rsd_ok=1
            fi
            ;;
        7)
            # Either rsd <=0.085 & samples >=10 (lenient) OR rsd <=0.05 but samples <20 (transition state)
            if awk -v r="$aggregate_rsd" -v n="$total_samples" 'BEGIN{
                cond1=(r<=0.085 && n>=10)
                cond2=(r<=0.05 && n<20)
                exit !(cond1||cond2)
            }'; then
                rsd_ok=1
            fi
            ;;
        10)
            # Accept if rsd > 0.05 OR insufficient samples for tighter guard
            if awk -v r="$aggregate_rsd" -v n="$total_samples" 'BEGIN{
                cond=(r>0.05) || (n<10)
                exit !cond
            }'; then
                rsd_ok=1
            fi
            ;;
    esac
    if (( rsd_ok )); then
        pass "A7: guard-consistency"
    else
        fail "A7: guard-consistency (rsd=$aggregate_rsd samples=$total_samples guard=$recommended_guard_pct)"
    fi
else
    fail "A7: guard-consistency (missing fields)"
fi

# -------------------- Emit Results -------------------------------------------
for p in "${_pass[@]}"; do
    print "PASS: $p"
done
for f in "${_fail[@]}"; do
    print "FAIL: $f"
done

print "---"
print "SUMMARY: passes=${#_pass[@]} fails=${#_fail[@]} (files=${stage3_count} analyzed=${analyzed_files:-?} samples=${total_samples:-?})"

if (( ${#_fail[@]} > 0 )); then
    print -u2 "TEST RESULT: FAIL"
    exit 1
fi

print "TEST RESULT: PASS"
exit 0
