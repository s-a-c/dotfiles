#!/usr/bin/env bash
# Hardened preflight insertion (added 2025-10-02):
# Adds _preflight_hardening function to enforce:
#   - Stray artifact detector (numeric root entries)
#   - Redirection misuse lint (spacing errors like '> 2')
# Skippable via PROMOTE_SKIP_PREFLIGHT=1

_preflight_hardening() {
  if [[ "${PROMOTE_SKIP_PREFLIGHT:-0}" == "1" ]]; then
    printf '[INFO] Preflight hardening skipped by PROMOTE_SKIP_PREFLIGHT=1\n' >&2
    return 0
  fi
  # Must be run from zsh/ root (already validated later, but guard anyway)
  if [[ ! -f "docs/fix-zle/plan-of-attack.md" ]]; then
    printf '[WARN] Preflight: not in repo root; skipping hardening checks\n' >&2
    return 0
  fi
  local fail=0

  # Stray artifact detector
  if [[ -x "tools/detect-stray-artifacts.zsh" ]]; then
    if ! zsh tools/detect-stray-artifacts.zsh --json --quiet >/dev/null 2>&1; then
      printf '[ERROR] Preflight: stray artifact detector failed (numeric root entry detected)\n' >&2
      fail=1
    else
      printf '[INFO] Preflight: stray artifact scan passed\n' >&2
    fi
  else
    printf '[INFO] Preflight: detector missing (tools/detect-stray-artifacts.zsh) – continuing\n' >&2
  fi

  # Redirection lint
  if [[ -x "tools/lint-redirections.zsh" ]]; then
    if ! zsh tools/lint-redirections.zsh --json --quiet >/dev/null 2>&1; then
      printf '[ERROR] Preflight: redirection lint failed (suspicious redirection spacing)\n' >&2
      fail=1
    else
      printf '[INFO] Preflight: redirection lint passed\n' >&2
    fi
  else
    printf '[INFO] Preflight: redirection lint script missing (tools/lint-redirections.zsh) – continuing\n' >&2
  fi

  if (( fail )); then
    printf '[ERROR] Preflight hardening failed; aborting.\n' >&2
    exit 2
  fi
}

# promote-layer.sh
#
# Phase: Post-Phase7 Layer Governance (Roadmap Implementation + Checksum Ingestion + Manifest Seed)
#
# Purpose:
#   Automate promotion of a prepared ZSH layer set (e.g. from 00 -> 01),
#   perform health validation (widget baseline, segment instrumentation validity,
#   abbreviation markers), update an auditable manifest, archive the previous
#   stable set, optionally rollback to a prior layer, seed an initial manifest
#   entry for the current active layer, and ingest canonicalized segment
#   checksum digests into each manifest entry when segment validation is enabled.
#
# Features:
#   * Promotion: Validates candidate layer directories exist, runs health checks,
#     flips symlinks (.zshrc.* -> versioned dirs).
#   * Validation: Executes smoke + aggregator (segments optional) and enforces:
#       - widget_count >= baseline (default 417)
#       - segments_valid==true if segments embedded
#   * Checksum Ingestion: When segments are enabled and a live segment file exists,
#       runs segment-canonicalize.sh (NDJSON, gzip) and appends resulting sha256
#       digest to manifest entry checksum_set.
#   * Manifest: layers/manifest.json (atomic write) logs promotions, rollbacks,
#       and seed events.
#   * Seed: `seed` command records the currently active layer in the manifest
#       without changing symlinks or archiving (initialization).
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
#   Seed manifest with current active layer (no symlink changes):
#     ./zsh/tools/promote-layer.sh seed --commit "$(git rev-parse --short HEAD)" --rationale "Initialize manifest with active layer"
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
#   PROMOTE_SNAPSHOT=1 (append validation snapshot on success)
#   PROMOTE_SNAPSHOT_FORCE=1 (allow forced snapshot below baseline; requires PROMOTE_SNAPSHOT_REASON)
#   PROMOTE_SNAPSHOT_REASON="text" (justification for forced snapshot)
#   PROMOTE_SNAPSHOT_APPROVED=1 (bypass protected branch force gate)
#   PROMOTE_SNAPSHOT_DRY_STAGE=1 (when --dry-run used: stage snapshot line only; do not append to plan-of-attack)
#   PROMOTE_SNAPSHOT_DRY_STAGE_FILE=path (optional file to receive staged snapshot line; default artifacts/promotion-snapshot-dry-run.txt)
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

# Snapshot helper: invoked post-promotion if PROMOTE_SNAPSHOT=1
_run_promotion_snapshot() {
  local snapshot_script="zsh/tools/append-validation-snapshot.sh"
  [[ -x "${snapshot_script}" ]] || { printf '[WARN] snapshot script not executable (%s)\n' "${snapshot_script}" >&2; return 0; }

  # Prepare environment overrides:
  export WIDGETS="${WIDGET_COUNT:-}"
  export SEG_VALID="${SEG_VALID:-unknown}"

  local args=()
  if [[ "${PROMOTE_SNAPSHOT_FORCE:-0}" == "1" ]]; then
    if [[ -z "${PROMOTE_SNAPSHOT_REASON:-}" ]]; then
      printf '[ERROR] PROMOTE_SNAPSHOT_FORCE=1 requires PROMOTE_SNAPSHOT_REASON.\n' >&2
      return 1
    fi
    args+=(--force --reason "${PROMOTE_SNAPSHOT_REASON}")
    if [[ "${PROMOTE_SNAPSHOT_APPROVED:-0}" == "1" ]]; then
      export SNAPSHOT_FORCE_APPROVED=1
    fi
  fi

  # Dry-run staging mode: when overall promotion is --dry-run AND PROMOTE_SNAPSHOT_DRY_STAGE=1,
  # we do NOT append to plan-of-attack; we just capture the would-be snapshot line.
  if (( DRY_RUN )) && [[ "${PROMOTE_SNAPSHOT_DRY_STAGE:-0}" == "1" ]]; then
    local stage_file="${PROMOTE_SNAPSHOT_DRY_STAGE_FILE:-artifacts/promotion-snapshot-dry-run.txt}"
    mkdir -p "$(dirname "$stage_file")"
    printf '[INFO] Staging snapshot line only (dry-run, no append): %s\n' "$stage_file" >&2
    if line="$("${snapshot_script}" --dry-run --line-only "${args[@]}")"; then
      printf '%s\n' "$line" > "$stage_file"
      printf '[INFO] Staged snapshot line written.\n' >&2
      return 0
    else
      printf '[WARN] Failed to stage snapshot line (non-fatal).\n' >&2
      return 0
    fi
  fi

  printf '[INFO] Appending validation snapshot (post-promotion)...\n' >&2
  if "${snapshot_script}" "${args[@]}"; then
    printf '[INFO] Snapshot appended successfully.\n' >&2
  else
    printf '[WARN] Snapshot append failed (non-fatal to promotion).\n' >&2
  fi
}

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

Options (for promote / rollback / seed):
  --commit <hash>       Source commit short hash (auto-detected if git present)
  --rationale <text>    Human-readable rationale (RECOMMENDED)
  --with-segments       Run aggregator with segment embedding + validation (promotion only)
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
  $SCRIPT_NAME promote 01 --with-segments --commit \$(git rev-parse --short HEAD)
  $SCRIPT_NAME rollback 00 --commit \$(git rev-parse --short HEAD) --rationale "Revert regression"

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
  promote|rollback|status|seed) : ;;
  --help|-h) usage; exit 0 ;;
  *) err "Unknown command: ${CMD}"; usage; exit 1 ;;
esac

while (($#)); do
  case "$1" in
    --commit)
      shift || { err "--commit requires value"; exit 1; }
      COMMIT="$1"
      ;;
    --rationale)
      shift || { err "--rationale requires value"; exit 1; }
      RATIONALE="$1"
      ;;
    --with-segments) WITH_SEGMENTS=1 ;;
    --no-segments) WITH_SEGMENTS=0 ;;
    --baseline)
      shift || { err "--baseline requires value"; exit 1; }
      WIDGET_BASELINE="$1"
      ;;
    --dry-run) DRY_RUN=1 ;;
    --quiet) QUIET=1 ;;
    --manifest-only) MANIFEST_ONLY=1 ;;
    --help|-h) usage; exit 0 ;;
    -*)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      if [[ -z "${TARGET_LAYER:-}" && "${CMD}" != "status" ]]; then
        TARGET_LAYER="$1"
      else
        err "Unexpected argument: $1"
        usage
        exit 1
      fi
      ;;
  esac
  shift || true
done

if [[ "${CMD}" != "status" && "${CMD}" != "seed" && -z "${TARGET_LAYER:-}" ]]; then
  err "Layer id required for ${CMD}"
  exit 1
fi

# Env override for segments
if [[ "${LAYER_SEGMENTS_ENABLE:-0}" == "1" ]]; then
  FORCE_SEGMENTS_ENV=1
  WITH_SEGMENTS=1
fi

# Auto-detect commit hash if not provided
if [[ -z "${COMMIT:-}" && "${CMD}" != "status" ]]; then
  if command -v git >/dev/null 2>&1; then
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      COMMIT="$(git rev-parse --short HEAD 2>/dev/null || true)"
    fi
  fi
fi
[[ -z "${COMMIT:-}" ]] && COMMIT="unknown"

# ------------- Quiet Logging Gate --------------------------------------------
if (( QUIET )); then
  log()  { :; }
  warn() { :; }
fi

# ------------- Repo Sanity (Run from zsh/ root) -------------------------------
ensure_repo_root() {
  # Heuristic: expect docs/fix-zle/plan-of-attack.md to exist
  if [[ ! -f "docs/fix-zle/plan-of-attack.md" ]]; then
    err "Run this script from the zsh/ configuration root (docs/fix-zle/plan-of-attack.md not found)."
    exit 1
  fi
}
ensure_repo_root

# ------------- Layer Discovery ------------------------------------------------
current_layer_from_symlink() {
  # Inspect one representative symlink (.zshrc.d) to derive current layer id
  local ref
  if [[ -L ".zshrc.d" ]]; then
    ref="$(readlink ".zshrc.d" 2>/dev/null || true)"
    # Expect pattern .zshrc.d.<id>
    if [[ "$ref" =~ \.zshrc\.d\.([0-9][0-9])$ ]]; then
      printf '%s' "${BASH_REMATCH[1]}"
      return 0
    fi
  fi
  # Fallback: parse environment marker if running in an active shell context
  if [[ -n "${_ZF_LAYER_SET:-}" ]]; then
    printf '%s' "${_ZF_LAYER_SET}"
    return 0
  fi
  # Default to 00 if unknown
  printf '00'
}

ACTIVE_LAYER="$(current_layer_from_symlink)"

# ------------- Status Command -------------------------------------------------
if [[ "${CMD}" == "status" ]]; then
  printf "Active Layer (symlink-derived): %s\n" "${ACTIVE_LAYER}"
  printf "Widget Baseline Policy: >= %s\n" "${WIDGET_BASELINE}"
  if [[ -f "${MANIFEST_FILE}" ]]; then
    printf "Manifest: %s\n" "${MANIFEST_FILE}"
    # Show last 3 entries quickly (manual grep/tail if no jq)
    if command -v jq >/dev/null 2>&1; then
      jq '(.layers // []) | sort_by(.timestamp) | reverse | .[:3]' "${MANIFEST_FILE}"
    else
      grep -E '"layer"|timestamp' "${MANIFEST_FILE}" | tail -n 12 || true
    fi
  else
    printf "Manifest: (not yet created)\n"
  fi
  exit 0
fi

# ------------- Validation Helpers --------------------------------------------
require_layer_dirs() {
  local layer="$1"
  local missing=0
  for base in .zshrc.pre-plugins.d .zshrc.add-plugins.d .zshrc.d; do
    local path="${base}.${layer}"
    if [[ ! -d "${path}" ]]; then
      err "Missing directory for layer ${layer}: ${path}"
      missing=1
    fi
  done
  if (( missing )); then
    return 1
  fi
  return 0
}

# ------------- Health Check (Smoke + Aggregator) ------------------------------
run_health_checks() {
  local layer="$1"
  local segments="$2" # 1 or 0
  local tmpdir
  tmpdir="$(mktemp -d)"
  local agg_json="${tmpdir}/aggregate.json"
  local seg_flag=()
  local seg_file=""

  # Optionally enable live segment capture for the aggregator run
  if (( segments == 1 )); then
    export ZF_SEGMENT_CAPTURE=1
    seg_file="${HOME}/.cache/zsh/segments/live-segments.ndjson"
    seg_flag=(--segment-file "${seg_file}" --embed-segments --require-segments-valid)
  else
    unset ZF_SEGMENT_CAPTURE || true
  fi

  # The aggregator script uses the *current* symlinked directories.
  # If promoting, we validate the candidate layer by temporarily pointing symlinks
  # in a subshell (without altering working copy) to the candidate directories.
  # Implementation: create a throwaway sandbox symlink set inside tmpdir and
  # run ZDOTDIR there.

  # Build sandbox
  local sandbox="${tmpdir}/sandbox"
  mkdir -p "${sandbox}"
  for base in .zshrc.pre-plugins.d .zshrc.add-plugins.d .zshrc.d; do
    ln -s "../../${base}.${layer}" "${sandbox}/${base}"
  done

  # Copy aggregator & tests path reference (invoked relative to repo root)
  # We'll set ZDOTDIR to sandbox so zsh resolves symlinks there.
  local envwrap="${tmpdir}/envwrap.sh"
  cat > "${envwrap}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export ZDOTDIR="\$(pwd)/${sandbox}"
# Basic smoke via aggregator
bash docs/fix-zle/tests/aggregate-json-tests.sh \\
  --run-pty \\
  ${segments:+${seg_flag[*]}} \\
  --output "${agg_json}" \\
  --quiet || exit 2
EOF
  chmod +x "${envwrap}"

  bash "${envwrap}" || return 2

  # Extract metrics (no jq dependency)
  local widget_count
  widget_count="$(grep -Eo '"widget_count":[0-9]+' "${agg_json}" | head -n1 | cut -d: -f2 || echo 0)"
  local segments_valid
  segments_valid="$(grep -Eo '"segments_valid":(true|false|null)' "${agg_json}" | head -n1 | cut -d: -f2 || echo null)"

  if [[ -z "${widget_count}" ]]; then
    err "Failed to parse widget_count from aggregator output"
    return 2
  fi
  if (( widget_count < WIDGET_BASELINE )); then
    err "Widget baseline regression: ${widget_count} < ${WIDGET_BASELINE}"
    return 2
  fi

  if (( segments == 1 )); then
    if [[ "${segments_valid}" != "true" ]]; then
      err "Segment validation failed or not true (segments_valid=${segments_valid})"
      return 2
    fi
  fi

  # Print summary (used by caller)
  printf "%s\n" "WIDGET_COUNT=${widget_count}"
  printf "%s\n" "SEGMENTS_VALID=${segments_valid}"
  printf "%s\n" "AGG_JSON=${agg_json}"
  if (( segments == 1 )); then
    printf "%s\n" "SEGMENT_FILE=${seg_file}"
  fi
  return 0
}

# ------------- Manifest Management --------------------------------------------
init_manifest_if_needed() {
  mkdir -p "${MANIFEST_DIR}" || { err "Failed to create ${MANIFEST_DIR}"; exit 4; }
  if [[ ! -f "${MANIFEST_FILE}" ]]; then
    cat > "${MANIFEST_FILE}" <<EOF
{
  "version": 1,
  "layers": []
}
EOF
  fi
}

append_manifest_entry() {
  local layer="$1"
  local promoted_from="$2"
  local rollback_from="$3"
  local widgets="$4"
  local segments_valid="$5"
  local rationale="$6"
  local commit="$7"
  local checksum_list="${8:-}"

  init_manifest_if_needed

  local entry
  entry=$(cat <<EOF
{
  "layer": "${layer}",
  "promoted_from": ${promoted_from:+\"$promoted_from\"${rollback_from:+,}},
  ${rollback_from:+\"rollback_from\": \"${rollback_from}\",}
  "timestamp": "$(ts_utc)",
  "commit": "${commit}",
  "widgets": ${widgets},
  "segments_valid": ${segments_valid:-null},
  "rationale": ${rationale:+$(printf '%s' "$rationale" | sed 's/"/\\"/g' | awk '{printf "\"%s\"", $0}')} ,
  "checksum_set": [
$( if [[ -n "${checksum_list}" ]]; then IFS=',' read -r -a _cks <<< "${checksum_list}"; for c in "${_cks[@]}"; do printf '    "%s"\n' "${c}"; done; fi )
  ]
}
EOF
)

  # Normalize JSON (remove stray trailing comma before checksum_set if rationale empty)
  entry="$(printf '%s' "${entry}" | sed 's/, *"checksum_set"/, "checksum_set"/')"

  local tmp_manifest
  tmp_manifest="$(mktemp)"

  if command -v jq >/dev/null 2>&1; then
    if ! jq --argjson entry "${entry}" '.layers += [$entry]' "${MANIFEST_FILE}" > "${tmp_manifest}" 2>/dev/null; then
      # Fallback manual append
      warn "jq append failed; falling back to manual JSON injection"
      manual_manifest_append "${entry}" "${tmp_manifest}"
    fi
  else
    manual_manifest_append "${entry}" "${tmp_manifest}"
  fi

  if ! mv "${tmp_manifest}" "${MANIFEST_FILE}"; then
    err "Failed to write manifest atomically"
    exit 4
  fi
}

manual_manifest_append() {
  local entry="$1"
  local out="$2"
  # Very simple manual append:
  # Replace closing ] } with entry injection.
  awk -v new="${entry}" '
    BEGIN{inserted=0}
    /"layers"[[:space:]]*:[[:space:]]*\[/ {print; next}
    /"layers"[[:space:]]*:[[:space:]]*\[/ == 0 { }
    /"layers"[[:space:]]*:[[:space:]]*\[/ { }
    {lines[NR]=$0}
    END{
      # Reconstruct by searching for the layers array end
      # Simpler: read entire file into a string in shell; done minimal here.
    }' "${MANIFEST_FILE}" >/dev/null 2>&1 || true

  # Naive but safe approach: use sed to inject before last "]" of layers array.
  # This assumes manifest shape is stable (version + layers[]).
  local content
  content="$(cat "${MANIFEST_FILE}")"
  if grep -q '"layers"' <<< "${content}"; then
    # If array empty: "layers": []
    if grep -q '"layers"[^{\[]*:\s*\[\s*\]' <<< "${content}"; then
      content="$(printf '%s' "${content}" | sed 's/"layers"[[:space:]]*:[[:space:]]*\[\s*\]/"layers\":\n  [\n    '"${entry}"'\n  ]/')" || true
    else
      # Non-empty: insert before the closing ]
      content="$(printf '%s' "${content}" | sed '0,/"layers"[^\[]*\[/!b; :a; n; /]/ { s/]/  , '"${entry}"'\n  ]/; b }; ba')" || true
    fi
  else
    err "Manifest format unexpected; cannot append without jq"
    printf '%s' "${content}" > "${out}"
    return
  fi
  printf '%s' "${content}" > "${out}"
}

# ------------- Archive Previous Layer -----------------------------------------
archive_previous_layer() {
  local old_layer="$1"
  local commit="$2"

  local ts shortsha archive_path
  ts="$(date -u +%Y%m%d-%H%M%S)"
  shortsha="${commit:-unknown}"
  archive_path="${ARCHIVE_DIR}/${old_layer}-${ts}-${shortsha}"

  mkdir -p "${archive_path}" || { err "Failed to create archive path ${archive_path}"; return 3; }

  for base in .zshrc.pre-plugins.d .zshrc.add-plugins.d .zshrc.d; do
    local src="${base}.${old_layer}"
    if [[ -d "${src}" ]]; then
      cp -R "${src}" "${archive_path}/" || { err "Failed to archive ${src}"; return 3; }
    else
      warn "Archive skipping missing directory: ${src}"
    fi
  done
  log "Archived previous layer ${old_layer} -> ${archive_path}"
  return 0
}

# ------------- Symlink Flip ---------------------------------------------------
flip_symlinks() {
  local new_layer="$1"
  local -a bases=(.zshrc.pre-plugins.d .zshrc.add-plugins.d .zshrc.d)
  local b
  for b in "${bases[@]}"; do
    local target="${b}.${new_layer}"
    if [[ ! -d "${target}" ]]; then
      err "Cannot flip: target directory missing: ${target}"
      return 5
    fi
    if (( DRY_RUN )); then
      log "[dry-run] ln -snf ${target} ${b}"
    else
      ln -snf "${target}" "${b}" || { err "Failed to update symlink ${b} -> ${target}"; return 5; }
    fi
  done
  return 0
}

# ------------- PROMOTE --------------------------------------------------------
canonicalize_and_ingest_checksum() {
  local seg_path="$1"
  local checksum_var=""
  [[ -f "${seg_path}" ]] || return 0
  if command -v ./zsh/tools/segment-canonicalize.sh >/dev/null 2>&1; then
    if ./zsh/tools/segment-canonicalize.sh "${seg_path}" --ndjson --gzip --force --quiet; then
      local digest_file="${seg_path}.canonical.sha256"
      # Adjust: our canonical tool writes ${seg_path}.canonical.sha256 (base pattern)
      if [[ -f "${seg_path}.canonical.sha256" ]]; then
        checksum_var="$(cut -d: -f2 < "${seg_path}.canonical.sha256" | tr -d '[:space:]')"
      elif [[ -f "${seg_path}.canonical.sha256" ]]; then
        checksum_var="$(cut -d: -f2 < "${seg_path}.canonical.sha256" | tr -d '[:space:]')"
      fi
      if [[ -n "${checksum_var}" ]]; then
        printf '%s' "sha256:${checksum_var}"
        return 0
      fi
    fi
  fi
  return 0
}

if [[ "${CMD}" == "promote" ]]; then
  _preflight_hardening
  if [[ "${TARGET_LAYER}" == "${ACTIVE_LAYER}" ]]; then
    err "Target layer ${TARGET_LAYER} is already active."
    exit 1
  fi

  log "Promoting layer ${TARGET_LAYER} (current active: ${ACTIVE_LAYER})"
  require_layer_dirs "${TARGET_LAYER}" || { err "Layer directory validation failed"; exit 1; }

  # Run health checks (unless manifest-only)
  WIDGET_COUNT="unknown"
  SEG_VALID="null"
  if (( MANIFEST_ONLY )); then
    warn "Manifest-only mode: skipping health checks."
  else
    if output=$(run_health_checks "${TARGET_LAYER}" "${WITH_SEGMENTS}"); then
      # Parse summary lines
      WIDGET_COUNT="$(printf '%s\n' "${output}" | awk -F= '/^WIDGET_COUNT=/{print $2}')"
      SEG_VALID="$(printf '%s\n' "${output}" | awk -F= '/^SEGMENTS_VALID=/{print $2}')"
      log "Health OK: widgets=${WIDGET_COUNT} segments_valid=${SEG_VALID}"
    else
      err "Health validation failed ( aggregator / widget / segments )"
      exit 2
    fi
  fi

  # Archive existing layer (unless manifest-only)
  if (( MANIFEST_ONLY )); then
    warn "Skipping archive due to manifest-only mode."
  else
    archive_previous_layer "${ACTIVE_LAYER}" "${COMMIT}" || { err "Archival failed"; exit 3; }
  fi

  # Flip symlinks
  if (( MANIFEST_ONLY )); then
    warn "Skipping symlink flip due to manifest-only mode."
  else
    flip_symlinks "${TARGET_LAYER}" || exit 5
  fi

  # Segment checksum ingestion (optional)
  CHECKSUM_LIST=""
  if (( WITH_SEGMENTS == 1 )); then
    SEG_CANON=""
    if [[ -n "${SEGMENT_FILE:-}" && -f "${SEGMENT_FILE:-}" ]]; then
      # Use dedicated canonicalizer (quiet)
      if command -v ./zsh/tools/segment-canonicalize.sh >/dev/null 2>&1; then
        if ./zsh/tools/segment-canonicalize.sh "${SEGMENT_FILE}" --ndjson --gzip --force --quiet; then
          if [[ -f "${SEGMENT_FILE}.canonical.sha256" ]]; then
            DIGEST_LINE="$(cat "${SEGMENT_FILE}.canonical.sha256" 2>/dev/null || true)"
            if [[ "${DIGEST_LINE}" =~ ^sha256:([a-fA-F0-9]{64})$ ]]; then
              CHECKSUM_LIST="sha256:${BASH_REMATCH[1]}"
            fi
          fi
        else
          warn "Segment canonicalization failed; proceeding without checksum."
        fi
      else
        warn "segment-canonicalize.sh not found; skipping checksum ingestion."
      fi
    else
      warn "Segment file not found for checksum ingestion (${SEGMENT_FILE:-unset})."
    fi
  fi

  # Append manifest entry
  if (( DRY_RUN )); then
    log "[dry-run] Would append manifest entry for layer ${TARGET_LAYER}"
  else
    append_manifest_entry "${TARGET_LAYER}" "${ACTIVE_LAYER}" "" "${WIDGET_COUNT}" "${SEG_VALID}" "${RATIONALE:-}" "${COMMIT}" "${CHECKSUM_LIST}"
    log "Manifest updated: ${MANIFEST_FILE}"
  fi

  if [[ "${PROMOTE_SNAPSHOT:-0}" == "1" ]]; then
    _run_promotion_snapshot || true
  fi
  log "Promotion complete (${TARGET_LAYER})"
  exit 0
fi

# ------------- ROLLBACK -------------------------------------------------------
if [[ "${CMD}" == "rollback" ]]; then
  _preflight_hardening
  if [[ "${TARGET_LAYER}" == "${ACTIVE_LAYER}" ]]; then
    err "Already on target rollback layer ${TARGET_LAYER}"
    exit 1
  fi
  require_layer_dirs "${TARGET_LAYER}" || { err "Rollback layer directories missing"; exit 1; }

  log "Rolling back from ${ACTIVE_LAYER} -> ${TARGET_LAYER}"

  # Validate rollback candidate health
  if output=$(run_health_checks "${TARGET_LAYER}" 0); then
    WIDGET_COUNT="$(printf '%s\n' "${output}" | awk -F= '/^WIDGET_COUNT=/{print $2}')"
    log "Rollback candidate health OK: widgets=${WIDGET_COUNT}"
  else
    err "Rollback validation failed"
    exit 2
  fi

  if (( DRY_RUN )); then
    log "[dry-run] Would flip symlinks to layer ${TARGET_LAYER}"
    log "[dry-run] Would append rollback manifest entry"
    exit 0
  fi

  flip_symlinks "${TARGET_LAYER}" || exit 5
  append_manifest_entry "${TARGET_LAYER}" "" "${ACTIVE_LAYER}" "${WIDGET_COUNT:-null}" "null" "${RATIONALE:-Rollback}" "${COMMIT}" ""
  if [[ "${PROMOTE_SNAPSHOT:-0}" == "1" ]]; then
    _run_promotion_snapshot || true
  fi
  log "Rollback complete (${TARGET_LAYER})"
  exit 0
fi

# ------------- SEED (Manifest Initialization) ---------------------------------
if [[ "${CMD}" == "seed" ]]; then
  log "Seeding manifest with current active layer ${ACTIVE_LAYER}"
  init_manifest_if_needed
  # Avoid duplicate seed if already present
  if grep -q "\"layer\": \"${ACTIVE_LAYER}\"" "${MANIFEST_FILE}" 2>/dev/null; then
    warn "Manifest already contains an entry for layer ${ACTIVE_LAYER}; adding another seed entry anyway."
  fi
  append_manifest_entry "${ACTIVE_LAYER}" "" "" "null" "null" "${RATIONALE:-Seed manifest}" "${COMMIT}" ""
  log "Seed complete (${ACTIVE_LAYER})"
  exit 0
fi

# Should not reach here
err "Unhandled command path"
exit 1
