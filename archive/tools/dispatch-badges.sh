#!/usr/bin/env bash
#
# dispatch-badges.sh
#
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v9ab717af287538a58515d2f3369d011f40ef239829ec614afadfc1cc419e5f20
#
# Purpose:
#   Convenience helper to trigger the badges / metrics workflow indirectly via repository_dispatch
#   while native workflow_dispatch remains unreliable for newly created workflow files (422 anomaly).
#
# Features:
#   - Sends repository_dispatch with event_type (default: badges_v2_run)
#   - Optional ref override (defaults to main if omitted)
#   - Optional client payload key/values (--payload key=value)
#   - Dry run mode (shows final curl command without executing)
#   - Verbose and JSON output modes
#   - jq usage optional; falls back gracefully if missing
#   - Token sourcing order: GITHUB_TOKEN > GH_TOKEN > GH_PAT > gh auth token (if gh CLI available)
#
# Exit Codes:
#   0  Success (HTTP 204/201)
#   2  API responded non‑success
#   3  Missing authentication token
#   4  Network / curl transport error
#   5  Dependency or usage error
#
# Security Notes:
#   - Does not echo token unless --very-verbose is explicitly set.
#   - Avoids writing payload to disk (uses process substitution / inline strings).
#
# Usage:
#   tools/dispatch-badges.sh                    # dispatch to s-a-c/dotfiles @ main
#   tools/dispatch-badges.sh --ref develop
#   tools/dispatch-badges.sh --repo youruser/dotfiles --event badges_v2_run
#   tools/dispatch-badges.sh --payload force=true --payload runs=3
#   DRY_RUN=1 tools/dispatch-badges.sh
#
#   JSON friendly:
#     tools/dispatch-badges.sh --json --payload reason=manual --payload source=cli
#
set -euo pipefail

# ---------------------------
# Defaults
# ---------------------------
REPO="s-a-c/dotfiles"
REF="main"
EVENT_TYPE="badges_v2_run"
VERBOSE=0
VERY_VERBOSE=0
DRY_RUN=0
JSON_OUTPUT=0
PAYLOAD_KV=()

CURL_BIN="${CURL_BIN:-curl}"
JQ_BIN="${JQ_BIN:-jq}"

# ---------------------------
# Helpers
# ---------------------------
err() { printf >&2 "ERROR: %s\n" "$*"; }
info() { [ "$VERBOSE" -ge 1 ] && printf "INFO: %s\n" "$*"; }
debug() { [ "$VERY_VERBOSE" -ge 1 ] && printf "DEBUG: %s\n" "$*"; }

usage() {
  cat <<'EOF'
dispatch-badges.sh - Trigger repository_dispatch for badges pipeline

Options:
  -r, --repo <owner/repo>     Target repository (default: s-a-c/dotfiles)
      --ref <git-ref>         Git ref to include in client payload (default: main)
  -e, --event <event_type>    Event type (default: badges_v2_run)
  -p, --payload k=v           Add key/value pair to client_payload (repeatable)
  -n, --dry-run               Print the request without executing
  -v, --verbose               Verbose logging
      --very-verbose          Include sensitive debug (never in CI logs unless needed)
      --json                  Emit a machine-readable JSON summary on stdout
  -h, --help                  Show help

Environment:
  GITHUB_TOKEN / GH_TOKEN / GH_PAT used in that order if present.
  DRY_RUN=1 can be used instead of --dry-run.

Examples:
  ./dispatch-badges.sh
  ./dispatch-badges.sh --ref develop --payload reason=adhoc --payload runs=5
  GITHUB_TOKEN=ghp_xxx ./dispatch-badges.sh --json

Exit Codes:
  0 success, 2 API failure, 3 no token, 4 network error, 5 usage/dependency error
EOF
}

# ---------------------------
# Argument Parsing
# ---------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--repo)
      REPO="$2"; shift 2;;
    --ref)
      REF="$2"; shift 2;;
    -e|--event)
      EVENT_TYPE="$2"; shift 2;;
    -p|--payload)
      PAYLOAD_KV+=("$2"); shift 2;;
    -n|--dry-run)
      DRY_RUN=1; shift;;
    -v|--verbose)
      VERBOSE=$((VERBOSE+1)); shift;;
    --very-verbose)
      VERBOSE=$((VERBOSE+1)); VERY_VERBOSE=$((VERY_VERBOSE+1)); shift;;
    --json)
      JSON_OUTPUT=1; shift;;
    -h|--help)
      usage; exit 0;;
    *)
      err "Unknown argument: $1"
      usage
      exit 5;;
  esac
done

# Allow env override
[ "${DRY_RUN:-0}" = "1" ] && DRY_RUN=1

# ---------------------------
# Token Resolution
# ---------------------------
TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-${GH_PAT:-}}}"

if [[ -z "$TOKEN" ]] && command -v gh >/dev/null 2>&1; then
  # Attempt to extract token from gh (gh does not expose raw token easily; rely on API as fallback).
  # We simply note that gh is present; user can rely on 'gh api' path if desired.
  debug "gh CLI present but no explicit token; attempting to use gh api fallback."
fi

if [[ -z "$TOKEN" ]] && [[ "$DRY_RUN" -eq 0 ]]; then
  err "No token found (set GITHUB_TOKEN or GH_TOKEN)."
  exit 3
fi

# ---------------------------
# Build Payload
# ---------------------------
# Base payload structure: event_type + client_payload
PAYLOAD_JSON=""
build_payload() {
  local kv_json extra ref_json
  if command -v "$JQ_BIN" >/dev/null 2>&1; then
    # Start with empty object
    kv_json="{}"
    for pair in "${PAYLOAD_KV[@]:-}"; do
      if [[ "$pair" != *"="* ]]; then
        err "--payload must be key=value (got '$pair')"
        exit 5
      fi
      local key="${pair%%=*}"
      local val="${pair#*=}"
      # shellcheck disable=SC2016
      kv_json=$("$JQ_BIN" -c --arg k "$key" --arg v "$val" '$in| .[$k]=$v' --argjson in "$kv_json" <<<"$kv_json" 2>/dev/null || \
        "$JQ_BIN" -c --arg k "$key" --arg v "$val" '. + {($k):$v}' <<<"$kv_json")
    done
    kv_json=$("$JQ_BIN" -c --arg r "$REF" '.ref = $r' <<<"$kv_json")
    PAYLOAD_JSON=$("$JQ_BIN" -c --arg et "$EVENT_TYPE" --argjson cp "$kv_json" '{event_type:$et, client_payload:$cp}')
  else
    # Minimal manual JSON (no escaping for quotes/backslashes in values)
    info "jq not found; constructing naive JSON (values not escaped)."
    local cp_entries="\"ref\":\"$REF\""
    for pair in "${PAYLOAD_KV[@]:-}"; do
      local key="${pair%%=*}"
      local val="${pair#*=}"
      cp_entries+=",\"$key\":\"$val\""
    done
    PAYLOAD_JSON="{\"event_type\":\"$EVENT_TYPE\",\"client_payload\":{${cp_entries}}}"
  fi
}

build_payload

debug "Payload JSON: $PAYLOAD_JSON"

API_URL="https://api.github.com/repos/${REPO}/dispatches"

# ---------------------------
# Dry Run Path
# ---------------------------
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[DRY-RUN] Would POST to: $API_URL"
  echo "[DRY-RUN] Payload: $PAYLOAD_JSON"
  if [[ -n "$TOKEN" ]]; then
    echo "[DRY-RUN] Auth: Bearer **** (redacted)"
  else
    echo "[DRY-RUN] No token (would fail unless using gh api manually)."
  fi
  exit 0
fi

# ---------------------------
# Dispatch
# ---------------------------
HTTP_CODE=""
TMP_BODY="$(mktemp)"
trap 'rm -f "$TMP_BODY"' EXIT

dispatch_with_curl() {
  info "Dispatching via direct REST API..."
  set +e
  HTTP_CODE=$($CURL_BIN -sS -o "$TMP_BODY" -w '%{http_code}' \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -X POST "$API_URL" \
    -d "$PAYLOAD_JSON")
  CURL_STATUS=$?
  set -e
  if [[ $CURL_STATUS -ne 0 ]]; then
    err "curl transport error (exit $CURL_STATUS)"
    return 4
  fi
  return 0
}

dispatch_with_gh() {
  info "Dispatching via gh api fallback..."
  set +e
  # gh api returns 204 without body; capture stderr for errors.
  gh api -X POST "repos/${REPO}/dispatches" --input - <<<"$PAYLOAD_JSON" 1>"$TMP_BODY" 2>&1
  local gh_status=$?
  set -e
  if [[ $gh_status -ne 0 ]]; then
    err "gh api failed: $(<"$TMP_BODY")"
    return 2
  fi
  HTTP_CODE="204"
  return 0
}

RESULT=0
if [[ -n "$TOKEN" ]]; then
  dispatch_with_curl || RESULT=$?
else
  if command -v gh >/dev/null 2>&1; then
    dispatch_with_gh || RESULT=$?
  else
    err "No token and gh CLI not available."
    exit 3
  fi
fi

if [[ $RESULT -ne 0 ]]; then
  exit "$RESULT"
fi

# ---------------------------
# Evaluate Response
# ---------------------------
BODY="$(<"$TMP_BODY")"
if [[ "$HTTP_CODE" == "204" || "$HTTP_CODE" == "201" ]]; then
  info "Dispatch accepted (HTTP $HTTP_CODE)."
  if [[ "$JSON_OUTPUT" -eq 1 ]]; then
    printf '{"ok":true,"http_code":%s,"event_type":"%s","repo":"%s","ref":"%s"}\n' \
      "$HTTP_CODE" "$EVENT_TYPE" "$REPO" "$REF"
  else
    echo "Success: event_type=${EVENT_TYPE} repo=${REPO} ref=${REF} http=${HTTP_CODE}"
  fi
  exit 0
fi

# Non-success
err "API returned HTTP $HTTP_CODE"
[ "$VERY_VERBOSE" -ge 1 ] && echo "Response Body: ${BODY:-<empty>}"

if [[ "$JSON_OUTPUT" -eq 1 ]]; then
  # Try to wrap body safely
  esc_body="${BODY//\"/\\\"}"
  printf '{"ok":false,"http_code":%s,"event_type":"%s","repo":"%s","ref":"%s","body":"%s"}\n' \
    "$HTTP_CODE" "$EVENT_TYPE" "$REPO" "$REF" "$esc_body"
else
  echo "Body: ${BODY:-<empty>}"
fi

# Heuristic: show targeted hint for known anomaly
if grep -qi "does not have 'workflow_dispatch' trigger" <<<"$BODY"; then
  echo
  echo "Hint: This matches the known indexing anomaly (new workflows failing manual dispatch)."
  echo "      Continue using repository_dispatch / tag fallback; escalate with diagnostics bundle."
fi

exit 2
