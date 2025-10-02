#!/usr/bin/env bash
# archive-batch.sh
#
# Purpose:
#   Archive unused / legacy ZSH tooling, tests, or docs into the .ARCHIVE
#   directory while preserving relative paths and recording an auditable
#   manifest entry (batch-based, append-only).
#
# Features:
#   - Batch archival with consistent batch_id (timestamp + short git sha when available)
#   - Dry-run mode (no filesystem mutations)
#   - Auto manifest creation / update (JSON)
#   - Per-file metadata: original_path, archived_path, reason, sha256, size_bytes, executable
#   - Reference guard: skips files still referenced in workflow YAML (unless --force)
#   - Duplicate avoidance: refuses to re-archive an already archived path
#   - Optional exclusions
#
# Manifest Schema (version 1):
# {
#   "version": 1,
#   "batches": [
#     {
#       "batch_id": "20251001-1847-abcd123",
#       "archived_at": "2025-10-01T18:47:00Z",
#       "files": [
#         {
#           "original_path": "zsh/tools/legacy-script.sh",
#           "archived_path": "zsh/.ARCHIVE/tools/legacy-script.sh",
#           "reason": "legacy-migration",
#           "sha256": "sha256:<digest>",
#           "size_bytes": 1234,
#           "executable": true
#         }
#       ]
#     }
#   ]
# }
#
# Exit Codes:
#   0  All files archived successfully
#   1  Usage / argument error
#   2  Partial success (some files skipped)
#   3  Fatal error (I/O or manifest write failure)
#
# Usage Examples:
#   # Archive an explicit set (dry run)
#   ./zsh/tools/archive-batch.sh --dry-run --reason legacy-migration zsh/tools/old-a.sh zsh/tools/old-b.sh
#
#   # Archive from a list file (one path per line)
#   ./zsh/tools/archive-batch.sh --files-from archive-list.txt --reason legacy-migration
#
#   # Add incrementally with multiple --add flags
#   ./zsh/tools/archive-batch.sh --add zsh/tools/old-a.sh --add zsh/tools/old-b.sh --reason legacy-migration
#
#   # Skip workflow reference guard
#   ./zsh/tools/archive-batch.sh --force --add zsh/tools/dev-helper.sh --reason obsolete-helper
#
# Safety:
#   - set -euo pipefail
#   - All optional expansions guarded
#   - No destructive edits on existing manifest (atomic temp write)
#
# Dependencies:
#   - sha256sum OR shasum
#   - jq (optional; improves JSON merge)
#
set -euo pipefail

# -----------------------
# Defaults / Globals
# -----------------------
SCRIPT_NAME="archive-batch.sh"

# PROJECT_ROOT: the canonical root of the active zsh project (where tools/, .github/, .zshrc* live)
# Can be overridden by environment: export PROJECT_ROOT=/absolute/path/to/dot-config/zsh
PROJECT_ROOT="${PROJECT_ROOT:-}"

# Legacy ROOT variable retained for minimal downstream disturbance (will be set to PROJECT_ROOT)
ROOT="."

# Archive directory (always relative to PROJECT_ROOT)
ARCHIVE_DIR=".ARCHIVE"
MANIFEST="${ARCHIVE_DIR}/manifest.json"

REASON="legacy"
DRY_RUN=0
FORCE=0
BATCH_ID=""
FILES_FROM=""
declare -a ADD_FILES
declare -a EXCLUDES
QUIET=0
DEBUG=0

# -----------------------
# Logging
# -----------------------
log()  { (( QUIET )) || printf '[INFO] %s\n' "$*" >&2; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err()  { printf '[ERROR] %s\n' "$*" >&2; }
dbg()  { (( DEBUG )) && printf '[DEBUG] %s\n' "$*" >&2; }

# -----------------------
# Usage
# -----------------------
usage() {
  cat <<EOF
$SCRIPT_NAME - Archive legacy / inactive files into .ARCHIVE with manifest logging.

Usage:
  $SCRIPT_NAME [options] [file1 file2 ...]

Options:
  --root <path>          Repository root (default: .)
  --reason <text>        Reason label for all files in this batch (default: legacy)
  --files-from <file>    File containing newline-separated paths to archive
  --add <path>           Add a single file (can repeat)
  --exclude <path>       Exclude a path (can repeat; takes precedence)
  --batch-id <id>        Override auto-generated batch id
  --manifest <path>      Override manifest file path (default: zsh/.ARCHIVE/manifest.json)
  --dry-run              Show actions without performing changes
  --force                Skip workflow reference guard (force archive)
  --quiet                Reduce non-error output
  --debug                Enable verbose path / existence diagnostics
  --help                 Show this help

Exit Codes:
  0 success
  1 usage error
  2 partial success (some files skipped)
  3 fatal error (manifest write or I/O)

Notes:
  - Paths must be relative to repo root.
  - Files already under .ARCHIVE/ are ignored.
  - Workflow reference guard scans .github/workflows/*.yml for basename presence.
EOF
}

# -----------------------
# Parse Args
# -----------------------
while (($#)); do
  case "$1" in
    --root) shift || { err "--root requires value"; exit 1; }; ROOT="$1" ;;
    --reason) shift || { err "--reason requires value"; exit 1; }; REASON="$1" ;;
    --files-from) shift || { err "--files-from requires file"; exit 1; }; FILES_FROM="$1" ;;
    --add) shift || { err "--add requires path"; exit 1; }; ADD_FILES+=("$1") ;;
    --exclude) shift || { err "--exclude requires path"; exit 1; }; EXCLUDES+=("$1") ;;
    --batch-id) shift || { err "--batch-id requires id"; exit 1; }; BATCH_ID="$1" ;;
    --manifest) shift || { err "--manifest requires path"; exit 1; }; MANIFEST="$1" ;;
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --quiet) QUIET=1 ;;
    --debug) DEBUG=1 ;;
    --help|-h) usage; exit 0 ;;
    -*)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      ADD_FILES+=("$1")
      ;;
  esac
  shift || true
done

# Normalize incoming paths for invocation contexts:
# 1. Called from repo root with paths like zsh/tools/...
# 2. Called from inside zsh project root with paths like tools/...
# 3. Mixed usage – strip leading ./ and adjust if needed.
if [[ -n "${ADD_FILES[*]:-}" ]]; then
  dbg "Normalizing input path list (${#ADD_FILES[@]} entries)"
  _norm=()
  for p in "${ADD_FILES[@]}"; do
    orig="$p"
    p="${p#./}"
    # If we're already inside zsh project root and path starts with zsh/, try stripping
    if [[ -f "${p}" ]]; then
      _norm+=("$p")
      dbg "Keep(path-exists): $orig -> $p"
      continue
    fi
    if [[ "${p}" == zsh/* && -f "${p#zsh/}" ]]; then
      dbg "Strip leading zsh/: $orig -> ${p#zsh/}"
      _norm+=("${p#zsh/}")
      continue
    fi
    # If missing but adding zsh/ makes it exist and we are at repo root
    if [[ ! "$p" == zsh/* && -d "zsh" && -f "zsh/${p}" ]]; then
      dbg "Prefix with zsh/: $orig -> zsh/${p}"
      _norm+=("zsh/${p}")
      continue
    fi
    dbg "Unchanged (no resolution heuristic matched): $orig"
    _norm+=("$p")
  done
  ADD_FILES=("${_norm[@]}")
fi

# -----------------------
# Validate Inputs
# -----------------------
if [[ -n "${FILES_FROM}" ]]; then
  if [[ ! -f "${FILES_FROM}" ]]; then
    err "files-from list not found: ${FILES_FROM}"
    exit 1
  fi
  while IFS= read -r line; do
    [[ -z "${line// /}" ]] && continue
    ADD_FILES+=("$line")
  done < "${FILES_FROM}"
fi

if [[ ${#ADD_FILES[@]} -eq 0 ]]; then
  err "No files specified (use positional paths, --add, or --files-from)."
  usage
  exit 1
fi

# Normalize root
if [[ ! -d "${ROOT}" ]]; then
  err "Root directory does not exist: ${ROOT}"
  exit 1
fi

# Resolve PROJECT_ROOT deterministically:
# Priority:
#   1. Explicit $PROJECT_ROOT env (must exist)
#   2. Current directory if it contains hallmark files (tools/promote-layer.sh or .github/workflows)
#   3. If current directory has a zsh/ subdir containing tools/, treat that subdir as project root
#   4. Fallback: current directory
if [[ -n "${PROJECT_ROOT}" ]]; then
  if [[ ! -d "${PROJECT_ROOT}" ]]; then
    err "PROJECT_ROOT specified but not a directory: ${PROJECT_ROOT}"
    exit 1
  fi
else
  if [[ -f "tools/promote-layer.sh" || -d ".github/workflows" ]]; then
    PROJECT_ROOT="$(pwd)"
  elif [[ -d "zsh/tools" ]]; then
    PROJECT_ROOT="$(pwd)/zsh"
  else
    PROJECT_ROOT="$(pwd)"
    warn "PROJECT_ROOT inferred as current directory (no nested zsh/ or hallmark files detected)."
  fi
fi

# Enter project root to normalize relative path handling
if ! pushd "${PROJECT_ROOT}" >/dev/null 2>&1; then
  err "Failed to enter PROJECT_ROOT: ${PROJECT_ROOT}"
  exit 1
fi

# ROOT compatibility (some later code concatenates ROOT + path)
ROOT="${PROJECT_ROOT}"

dbg "PROJECT_ROOT=${PROJECT_ROOT}"
dbg "ARCHIVE_DIR=${ARCHIVE_DIR}"

# -----------------------
# Prepare Batch ID
# -----------------------
if [[ -z "${BATCH_ID}" ]]; then
  ts="$(date -u +%Y%m%d-%H%M)"
  shortsha="nogit"
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    shortsha="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
  fi
  BATCH_ID="${ts}-${shortsha}"
fi

# RFC3339 timestamp
BATCH_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# -----------------------
# Collect Candidate Files
# -----------------------
# macOS system bash (3.x) lacks associative arrays; replace map with helper function
is_excluded() {
  local candidate="$1"
  local e
  for e in "${EXCLUDES[@]:-}"; do
    [[ "$e" == "$candidate" ]] && return 0
  done
  # Not excluded
  return 1
}

declare -a TO_ARCHIVE

dedupe() {
  # Remove duplicates while preserving order
  awk '!seen[$0]++'
}

# Sanitize & filter
# Build deduped list without pipeline subshell (bash 3.x compatibility)
DEDUPED_LIST=()
while IFS= read -r _line; do
  [[ -z "${_line// /}" ]] && continue
  DEDUPED_LIST+=("${_line}")
done < <(printf '%s\n' "${ADD_FILES[@]}" | dedupe)

for path in "${DEDUPED_LIST[@]}"; do
  [[ -z "${path// /}" ]] && continue
  dbg "Candidate(raw)=${path}"
  # Normalize leading ./ if present
  path="${path#./}"

  # Adjust if path omits zsh/ but only exists with zsh/ prefix (repo-root invocation)
  if [[ ! -f "${ROOT}/${path}" && -f "${ROOT}/zsh/${path}" ]]; then
    dbg "Adjusted -> zsh/${path}"
    path="zsh/${path}"
  fi

  if is_excluded "$path"; then
    for ex in "${EXCLUDES[@]:-}"; do
      [[ "$ex" == "$path" ]] && { log "Excluded: $path"; continue 2; }
    done
  fi
  # Ignore already archived paths
  if [[ "$path" == zsh/.ARCHIVE/* ]]; then
    log "Already archived (skipping): $path"
    continue
  fi
  if [[ ! -f "${ROOT}/${path}" ]]; then
    dbg "Not found after normalization: ${ROOT}/${path}"
  else
    dbg "Resolved file: ${ROOT}/${path}"
  fi
  TO_ARCHIVE+=("$path")
done

if [[ ${#TO_ARCHIVE[@]} -eq 0 ]]; then
  warn "No remaining files to archive after exclusions."
  exit 0
fi

# -----------------------
# Verify Existence
# -----------------------
declare -a FINAL_FILES
for f in "${TO_ARCHIVE[@]}"; do
  if [[ ! -f "${ROOT}/${f}" ]]; then
    warn "File not found (skipping): ${f}"
    continue
  fi
  FINAL_FILES+=("$f")
done

if [[ ${#FINAL_FILES[@]} -eq 0 ]]; then
  warn "No existing files to archive."
  exit 0
fi

# -----------------------
# Workflow Reference Guard
# -----------------------
WORKFLOW_DIR="${ZSH_BASE}/.github/workflows"
# Use plain list instead of associative array for POSIX / bash 3.x compatibility
SKIP_REF_LIST=""
if [[ -d "${WORKFLOW_DIR}" && ${FORCE} -eq 0 ]]; then
  for f in "${FINAL_FILES[@]}"; do
    base="${f##*/}"
    # Grep only yaml workflows; if referenced -> skip
    if grep -R -F -q -- "${base}" "${WORKFLOW_DIR}" 2>/dev/null; then
      warn "Referenced in workflow (skipping, use --force to override): ${f}"
      SKIP_REF_LIST="${SKIP_REF_LIST}::$f"
    fi
  done
fi

# -----------------------
# Prepare Manifest
# -----------------------
mkdir -p "${ROOT}/${ARCHIVE_DIR}" || { err "Failed to create archive dir: ${ARCHIVE_DIR}"; exit 3; }

if [[ ! -f "${ROOT}/${MANIFEST}" ]]; then
  log "Creating new manifest: ${MANIFEST}"
  if (( DRY_RUN )); then
    :
  else
    cat > "${ROOT}/${MANIFEST}" <<EOF
{
  "version": 1,
  "batches": []
}
EOF
  fi
fi

# -----------------------
# Archive Operation
# -----------------------
declare -a BATCH_JSON_ENTRIES
SKIPPED=0
ARCHIVED=0

hash_tool=""
if command -v sha256sum >/dev/null 2>&1; then
  hash_tool="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  hash_tool="shasum -a 256"
else
  err "No sha256 capable tool (sha256sum or shasum) found."
  exit 3
fi

for f in "${FINAL_FILES[@]}"; do
  case "${SKIP_REF_LIST}::" in
    *"::$f::"*) ((SKIPPED++)); continue ;;
  esac

  abs_src="${f}"
  # If f is not absolute, prefix with PROJECT_ROOT
  [[ "${abs_src}" != /* ]] && abs_src="${PROJECT_ROOT}/${abs_src}"
  dbg "Process candidate: f='${f}' abs='${abs_src}'"
  if [[ ! -f "${abs_src}" ]]; then
    warn "File disappeared during processing (skip): ${f}"
    ((SKIPPED++))
    continue
  else
    dbg "Exists: ${abs_src}"
  fi

  digest_line="$($hash_tool "${abs_src}" 2>/dev/null || true)"
  digest="$(printf '%s' "${digest_line}" | awk '{print $1}' | tr -d '[:space:]')"
  if [[ -z "${digest}" ]]; then
    warn "Unable to compute digest (skip): ${f}"
    ((SKIPPED++))
    continue
  fi
  size_bytes=$(wc -c < "${abs_src}" | tr -d '[:space:]')
  exec_flag="false"
  [[ -x "${abs_src}" ]] && exec_flag="true"

  # Destination path (normalize to avoid duplicate leading zsh/)
  rel_path="${f#./}"
  if [[ "${rel_path}" == zsh/* ]]; then
    rel_path="${rel_path#zsh/}"
  fi
  rel_path="${rel_path#./}"
  dest="${ARCHIVE_DIR}/${rel_path}"
  # Collapse any accidental duplicate .ARCHIVE segments
  dest="${dest//.ARCHIVE\/.ARCHIVE/.ARCHIVE}"
  dbg "Archive destination resolved: ${dest}"

  dest_dir="$(dirname "${ROOT}/${dest}")"
  if (( DRY_RUN )); then
    log "[dry-run] mv ${f} -> ${dest}"
  else
    mkdir -p "${dest_dir}" || { err "Failed to create dest dir: ${dest_dir}"; exit 3; }
    mv "${abs_src}" "${ROOT}/${dest}" || { err "Move failed: ${f} -> ${dest}"; exit 3; }
  fi

  ARCHIVED=$((ARCHIVED + 1))

  # JSON entry (indentation handled later)
  BATCH_JSON_ENTRIES+=("{
      \"original_path\": \"${f}\",
      \"archived_path\": \"${dest}\",
      \"reason\": \"${REASON}\",
      \"sha256\": \"sha256:${digest}\",
      \"size_bytes\": ${size_bytes},
      \"executable\": ${exec_flag}
    }")
done

# -----------------------
# Build Batch JSON
# -----------------------
if (( ARCHIVED > 0 )); then
  batch_obj="{
    \"batch_id\": \"${BATCH_ID}\",
    \"archived_at\": \"${BATCH_TS}\",
    \"files\": [
$( IFS=$'\n'; printf '      %s\n' "$(printf '%s\n' "${BATCH_JSON_ENTRIES[@]}" | sed '1!s/^/, /')" )
    ]
  }"
fi

# -----------------------
# Append to Manifest
# -----------------------
if (( ARCHIVED > 0 )); then
  if (( DRY_RUN )); then
    log "[dry-run] Would append batch to manifest: ${MANIFEST}"
  else
    tmp_manifest="$(mktemp)"
    if command -v jq >/dev/null 2>&1; then
      if ! jq --argjson batch "${batch_obj}" '.batches += [$batch]' "${ROOT}/${MANIFEST}" > "${tmp_manifest}" 2>/dev/null; then
        warn "jq append failed; falling back to manual JSON injection."
      else
        mv "${tmp_manifest}" "${ROOT}/${MANIFEST}"
        tmp_manifest=""
      fi
    fi
    if [[ -n "${tmp_manifest}" ]]; then
      # Manual fallback
      content="$(cat "${ROOT}/${MANIFEST}")"
      # Manual fallback without fragile multi-line sed (handle empty or non-empty batches)
      if command -v python3 >/dev/null 2>&1; then
        content="$(python3 - <<'PY'
import json,sys,os
raw=sys.stdin.read()
try:
    data=json.loads(raw)
except Exception as e:
    # If parsing fails, emit original content unchanged
    print(raw,end="")
    sys.exit(0)
batch_json=os.environ.get("BATCH_OBJ","{}")
try:
    batch_obj=json.loads(batch_json)
except Exception:
    # Invalid batch object; keep original
    print(raw,end="")
    sys.exit(0)
if "batches" not in data or not isinstance(data["batches"], list):
    data["batches"]=[]
data["batches"].append(batch_obj)
print(json.dumps(data, sort_keys=True, indent=2, separators=(',',': ')))
PY
BATCH_OBJ="${batch_obj}" <<< "${content}")"
      else
        # Extremely conservative shell fallback: if empty batches array pattern found, replace it;
        # otherwise append just before final closing brace.
        if printf '%s' "${content}" | grep -q '"batches"[[:space:]]*:[[:space:]]*\[[[:space:]]*\]'; then
          content="$(printf '%s' "${content}" | sed "s/\"batches\"[[:space:]]*:[[:space:]]*\[[[:space:]]*\]/\"batches\": [\n  ${batch_obj}\n]/")"
        else
          # Append before the last ']' of batches array (fallback heuristic)
          content="$(printf '%s' "${content}" | awk -v ins="${batch_obj}" '
            BEGIN{added=0}
            /\"batches\"[^\[]*\[/ {inb=1}
            {
              if(inb && $0 ~ /\]/ && added==0){
                sub(/\]/,"  , " ins "\n]")
                added=1
              }
              print
            }')"
        fi
      fi
      printf '%s' "${content}" > "${ROOT}/${MANIFEST}.tmp"
      mv "${ROOT}/${MANIFEST}.tmp" "${ROOT}/${MANIFEST}"
      rm -f "${tmp_manifest}"
    fi
  fi
fi

# -----------------------
# Summary
# -----------------------
log "Batch ID: ${BATCH_ID}"
log "Archived: ${ARCHIVED}"
log "Skipped: ${SKIPPED}"
if (( ARCHIVED > 0 )); then
  log "Manifest: ${MANIFEST}"
fi

# Leave project root
popd >/dev/null 2>&1 || true

if (( SKIPPED > 0 && ARCHIVED == 0 )); then
  exit 2
elif (( SKIPPED > 0 )); then
  exit 2
fi

exit 0
