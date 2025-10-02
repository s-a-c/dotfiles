#!/usr/bin/env bash
# segment-canonicalize.sh
# Phase 7 (Optional Enhancements) – Integrity & Instrumentation Support
#
# Purpose:
#   Canonicalize segment instrumentation output (JSON, NDJSON) into a
#   deterministic, stable representation and emit a SHA256 digest plus
#   a manifest for tamper-evident tracking.
#
# Scope:
#   Designed for fix-zle instrumentation artifacts (segment capture /
#   future aggregate snapshots) but generic enough for other JSON logs.
#
# Features:
#   * Accepts plain JSON object or JSON array input.
#   * Accepts NDJSON line streams (one JSON object per line) via --ndjson.
#   * Produces a canonical pretty JSON (sorted keys, stable formatting).
#   * Emits sha256:<hex> digest file and JSON manifest (machine readable).
#   * Optional compression (gzip) of canonical form with --gzip.
#   * Optional stdin streaming (use "-" as file).
#   * Strict failure codes (no silent degradation).
#
# Usage:
#   segment-canonicalize.sh path/to/file.json
#   segment-canonicalize.sh path/to/file.ndjson --ndjson
#   segment-canonicalize.sh - --ndjson < live.ndjson
#   segment-canonicalize.sh segments.json --output out/canon.json
#   segment-canonicalize.sh segments.ndjson --ndjson --gzip
#
# Outputs (default naming, relative to input path or --output):
#   <input>.canonical.json
#   <input>.canonical.json.gz          (when --gzip)
#   <input>.sha256                     (text: sha256:<hex>)
#   <input>.integrity.json             (manifest)
#
# Exit Codes:
#   0 success
#   1 usage / argument error
#   2 missing dependency (python3 or hash tool)
#   3 parse / canonicalization failure
#   4 write / filesystem failure
#
# Dependencies:
#   * python3 (required)
#   * sha256sum OR shasum (one required)
#   * gzip (optional; only if --gzip used)
#
# Nounset / Safety:
#   Uses `set -euo pipefail`; guard all parameter expansions.
#
# Policy Alignment:
#   * No silent error suppression.
#   * Minimal, auditable diff (single standalone tool).
#   * Nounset-safe expansions.
#
# -----------------------------------------------------------------------------
set -euo pipefail

SCRIPT_NAME="segment-canonicalize.sh"

usage() {
  cat <<'EOF'
Usage: segment-canonicalize.sh <file|-> [options]

Options:
  --ndjson             Treat input as NDJSON (one JSON object per line)
  --output <path>      Override canonical output path (implies base name)
  --manifest-only      Only (re)generate manifest + digest from existing canonical JSON
  --gzip               Gzip the canonical JSON (produces .gz alongside)
  --force              Overwrite existing canonical artifacts
  --stdin              Alias for specifying "-" as input (explicitness)
  --quiet              Suppress non-error informational output
  --help               Show this help

Notes:
  * Use "-" as <file> to read from stdin. When using stdin you MUST
    supply --output <path> (base path used for derived files).
  * For NDJSON, each non-empty line must be a valid JSON object.
  * The manifest JSON is stable (sorted keys, pretty) and includes:
      {
        "source": "<absolute input ref or 'stdin'>",
        "canonical_file": "<absolute canonical json path>",
        "gzip": true|false,
        "sha256": "sha256:<digest>",
        "line_count": <n or null>,
        "ndjson": true|false,
        "timestamp": "RFC3339",
        "tool": "segment-canonicalize.sh",
        "version": 1
      }
  * Re-running without --force will refuse to clobber existing outputs.

Exit Codes:
  0 success
  1 usage / argument error
  2 missing dependency
  3 parse failure
  4 write failure
EOF
}

# --------------------------
# Argument Parsing
# --------------------------
INPUT=""
NDJSON=0
OUTPUT_OVERRIDE=""
MANIFEST_ONLY=0
DO_GZIP=0
FORCE=0
QUIET=0

while (($#)); do
  case "$1" in
    --ndjson) NDJSON=1 ;;
    --output)
      shift || { echo "ERROR: --output requires path" >&2; exit 1; }
      OUTPUT_OVERRIDE="$1"
      ;;
    --manifest-only) MANIFEST_ONLY=1 ;;
    --gzip) DO_GZIP=1 ;;
    --force) FORCE=1 ;;
    --stdin) INPUT="-" ;;
    -) INPUT="-" ;;
    --quiet) QUIET=1 ;;
    --help|-h) usage; exit 0 ;;
    --) shift; break ;;
    -*)
      echo "ERROR: Unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [[ -z "${INPUT}" ]]; then
        INPUT="$1"
      else
        echo "ERROR: Multiple input files specified (first: ${INPUT}, extra: $1)" >&2
        exit 1
      fi
      ;;
  esac
  shift
done

if [[ -z "${INPUT}" ]]; then
  echo "ERROR: No input file (or -) specified" >&2
  usage
  exit 1
fi

if [[ "${INPUT}" == "-" && -z "${OUTPUT_OVERRIDE}" ]]; then
  echo "ERROR: --output is required when reading from stdin" >&2
  exit 1
fi

# --------------------------
# Dependency Checks
# --------------------------
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found" >&2; exit 2; }

# Hash tool detection
HAVE_SHA256SUM=0
if command -v sha256sum >/dev/null 2>&1; then
  HAVE_SHA256SUM=1
elif ! command -v shasum >/dev/null 2>&1; then
  echo "ERROR: Neither sha256sum nor shasum found" >&2
  exit 2
fi

if (( DO_GZIP == 1 )) && ! command -v gzip >/dev/null 2>&1; then
  echo "ERROR: gzip not found but --gzip requested" >&2
  exit 2
fi

# --------------------------
# Path Resolution
# --------------------------
# Derive base path for output naming
if [[ -n "${OUTPUT_OVERRIDE}" ]]; then
  # If override ends with .json treat as canonical target; else use as base path
  if [[ "${OUTPUT_OVERRIDE}" == *.json ]]; then
    CANONICAL_PATH="${OUTPUT_OVERRIDE}"
    BASE="${OUTPUT_OVERRIDE%.json}"
  else
    CANONICAL_PATH="${OUTPUT_OVERRIDE%.canonical}.canonical.json"
    BASE="${OUTPUT_OVERRIDE%.canonical}"
  fi
else
  if [[ "${INPUT}" == "-" ]]; then
    echo "ERROR: logic error: stdin without override should have exited" >&2
    exit 1
  fi
  CANONICAL_PATH="${INPUT}.canonical.json"
  BASE="${INPUT}.canonical"
fi

DIGEST_PATH="${BASE}.sha256"
MANIFEST_PATH="${BASE}.integrity.json"
GZIP_PATH="${CANONICAL_PATH}.gz"

# Guard existing outputs unless --force
for f in "${CANONICAL_PATH}" "${DIGEST_PATH}" "${MANIFEST_PATH}" "${GZIP_PATH}"; do
  if [[ -f "$f" && $FORCE -ne 1 && $MANIFEST_ONLY -ne 1 ]]; then
    echo "ERROR: Output file exists: $f (use --force to overwrite)" >&2
    exit 1
  fi
done

# --------------------------
# Read / Canonicalize
# --------------------------
tmp_in="$(mktemp)"
trap 'rm -f "$tmp_in"' EXIT

if [[ "${INPUT}" == "-" ]]; then
  cat > "${tmp_in}" || { echo "ERROR: Failed to read stdin" >&2; exit 3; }
else
  [[ -f "${INPUT}" ]] || { echo "ERROR: Input file not found: ${INPUT}" >&2; exit 1; }
  cp "${INPUT}" "${tmp_in}" || { echo "ERROR: Unable to copy input" >&2; exit 4; }
fi

LINE_COUNT=null
if (( NDJSON == 1 )); then
  # Count non-empty lines prior to parse
  LINE_COUNT=$(grep -cve '^[[:space:]]*$' "${tmp_in}" || echo 0)
fi

if (( MANIFEST_ONLY == 0 )); then
  # Perform canonicalization via python3
  # We allocate to a temp file first for atomicity
  tmp_out="$(mktemp)"
  trap 'rm -f "$tmp_in" "$tmp_out"' EXIT
  if (( NDJSON == 1 )); then
    if ! python3 - "${tmp_in}" > "${tmp_out}" <<'PY'; then
import json,sys
src=sys.argv[1]
objs=[]
with open(src,'r',encoding='utf-8') as f:
    for i,line in enumerate(f,1):
        line=line.strip()
        if not line:
            continue
        try:
            obj=json.loads(line)
        except Exception as e:
            sys.stderr.write(f"NDJSON parse error line {i}: {e}\n")
            sys.exit(3)
        objs.append(obj)
print(json.dumps(objs, sort_keys=True, indent=2, separators=(',',': ')))
PY
    then
      exit 3
    fi
  else
    if ! python3 - "${tmp_in}" > "${tmp_out}" <<'PY'; then
import json,sys
src=sys.argv[1]
try:
    with open(src,'r',encoding='utf-8') as f:
        data=json.load(f)
except Exception as e:
    sys.stderr.write(f"JSON parse error: {e}\n")
    sys.exit(3)
print(json.dumps(data, sort_keys=True, indent=2, separators=(',',': ')))
PY
    then
      exit 3
    fi
  fi
  # Move into place
  if ! mv "${tmp_out}" "${CANONICAL_PATH}"; then
    echo "ERROR: Unable to write canonical output" >&2
    exit 4
  fi
fi

# --------------------------
# Digest
# --------------------------
if [[ -f "${CANONICAL_PATH}" ]]; then
  if (( HAVE_SHA256SUM == 1 )); then
    DIGEST=$(sha256sum "${CANONICAL_PATH}" | awk '{print $1}')
  else
    DIGEST=$(shasum -a 256 "${CANONICAL_PATH}" | awk '{print $1}')
  fi
else
  echo "ERROR: Canonical file missing (internal error)" >&2
  exit 4
fi

echo "sha256:${DIGEST}" > "${DIGEST_PATH}" || { echo "ERROR: Writing digest failed" >&2; exit 4; }

# --------------------------
# Optional Gzip
# --------------------------
if (( DO_GZIP == 1 )); then
  cp "${CANONICAL_PATH}" "${GZIP_PATH%.gz}" || { echo "ERROR: gzip staging copy failed" >&2; exit 4; }
  gzip -f "${GZIP_PATH%.gz}" || { echo "ERROR: gzip compression failed" >&2; exit 4; }
fi

# --------------------------
# Manifest
# --------------------------
# timestamp via python for portability & RFC3339 Z
MANIFEST_TS=$(python3 - <<'PY'
import datetime,sys
print(datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z")
PY
)

# Build manifest JSON (sorted keys)
python3 - > "${MANIFEST_PATH}" <<PY
import json,os,sys
manifest = {
  "canonical_file": os.path.abspath("${CANONICAL_PATH}"),
  "gzip": bool(${DO_GZIP}),
  "line_count": ${LINE_COUNT},
  "ndjson": bool(${NDJSON}),
  "sha256": "sha256:${DIGEST}",
  "source": "${INPUT if INPUT != '-' else 'stdin'}",
  "timestamp": "${MANIFEST_TS}",
  "tool": "${SCRIPT_NAME}",
  "version": 1
}
print(json.dumps(manifest, sort_keys=True, indent=2, separators=(',',': ')))
PY

if (( QUIET == 0 )); then
  echo "[segment-canonicalize] canonical: ${CANONICAL_PATH}"
  echo "[segment-canonicalize] digest: sha256:${DIGEST}"
  echo "[segment-canonicalize] manifest: ${MANIFEST_PATH}"
  (( DO_GZIP )) && echo "[segment-canonicalize] gzip: ${GZIP_PATH}"
fi

exit 0
