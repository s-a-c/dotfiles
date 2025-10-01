#!/usr/bin/env bash
# promote-layer.sh
#
# Phase: Post-Phase7 Layer Governance (Roadmap Implementation)
#
# Purpose:
#   Automate promotion of a prepared ZSH layer set (e.g. from 00 -> 01),
#   perform health validation (widget baseline, segment instrumentation validity,
#   abbreviation markers), update an auditable manifest, archive the previous
#   stable set, and optionally rollback to a prior layer.
#
# Features:
#   * Promotion: Validates candidate layer directories exist, runs health checks,
#     flips symlinks (.zshrc.* -> versioned dirs).
#   * Validation: Executes smoke + aggregator (segments optional) and enforces:
#       - widget_count >= baseline (default 417)
#       - segments_valid==true if segments embedded
#   * Manifest: layers/manifest.json (atomic write) logs promotions & rollbacks.
#   * Archival: Copies outgoing stable layer directories into
#       layers/archives/<old-layer>-<UTC>-<shortsha>/
#   * Rollback: Restores symlinks to a previous layer with validation.
#   * Dry-run mode: Show planned changes without modifying filesystem.
#
# Usage:
#   Promote new layer "01":
#     ./zsh/tools/promote-layer.sh promote 01 \
#       --commit "$(git rev-parse --short HEAD)" \
#       --rationale "Phase 7 closure + instrumentation" \
#       --with-segments
#
#   Rollback to previous stable layer "00":
#     ./zsh/tools/promote-layer.sh rollback 00 --commit "$(git rev-parse --short HEAD)" --rationale "Revert perf regression"
#
#   Dry-run (no changes):
#     ./zsh/tools/promote-layer.sh promote 01 --dry-run
#
# Exit Codes:
#   0  Success
#   1  Usage / argument error
#   2  Validation failure (health gate)
#   3  Filesystem / archival error
#   4  Manifest update error
#   5  Symlink manipulation error
#
# Environment Overrides:
#   LAYER_WIDGET_BASELINE (default: 417)
#   LAYER_SEGMENTS_ENABLE=1 (force segment embedding even if flag omitted)
#
# Safety:
#   - set -euo pipefail for strict mode
#   - All optional expansions guarded with ${var:-}
#
# Dependencies (soft):
#   - jq (optional; improves manifest manipulation)
#   - git (for commit hash; can be passed manually)
#
# Policy Alignment:
#   - Minimal silent failure: explicit error messaging
#   - Nounset-safe
#   - No destructive in-place manifest edits (atomic temp write)
#
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_NAME="promote-layer.sh"
BASELINE_DEFAULT=417
WIDGET_BASELINE="${LAYER_WIDGET_BASELINE:-$BASELINE_DEFAULT}"

# Paths (relative to repo root `zsh/`)
MANIFEST_DIR="layers"
ARCHIVE_DIR="${MANIFEST_DIR}/archives"
MANIFEST_FILE="${MANIFEST_DIR}/manifest.json"

# ------------- Utility: Logging ------------------------------------------------
log()  { printf '%s\n' "[INFO] $*" >&2; }
warn() { printf '%s\n' "[WARN] $*" >&2; }
err()  { printf '%s\n' "[ERROR] $*" >&2; }

# ------------- Utility: Timestamp ---------------------------------------------
ts_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# ------------- Usage ----------------------------------------------------------
usage() {
  cat <<EOF
$SCRIPT_NAME - Manage promotion / rollback of versioned ZSH layer sets.

Commands:
  promote <layer-id>    Promote candidate layer (e.g. 01) to active stable (symlink flip)
  rollback <layer-id>   Roll back to specified prior layer id (e.g. 00)
  status                Show current symlink targets and manifest summary

Options (for promote / rollback):
  --commit <hash>       Source commit short hash (auto-detected if git present)
  --rationale <text>    Human-readable rationale (RECOMMENDED)
  --with-segments       Run aggregator with segment embedding + validation
  --no-segments         Force disable segments (overrides env LAYER_SEGMENTS_ENABLE)
  --baseline <n>        Override widget baseline (default: ${WIDGET_BASELINE})
  --dry-run             Show actions only (no filesystem changes)
  --quiet               Suppress non-error logs
  --manifest-only       Skip symlink + archive; just append manifest (for manual fix-ups)
  --help                Show this help

Exit Codes:
  0 success
  1 usage error
  2 validation failure (health gate)
  3 filesystem / archive error
  4 manifest write error
  5 symlink update error

Examples:
  $SCRIPT_NAME promote 01 --with-segments --commit $(git rev-parse --short HEAD)
  $SCRIPT_NAME rollback 00 --commit $(git rev-parse --short HEAD) --rationale "Revert regression"

EOF
}

# ------------- Global Flags ---------------------------------------------------
CMD=""
TARGET_LAYER=""
COMMIT=""
RATIONALE=""
WITH_SEGMENTS=0
FORCE_SEGMENTS_ENV=0
DRY_RUN=0
QUIET=0
MANIFEST_ONLY=0

# ------------- Parse Args -----------------------------------------------------
if [[ $# -lt 1 ]]; then
  usage; exit 1
fi

CMD="$1"; shift || true

case "${CMD}" in
  promote|rollback|status) : ;;
  --help|-h) usage; exit 0 ;;
  *) err "Unknown command: ${CMD}"; usage; exit 1 ;;
+esac
+...
+