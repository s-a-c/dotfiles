#!/usr/bin/env zsh
# Nightly maintenance orchestrator
# Responsibilities:
#    - Capture performance metrics
#    - Run (light) security maintenance (full weekly script runs separately)
#    - Generate/update performance badge (docs/badges/perf.json)
#    - Aggregate summary & send notification (if ALERT_EMAIL & neomutt/mail available)
#    - Prune old logs (>90d compressed quarterly) – TODO (optional)
set -euo pipefail

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
LOG_ROOT=${ROOT_DIR}/logs
NIGHTLY_DIR=${LOG_ROOT}/nightly
BADGE_DIR=${ROOT_DIR}/docs/badges
METRICS_DIR=${ROOT_DIR}/docs/redesign/metrics
mkdir -p "$NIGHTLY_DIR" "$BADGE_DIR" "$METRICS_DIR"
STAMP=$(date +%Y-%m-%dT%H-%M-%S)
LOG_FILE="$NIGHTLY_DIR/nightly-${STAMP}.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[nightly] Start $STAMP"
status_perf=0
status_sec=0
status_badge=0

# 1. Performance Capture
if [[ -x ${SCRIPT_DIR}/perf-capture.zsh ]]; then
    echo "[nightly] Performance capture"
    if ! ${SCRIPT_DIR}/perf-capture.zsh; then
        echo "[nightly] WARN: perf capture failed" >&2
        status_perf=1
    fi
else
    echo "[nightly] SKIP: perf-capture.zsh not found/executable" >&2
    status_perf=1
fi

# 2. Light Security Maintenance (quick integrity status only)
if [[ -x ${SCRIPT_DIR}/weekly-security-maintenance ]]; then
    echo "[nightly] Security light scan"
    if ! ${SCRIPT_DIR}/weekly-security-maintenance --light; then
        echo "[nightly] WARN: security maintenance failed" >&2
        status_sec=1
    fi
else
    echo "[nightly] SKIP: weekly-security-maintenance not executable" >&2
    status_sec=1
fi

# 3. Badge Generation (use existing perf-current.json or quick test)
GEN_BADGE_SCRIPT=${SCRIPT_DIR}/generate-perf-badge.zsh
if [[ -x $GEN_BADGE_SCRIPT ]]; then
    echo "[nightly] Generating performance badge"
    if ! $GEN_BADGE_SCRIPT --quiet; then
        echo "[nightly] WARN: badge generation failed" >&2
        status_badge=1
    fi
else
    echo "[nightly] SKIP: generate-perf-badge.zsh missing" >&2
    status_badge=1
fi

# 4. Summaries
SUMMARY=$(mktemp)
{
    echo "# Nightly Summary $STAMP"
    echo "Start: $STAMP"
    echo "## Component Status"
    echo "Performance: $([[ $status_perf -eq 0 ]] && echo OK || echo FAIL)"
    echo "Security: $([[ $status_sec -eq 0 ]] && echo OK || echo FAIL)"
    echo "Badge: $([[ $status_badge -eq 0 ]] && echo OK || echo FAIL)"
    echo "## Recent Perf Delta (if available)"
    if [[ -f ${BADGE_DIR}/perf.json ]]; then
        jq -r '.message' ${BADGE_DIR}/perf.json || true
    fi
    echo "## Tail Perf Log"
    if [[ -f ${LOG_ROOT}/perf-cron.log ]]; then
        tail -n 20 ${LOG_ROOT}/perf-cron.log
    else
        echo "(no perf log)"
    fi
    echo "## Security Violations (recent)"
    if [[ -f ${LOG_ROOT}/security-weekly.log ]]; then
        grep -i violation ${LOG_ROOT}/security-weekly.log | tail -n 20 || echo "(none)"
    else
        echo "(no security log)"
    fi
} > "$SUMMARY"

# 5. Notification (best-effort)
if [[ -x ${SCRIPT_DIR}/notify-email.zsh ]]; then
    ALERT_EMAIL=${ALERT_EMAIL:-embrace.s0ul+s-a-c-zsh@gmail.com} \
    ${SCRIPT_DIR}/notify-email.zsh "[zsh-refactor] Nightly Summary $STAMP" "$SUMMARY" || true
else
    echo "[nightly] NOTE: notifier missing; summary follows" >&2
    cat "$SUMMARY"
fi

rm -f "$SUMMARY"
echo "[nightly] Done"

# Exit non-zero if any major component failed (perf or security)
[[ $status_perf -eq 0 && $status_sec -eq 0 ]] || exit 1
