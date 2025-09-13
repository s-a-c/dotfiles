#!/usr/bin/env bash
#
# capture-dispatch-evidence.sh
#
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v9ab717af287538a58515d2f3369d011f40ef239829ec614afadfc1cc419e5f20
#
# Purpose:
#   Automate collection of reproducible evidence for the GitHub Actions anomaly:
#     HTTP 422: "Workflow does not have 'workflow_dispatch' trigger"
#   when manually dispatching *newly created* workflows.
#
# What This Script Does:
#   1. Validates environment & required utilities.
#   2. Attempts failing manual-dispatch API call for a reproduction workflow.
#   3. Attempts control dispatch on a legacy workflow (expected 204).
#   4. Redacts tokens from verbose curl logs.
#   5. Extracts failing JSON error line.
#   6. Captures hex dump snippet of the reproduction workflow file.
#   7. Records commit metadata & file stat info.
#   8. Copies diagnostics bundle if present.
#   9. Produces a manifest + tarball for support submission.
#
# Requirements:
#   - Environment variable GITHUB_TOKEN (or GH_TOKEN / GH_PAT fallback) with repo dispatch permission.
#   - curl, sed, grep, hexdump (from util-linux or BSD), tar, date, mktemp.
#
# Variables (override via env or flags):
#   REPO                (default: s-a-c/dotfiles)
#   REF                 (default: main)
#   REPRO_WORKFLOW      (default: test-minimal-dispatch.yml)
#   LEGACY_WORKFLOW     (default: ci-performance.yml)
#   OUT_DIR             (default: support-evidence)
#   FORCE               (default: 0) if 1, continue on some non-critical errors.
#   EXPECT_REPRO_STATUS   (default: 204) expected HTTP status for reproduction workflow dispatch.
#                          Set to 422 if the anomaly resurfaces and you need to re-capture failing evidence.
#   EXPECT_CONTROL_STATUS (default: 204) expected HTTP status for control (legacy) workflow dispatch; normally remains 204.
#
# Flags:
#   --repo owner/repo
#   --ref main|branch
#   --repro <workflow filename>
#   --legacy <workflow filename>
#   --out <output directory>
#   --force
#   --help
#
# Exit Codes:
#   0 success
#   1 usage / argument error
#   2 missing dependency
#   3 missing token
#   4 API failure (unexpected status)
#   5 file / path / FS error
#   6 partial success (when FORCE=1)
#
# Security:
#   - Never prints raw token.
#   - Redacts Authorization header in saved logs.
#
set -euo pipefail

#######################################
# Defaults
#######################################
REPO="${REPO:-s-a-c/dotfiles}"
REF="${REF:-main}"
REPRO_WORKFLOW="${REPRO_WORKFLOW:-test-minimal-dispatch.yml}"
LEGACY_WORKFLOW="${LEGACY_WORKFLOW:-ci-performance.yml}"
OUT_DIR="${OUT_DIR:-support-evidence}"
FORCE="${FORCE:-0}"
EXPECT_REPRO_STATUS="${EXPECT_REPRO_STATUS:-204}"
EXPECT_CONTROL_STATUS="${EXPECT_CONTROL_STATUS:-204}"

#######################################
# Helpers
#######################################
err() { printf >&2 "ERROR: %s\n" "$*"; }
warn() { printf >&2 "WARN: %s\n" "$*"; }
info() { printf "INFO: %s\n" "$*"; }
fatal() { err "$*"; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || {
    if [ "$FORCE" = "1" ]; then
      warn "Missing required utility '$1' (continuing due to FORCE=1)"
      return 1
    fi
    fatal "Missing required utility '$1'"
  }
}

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --repo owner/repo               (default: $REPO)
  --ref refname                   (default: $REF)
  --repro workflow.yml            (default: $REPRO_WORKFLOW)
  --legacy workflow.yml           (default: $LEGACY_WORKFLOW)
  --out dir                       (default: $OUT_DIR)
  --force                         Continue on some errors (FORCE=1)
  --help                          Show this help

Env Overrides:
  REPO, REF, REPRO_WORKFLOW, LEGACY_WORKFLOW, OUT_DIR, FORCE, GITHUB_TOKEN

Example:
  GITHUB_TOKEN=ghp_xxx $0 --repo s-a-c/dotfiles --repro test-minimal-dispatch.yml
EOF
}

#######################################
# Parse Args
#######################################
while [ "${1:-}" != "" ]; do
  case "$1" in
    --repo) REPO="$2"; shift 2;;
    --ref) REF="$2"; shift 2;;
    --repro) REPRO_WORKFLOW="$2"; shift 2;;
    --legacy) LEGACY_WORKFLOW="$2"; shift 2;;
    --out) OUT_DIR="$2"; shift 2;;
    --force) FORCE=1; shift;;
    --help|-h) usage; exit 0;;
    *) err "Unknown argument: $1"; usage; exit 1;;
  esac
done

#######################################
# Validate Token
#######################################
TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-${GH_PAT:-}}}"
if [ -z "${TOKEN}" ]; then
  if [ "$FORCE" = "1" ]; then
    warn "No token found (GITHUB_TOKEN). Some steps will fail."
  else
    fatal "No GITHUB_TOKEN (or GH_TOKEN / GH_PAT) provided."
  fi
fi

#######################################
# Check Dependencies
#######################################
DEPS=(curl sed grep hexdump tar date mktemp)
for d in "${DEPS[@]}"; do
  need "$d" || true
done

#######################################
# Prepare Output Structure
#######################################
TS="$(date -u +%Y%m%dT%H%M%SZ)"
SESSION_DIR="${OUT_DIR}/capture-${TS}"
mkdir -p "$SESSION_DIR"

MANIFEST="$SESSION_DIR/manifest.txt"
touch "$MANIFEST"

note_manifest() {
  printf "%s\n" "$*" >>"$MANIFEST"
}

info "Session directory: $SESSION_DIR"

#######################################
# Copy Diagnostics Bundle if present
#######################################
if [ -f ".github/dispatch-diagnostics/README.md" ]; then
  cp ".github/dispatch-diagnostics/README.md" "$SESSION_DIR/diagnostics-bundle.README.md"
  note_manifest "Diagnostics bundle copied: diagnostics-bundle.README.md"
else
  warn "Diagnostics bundle missing (.github/dispatch-diagnostics/README.md)"
  note_manifest "Diagnostics bundle missing"
fi

#######################################
# Capture Reproduction Workflow Local Evidence
#######################################
REPRO_PATH=".github/workflows/${REPRO_WORKFLOW}"
if [ -f "$REPRO_PATH" ]; then
  hexdump -C "$REPRO_PATH" | head -n 20 > "$SESSION_DIR/workflow-hexdump-snippet.txt" || warn "Hexdump snippet failed"
  cp "$REPRO_PATH" "$SESSION_DIR/${REPRO_WORKFLOW}.copy"
  note_manifest "Repro workflow present: $REPRO_PATH"
else
  warn "Repro workflow not found at $REPRO_PATH"
  note_manifest "Repro workflow missing: $REPRO_PATH"
  [ "$FORCE" = "1" ] || err "Continuing; reproduction dispatch test will likely fail with 404."
fi

#######################################
# Commit Metadata
#######################################
{
  echo "HEAD_SHA=$(git rev-parse HEAD 2>/dev/null || echo 'N/A')"
  echo "REPRO_LAST_COMMIT=$(git log -n 1 --pretty=oneline -- \"$REPRO_PATH\" 2>/dev/null || echo 'N/A')"
  echo "LEGACY_LAST_COMMIT=$(git log -n 1 --pretty=oneline -- \".github/workflows/${LEGACY_WORKFLOW}\" 2>/dev/null || echo 'N/A')"
} > "$SESSION_DIR/git-metadata.txt" || warn "Git metadata capture failed"

if [ -f "$REPRO_PATH" ]; then
  (stat "$REPRO_PATH" 2>/dev/null || ls -l "$REPRO_PATH") > "$SESSION_DIR/repro-file-stat.txt" || true
fi

#######################################
# Function: dispatch_workflow (expects 422 for repro, 204 for control)
#######################################
dispatch_workflow() {
  local workflow_file="$1"
  local tag="$2"          # label for files
  local expect_http="$3"  # expected HTTP (string, can include '|')
  local outfile_raw="$SESSION_DIR/${tag}-dispatch.raw.log"
  local outfile_redacted="$SESSION_DIR/${tag}-dispatch.redacted.log"
  local outfile_error_json="$SESSION_DIR/${tag}-error.json"

  local url="https://api.github.com/repos/${REPO}/actions/workflows/${workflow_file}/dispatches"

  if [ -z "$TOKEN" ]; then
    warn "Skipping dispatch for $workflow_file (no token)"
    return 0
  fi

  info "Dispatching $workflow_file (tag=$tag) -> $url"
  note_manifest "Dispatch attempt: ${workflow_file} (tag=${tag})"

  # Perform verbose curl
  set +e
  HTTP_CODE=$(curl -sS -w '%{http_code}' -o "$outfile_raw.body" -v \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -X POST "$url" \
    -d "{\"ref\":\"${REF}\"}" \
    2> "$outfile_raw.headers")
  CURL_STATUS=$?
  set -e

  cat "$outfile_raw.headers" "$outfile_raw.body" > "$outfile_raw"
  rm -f "$outfile_raw.headers" "$outfile_raw.body"

  if [ $CURL_STATUS -ne 0 ]; then
    err "curl transport error (exit $CURL_STATUS) for $workflow_file"
    note_manifest "curl transport error for $workflow_file exit=$CURL_STATUS"
    [ "$FORCE" = "1" ] || return 4
  fi

  # Redact token
  sed -E 's/(Authorization: Bearer )[^ ]+/\1***REDACTED***/I; s/(authorization: Bearer )[^ ]+/\1***REDACTED***/I' \
    "$outfile_raw" > "$outfile_redacted"

  # Extract error JSON line (if any) – usually appears at end for 422
  grep -E '^{\"message\"' "$outfile_redacted" | tail -1 > "$outfile_error_json" || true
  if [ ! -s "$outfile_error_json" ]; then
    # Fallback: try last non-empty JSON-looking line
    tail -20 "$outfile_redacted" | grep -E '\"message\"' | tail -1 > "$outfile_error_json" || true
  fi
  [ -s "$outfile_error_json" ] && note_manifest "${tag}: captured error JSON line"

  echo "HTTP_CODE=$HTTP_CODE" > "$SESSION_DIR/${tag}-status.txt"
  note_manifest "${tag} HTTP=$HTTP_CODE expected=$expect_http"

  # Evaluate expectation
  if echo "$expect_http" | grep -q "$HTTP_CODE"; then
    info "${tag} dispatch HTTP $HTTP_CODE (as expected)"
  else
    warn "${tag} dispatch HTTP $HTTP_CODE (expected $expect_http)"
    if [ "$FORCE" != "1" ]; then
      return 4
    fi
  fi
  return 0
}

#######################################
# Perform Reproduction Dispatch (expect $EXPECT_REPRO_STATUS)
#######################################
dispatch_workflow "$REPRO_WORKFLOW" "repro" "$EXPECT_REPRO_STATUS" || {
  if [ "$FORCE" = "1" ]; then
    warn "Continuing after repro dispatch mismatch."
  else
    err "Reproduction dispatch step failed."
  fi
}

#######################################
# Perform Control Dispatch (expect $EXPECT_CONTROL_STATUS)
#######################################
dispatch_workflow "$LEGACY_WORKFLOW" "control" "$EXPECT_CONTROL_STATUS" || {
  if [ "$FORCE" = "1" ]; then
    warn "Continuing after control dispatch mismatch."
  else
    err "Control dispatch step failed."
  fi
}

#######################################
# Sanity Check: Secret Redaction
#######################################
SECRET_HITS=$(grep -E 'ghp_|github_pat_|Bearer [A-Za-z0-9]+' "$SESSION_DIR"/repro-dispatch.redacted.log 2>/dev/null || true)
if [ -n "$SECRET_HITS" ]; then
  warn "Potential secret leakage detected in repro-dispatch.redacted.log"
  note_manifest "WARNING: potential secret leakage in repro log"
fi

#######################################
# Build Tarball
#######################################
TARBALL="${OUT_DIR}/workflow-dispatch-evidence-${TS}.tar.gz"
tar czf "$TARBALL" -C "$OUT_DIR" "capture-${TS}"
note_manifest "Tarball created: $TARBALL"

#######################################
# Summary
#######################################
echo "------------------------------------------------------------"
echo "Evidence Capture Summary"
echo "Repository:        $REPO"
echo "Reference:         $REF"
echo "Repro Workflow:    $REPRO_WORKFLOW"
echo "Legacy Workflow:   $LEGACY_WORKFLOW"
echo "Output Directory:  $SESSION_DIR"
echo "Tarball:           $TARBALL"
echo "------------------------------------------------------------"

# Status evaluation
REPRO_HTTP="$(grep -Eo '^[0-9]+' "$SESSION_DIR/repro-status.txt" 2>/dev/null || grep -Eo '[0-9]+' "$SESSION_DIR/repro-status.txt" || true)"
CONTROL_HTTP="$(grep -Eo '^[0-9]+' "$SESSION_DIR/control-status.txt" 2>/dev/null || grep -Eo '[0-9]+' "$SESSION_DIR/control-status.txt" || true)"

if [ "${REPRO_HTTP:-}" = "${EXPECT_REPRO_STATUS}" ] && [ "${CONTROL_HTTP:-}" = "${EXPECT_CONTROL_STATUS}" ]; then
  echo "Result: SUCCESS (expected statuses matched)."
  exit 0
else
  echo "Result: PARTIAL / UNEXPECTED"
  echo "  repro HTTP (expected ${EXPECT_REPRO_STATUS}):   ${REPRO_HTTP:-<missing>}"
  echo "  control HTTP (expected ${EXPECT_CONTROL_STATUS}): ${CONTROL_HTTP:-<missing>}"
  if [ "$FORCE" = "1" ]; then
    exit 6
  else
    exit 4
  fi
fi
