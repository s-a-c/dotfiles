#!/usr/bin/env zsh
# regenerate-empty-layer-manifest.zsh
#
# Purpose:
#   Regenerate an immutable manifest JSON describing the redesign "empty" layer
#   directory skeletons (.zshrc.*.d.empty) with per-file sha256 digests for
#   drift / tamper detection.
#
# Features:
#   - Pure zsh (no jq dependency)
#   - Stable JSON schema (compatible with existing checker)
#   - Append-only governance model (default: create a NEW timestamped file)
#   - Optional overwrite (governance breach unless explicitly justified)
#   - Optional pretty-print formatting
#   - Optional directory aggregate hash (sha256 of sorted "<sha256> <file>" lines)
#
# Directories Covered (hard-coded for safety):
#   .zshrc.pre-plugins.d.empty
#   .zshrc.add-plugins.d.empty
#   .zshrc.d.empty
#
# Output Schema (v1.0):
# {
#   "schema_version": "1.0",
#   "purpose": "...",
#   "generated_at": "ISO8601",
#   "hash_algorithm": "sha256",
#   "aggregation_policy": "...",
#   "directories": [
#     {
#       "name": ".zshrc.pre-plugins.d.empty",
#       "relative_path": ".zshrc.pre-plugins.d.empty",
#       "expected_file_count": 5,
#       "files": [
#         {"file":"010-shell-safety-nounset.zsh","sha256":"..."},
#         ...
#       ],
#       "aggregate_sha256": "..."   # (optional, only if --aggregate)
#     },
#     ...
#   ],
#   "governance": {
#     "immutability": "...",
#     "verification_recommendation": "...",
#     "previous_manifest": "layers/immutable/manifest.json"   # (if previous exists)
#   }
# }
#
# Usage:
#   regenerate-empty-layer-manifest.zsh
#   regenerate-empty-layer-manifest.zsh --output layers/immutable/manifest-<date>.json
#   regenerate-empty-layer-manifest.zsh --in-place        (OVERWRITE existing canonical manifest.json)
#   regenerate-empty-layer-manifest.zsh --aggregate       (add per-directory aggregate hashes)
#   regenerate-empty-layer-manifest.zsh --pretty
#   regenerate-empty-layer-manifest.zsh --force-overwrite --output layers/immutable/manifest.json
#
# Exit Codes:
#   0 success
#   1 validation / IO error
#   2 usage error
#
# Governance Notes:
#   - Preferred mode: create a NEW dated manifest file (append-only) then (optionally)
#     manually update a symlink (e.g., manifest.json -> manifest-<timestamp>.json).
#   - Overwriting the canonical manifest is discouraged; requires explicit
#     --force-overwrite AND either --in-place or explicit --output path.
#
# ------------------------------------------------------------------------------

set -euo pipefail
setopt extendedglob null_glob

# -------------------------------
# Defaults / Configuration
# -------------------------------
ZF_SCHEMA_VERSION="1.0"
ZF_HASH_ALGO="sha256"
ZF_AGGREGATION_POLICY="Per-file sha256 recorded; directory aggregate optional. Existing manifests treated as append-only snapshots."
ZF_CANONICAL_MANIFEST_REL="layers/immutable/manifest.json"
ZF_EMPTY_DIRS=( ".zshrc.pre-plugins.d.empty" ".zshrc.add-plugins.d.empty" ".zshrc.d.empty" )

# -------------------------------
# CLI Flags
# -------------------------------
OUTPUT_PATH=""
IN_PLACE=0
PRETTY=0
AGGREGATE=0
FORCE_OVERWRITE=0
EMBED_DIR_HASH=0

zf::usage() {
  cat <<'EOF'
regenerate-empty-layer-manifest.zsh [options]

Options:
  --output <path>        Write manifest to specified path (recommended: layers/immutable/manifest-YYYYmmddTHHMMSSZ.json)
  --in-place             Overwrite canonical layers/immutable/manifest.json (governance breach unless justified)
  --pretty               Pretty-print JSON (multi-line, indented)
  --aggregate            Include per-directory aggregate sha256 (sorted "<sha256> <file>" lines)
  --embed-dir-hash       Also embed canonical directory aggregate as "dir_hash" (implies aggregate computation)
  --force-overwrite      Allow overwrite of existing file (otherwise abort if target exists)
  --schema-version <v>   Override schema_version (default: 1.0)
  --help                 Show this help

Examples:
  # Safe new snapshot:
  regenerate-empty-layer-manifest.zsh --output layers/immutable/manifest-$(date -u +%Y%m%dT%H%M%SZ).json

  # Overwrite canonical (discouraged):
  regenerate-empty-layer-manifest.zsh --in-place --force-overwrite

Governance:
  Prefer creating a new timestamped file and updating a symlink manually.
  Overwriting canonical manifest requires justification (commit message).
EOF
}

# -------------------------------
# Argument Parsing
# -------------------------------
while (( $# > 0 )); do
  case "$1" in
    --output)
      shift || { echo "ERROR: --output requires a path" >&2; exit 2; }
      OUTPUT_PATH="$1"
      ;;
    --in-place)
      IN_PLACE=1
      ;;
    --pretty)
      PRETTY=1
      ;;
    --aggregate)
      AGGREGATE=1
      ;;
    --embed-dir-hash)
      EMBED_DIR_HASH=1
      ;;
    --force-overwrite)
      FORCE_OVERWRITE=1
      ;;
    --schema-version)
      shift || { echo "ERROR: --schema-version requires value" >&2; exit 2; }
      ZF_SCHEMA_VERSION="$1"
      ;;
    --help|-h)
      zf::usage; exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      zf::usage >&2
      exit 2
      ;;
  esac
  shift
done

# -------------------------------
# Resolve Paths
# -------------------------------
SCRIPT_DIR=${0:A:h}
REPO_ROOT=$SCRIPT_DIR:h
CANONICAL_PATH="$REPO_ROOT/$ZF_CANONICAL_MANIFEST_REL"

if (( IN_PLACE )); then
  OUTPUT_PATH="$ZF_CANONICAL_MANIFEST_REL"
fi

if [[ -z "$OUTPUT_PATH" ]]; then
  # Default: timestamped new snapshot beside canonical path
  ts=$(date -u +%Y%m%dT%H%M%SZ)
  OUTPUT_PATH="layers/immutable/manifest-${ts}.json"
fi

ABS_OUTPUT_PATH="$REPO_ROOT/$OUTPUT_PATH"
OUTPUT_DIR="${ABS_OUTPUT_PATH:h}"

# -------------------------------
# Validation
# -------------------------------
if [[ ! -d "$OUTPUT_DIR" ]]; then
  mkdir -p "$OUTPUT_DIR" || { echo "ERROR: Cannot create output directory: $OUTPUT_DIR" >&2; exit 1; }
fi

if [[ -e "$ABS_OUTPUT_PATH" && $FORCE_OVERWRITE -eq 0 ]]; then
  echo "ERROR: Output file exists: $ABS_OUTPUT_PATH (use --force-overwrite to replace)" >&2
  exit 1
fi

if (( IN_PLACE )) && [[ "$ABS_OUTPUT_PATH" != "$CANONICAL_PATH" ]]; then
  echo "ERROR: --in-place mismatch (internal invariant failed)" >&2
  exit 1
fi

if (( IN_PLACE )) && (( FORCE_OVERWRITE == 0 )); then
  echo "ERROR: --in-place requires --force-overwrite (governance safeguard)" >&2
  exit 1
fi

# -------------------------------
# Hash Tool Detection
# -------------------------------
zf::hash_cmd() {
  if command -v shasum >/dev/null 2>&1; then
    echo "shasum -a 256"
  elif command -v sha256sum >/dev/null 2>&1; then
    echo "sha256sum"
  else
    echo "ERROR: No sha256 hash tool available (need shasum or sha256sum)" >&2
    return 1
  fi
}

HASH_CMD=$(zf::hash_cmd) || exit 1

zf::file_hash() {
  local f=$1
  $=HASH_CMD "$f" | awk '{print $1}'
}

# -------------------------------
# Gather Data
# -------------------------------
typeset -a JSON_DIR_OBJECTS
PREVIOUS_MANIFEST=""
if [[ -f "$CANONICAL_PATH" ]]; then
  PREVIOUS_MANIFEST="$ZF_CANONICAL_MANIFEST_REL"
fi

for d in "${ZF_EMPTY_DIRS[@]}"; do
  abs_dir="$REPO_ROOT/$d"
  if [[ ! -d "$abs_dir" ]]; then
    echo "ERROR: Expected directory missing: $d" >&2
    exit 1
  fi

  files=(${abs_dir}/*.zsh(N))
  # Build file entries
  typeset -a file_entries
  file_entries=()
  for f in "${files[@]}"; do
    base=${f:t}
    digest=$(zf::file_hash "$f")
    file_entries+="{\"file\":\"$base\",\"sha256\":\"$digest\"}"
  done

  # Compute optional aggregate hash (needed if either aggregate or embed-dir-hash requested)
  dir_aggregate=""
  if (( AGGREGATE || EMBED_DIR_HASH )); then
    lines=()
    for f in "${files[@]}"; do
      base=${f:t}
      digest=$(zf::file_hash "$f")
      lines+="$digest $base"
    done
    IFS=$'\n' sorted=($(printf "%s\n" "${lines[@]}" | LC_ALL=C sort))
    aggregate_input=$(printf "%s\n" "${sorted[@]}")
    dir_aggregate=$($=HASH_CMD <<<"$aggregate_input" | awk '{print $1}')
  fi

  entry="{\"name\":\"$d\",\"relative_path\":\"$d\",\"expected_file_count\":${#files[@]},\"files\":[${(j:,:)file_entries}]"
  if (( AGGREGATE )); then
    entry+=",\"aggregate_sha256\":\"$dir_aggregate\""
  fi
  if (( EMBED_DIR_HASH )); then
    entry+=",\"dir_hash\":\"$dir_aggregate\""
  fi
  entry+="}"
  JSON_DIR_OBJECTS+="$entry"
done

GENERATED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# -------------------------------
# JSON Assembly
# -------------------------------
json_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  printf '%s' "$s"
}

purpose="Immutable manifest of redesign layer skeleton (.zshrc.*.d.empty) file hashes for drift & tamper detection."
immutability="This file is append-only; modifications to existing entries require a new manifest file unless formally justified."
verification="Run: for d in .zshrc.*.d.empty; do shasum -a 256 $d/*.zsh; done | compare to manifest."
next_steps=( \
  "Integrate CI drift check (fail on mismatch)" \
  "Maintain append-only chain of manifest-<timestamp>.json files" \
  "Optionally maintain a symlink manifest.json -> latest snapshot" \
  "Include aggregate directory hashes for rapid diff triage" \
)

# Build next_steps JSON array
typeset -a steps_json
for s in "${next_steps[@]}"; do
  steps_json+="\"$(json_escape "$s")\""
done

governance="{\"immutability\":\"$(json_escape "$immutability")\",\"verification_recommendation\":\"$(json_escape "$verification")\""
if [[ -n "$PREVIOUS_MANIFEST" && "$OUTPUT_PATH" != "$ZF_CANONICAL_MANIFEST_REL" ]]; then
  governance+=",\"previous_manifest\":\"$(json_escape "$PREVIOUS_MANIFEST")\""
fi
governance+=",\"next_steps\":[${(j:,:)steps_json}]}"

# Root JSON object
ROOT_JSON="{\"schema_version\":\"$ZF_SCHEMA_VERSION\",\"purpose\":\"$(json_escape "$purpose")\",\"generated_at\":\"$GENERATED_AT\",\"hash_algorithm\":\"$ZF_HASH_ALGO\",\"aggregation_policy\":\"$(json_escape "$ZF_AGGREGATION_POLICY")\",\"directories\":[${(j:,:)JSON_DIR_OBJECTS}],\"governance\":$governance}"

# Pretty print if requested
if (( PRETTY )); then
  if command -v python3 >/dev/null 2>&1; then
    ROOT_JSON=$(python3 - <<'PY' 2>/dev/null || echo "{}"
import json,sys
try:
    data=json.loads(sys.stdin.read())
    print(json.dumps(data, indent=2, sort_keys=False))
except Exception as e:
    sys.stderr.write(f"Pretty print failed: {e}\n")
    sys.stdout.write("{}")
PY
<<< "$ROOT_JSON")
  else
    echo "WARN: python3 not available; pretty printing skipped" >&2
  fi
fi

# -------------------------------
# Write Output
# -------------------------------
printf '%s\n' "$ROOT_JSON" > "$ABS_OUTPUT_PATH"

# -------------------------------
# Post Summary
# -------------------------------
echo "[manifest] Wrote: $OUTPUT_PATH"
echo "[manifest] Generated at: $GENERATED_AT"
echo "[manifest] Directories: ${#ZF_EMPTY_DIRS[@]}"
for d in "${ZF_EMPTY_DIRS[@]}"; do
  count=$(ls -1 "$REPO_ROOT/$d"/*.zsh 2>/dev/null | wc -l | tr -d ' ')
  echo " - $d ($count files)"
done
if (( AGGREGATE )); then
  echo "[manifest] Included directory aggregate hashes"
fi
if (( IN_PLACE )); then
  echo "[manifest] WARNING: In-place overwrite performed (governance exception)!"
fi
if (( FORCE_OVERWRITE == 0 )) && [[ -e "$ABS_OUTPUT_PATH" ]]; then
  : # normal path already handled
fi

echo "[manifest] Done."

exit 0
