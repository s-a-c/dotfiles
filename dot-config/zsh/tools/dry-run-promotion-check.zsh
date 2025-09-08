#!/usr/bin/env zsh
# dry-run-promotion-check.zsh
# Validates readiness for Promotion (Phase 8) without modifying the repo.
# Exit Codes:
# 0 Ready
# 1 Missing prerequisite(s)
# 2 Test failure(s)
# 3 Performance threshold not met (if perf check enabled)
# 4 Duplicate prefix or guard issues (structure integrity)
# 5 Structure badge drift (badge color red) when expected count reached
#
# Usage:
#     tools/dry-run-promotion-check.zsh [--no-perf] [--expect-modules 11] [--verbose]
#     Set STRICT_DRIFT=1 to enforce structure badge color green.
set -euo pipefail

ROOT_DIR=${0:A:h:h}
ZROOT=${ZDOTDIR:-$ROOT_DIR}
cd "$ROOT_DIR" || { echo "[check] Unable to cd to root $ROOT_DIR" >&2; exit 1; }

EXPECT_MODULES=11
DO_PERF=1
VERBOSE=0
STRICT=${STRICT_DRIFT:-0}
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-perf) DO_PERF=0; shift ;;
        --expect-modules) EXPECT_MODULES=$2; shift 2 ;;
        --verbose|-v) VERBOSE=1; shift ;;
        -h|--help)
            sed -n '1,60p' "$0"; exit 0 ;;
        *) echo "[check] Unknown arg: $1" >&2; exit 1 ;;
    esac
done

log() { [[ $VERBOSE -eq 1 ]] && echo "$*" >&2; }
fail_reasons=()

# 1. Baseline metrics
BASE_METRICS=docs/redesign/metrics/perf-baseline.json
if [[ ! -f $BASE_METRICS ]]; then
    fail_reasons+="Missing baseline metrics: $BASE_METRICS"
fi

# 2. Backup directory & immutability
backup_dir=$(ls -1d .zshrc.d.backup-* 2>/dev/null | head -n1 || true)
if [[ -z $backup_dir ]]; then
    fail_reasons+="No backup directory (.zshrc.d.backup-*) found"
else
    if [[ -w $backup_dir ]]; then
        fail_reasons+="Backup directory $backup_dir is writable (should be immutable)"
    fi
fi

# 3. Redesign skeleton presence
REDESIGN_DIR=.zshrc.d.REDESIGN
if [[ ! -d $REDESIGN_DIR ]]; then
    fail_reasons+="Redesign directory missing: $REDESIGN_DIR"
else
    module_files=(${REDESIGN_DIR}/*.zsh(N))
    mod_count=${#module_files[@]}
    typeset -A seen_prefix
    dup_prefix=0
    guard_missing=0
    for f in "${module_files[@]}"; do
        bn=${f:t}
        [[ $bn =~ '^([0-9]{2})' ]] && pfx=${match[1]} || pfx="NA"
        if [[ -n ${seen_prefix[$pfx]:-} ]]; then dup_prefix=1; else seen_prefix[$pfx]=1; fi
        grep -q '_LOADED_' "$f" 2>/dev/null || guard_missing=1
    done
    (( dup_prefix )) && fail_reasons+="Duplicate numeric prefix detected in redesign modules"
    (( guard_missing )) && fail_reasons+="One or more redesign modules missing guard (_LOADED_)"
    if (( mod_count > 0 && mod_count < EXPECT_MODULES )); then
        log "[check] NOTE: redesign module count ($mod_count) < expected ($EXPECT_MODULES) – allowed pre-migration"
    fi
    # Structure badge enforcement when expected count achieved and strict mode
    if (( STRICT )) && (( mod_count >= EXPECT_MODULES )); then
        if [[ -f docs/badges/structure.json ]]; then
            color=$(grep -E '"color"' docs/badges/structure.json | head -n1 | sed 's/.*"color":"\([^"]*\)".*/\1/')
            if [[ $color == red ]]; then
                fail_reasons+="Structure badge red (drift)"
                badge_drift=1
            fi
        else
            log "[check] structure badge missing; skipping badge drift check"
        fi
    fi
fi

# 4. Git cleanliness
if ! git diff --quiet --exit-code; then fail_reasons+="Unstaged changes present"; fi
if ! git diff --cached --quiet --exit-code; then fail_reasons+="Staged but uncommitted changes present"; fi

# 5. Run core tests (design, integration, security)
TEST_RUNNER=tests/run-all-tests.zsh
if [[ -x $TEST_RUNNER ]]; then
    log "[check] Running core tests (design,integration,security)"
    if ! ZSH_DEBUG=0 $TEST_RUNNER --category=design,integration,security --fail-fast >/dev/null 2>&1; then
        fail_reasons+="Core tests failed (design/integration/security)"
        tests_failed=1
    else
        tests_failed=0
    fi
else
    fail_reasons+="Test runner missing: $TEST_RUNNER"
fi

# 6. Performance threshold (optional)
if (( DO_PERF )); then
    CUR_METRICS=docs/redesign/metrics/perf-current.json
    if [[ -f $BASE_METRICS && -f $CUR_METRICS ]]; then
        base_mean=$(grep -E 'startup_mean_ms' "$BASE_METRICS" | tr -dc '0-9.')
        cur_mean=$(grep -E 'startup_mean_ms' "$CUR_METRICS" | tr -dc '0-9.')
        if [[ -n $base_mean && -n $cur_mean ]]; then
            threshold=$(awk -v b="$base_mean" 'BEGIN{printf "%.2f", b*0.80}')
            if ! awk -v c="$cur_mean" -v t="$threshold" 'BEGIN{exit (c<=t?0:1)}'; then
                perf_fail=1
            else
                log "[check] Performance OK: cur=$cur_mean ms <= $threshold ms (80% baseline)"
            fi
        else
            fail_reasons+="Unable to parse mean values from metrics"
        fi
    else
        log "[check] Skipping perf threshold (current metrics missing)"
    fi
fi

if (( ${#fail_reasons[@]} )); then
    echo "[check] Promotion readiness: NOT READY" >&2
    for r in "${fail_reasons[@]}"; do echo " - $r" >&2; done
    (( tests_failed )) && exit 2
    (( perf_fail )) && { echo "[check] Performance threshold not met" >&2; exit 3; }
    if printf '%s\n' "${fail_reasons[@]}" | grep -qi 'duplicate numeric prefix\|guard'; then exit 4; fi
    (( badge_drift )) && exit 5
    exit 1
fi

if (( perf_fail )); then
    echo "[check] Performance threshold not met (code 3)" >&2
    exit 3
fi

if (( badge_drift )); then
    echo "[check] Structure badge drift (code 5)" >&2
    exit 5
fi

echo "[check] Promotion readiness: READY"
exit 0
