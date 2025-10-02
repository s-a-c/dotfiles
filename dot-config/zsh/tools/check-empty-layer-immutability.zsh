#!/usr/bin/env zsh
# check-empty-layer-immutability.zsh
#
# Purpose:
#   Verify immutability (no drift) of redesign skeleton "empty" layer directories:
#     .zshrc.pre-plugins.d.empty
#     .zshrc.add-plugins.d.empty
#     .zshrc.d.empty
#   against the manifest produced at: zsh/layers/immutable/manifest.json
#
# Manifest Schema (v1.0 excerpt):
# {
#   "directories": [
#     {
#       "name": ".zshrc.pre-plugins.d.empty",
#       "relative_path": ".zshrc.pre-plugins.d.empty",
#       "expected_file_count": 5,
#       "files": [
#          {"file": "010-shell-safety-nounset.zsh", "sha256": "..."},
#          ...
#       ]
#     },
#     ...
#   ]
# }
#
# Exit Codes:
#   0 = All checks passed (immutable)
#   1 = Drift detected (hash mismatch, missing / extra files, count mismatch)
#   2 = Usage error
#   3 = Manifest missing (and not allowed)
#   4 = Manifest parse error (malformed or unreadable)
#
# Options:
#   --manifest <path>            Override manifest path (default: layers/immutable/manifest.json relative to script root)
#   --json                       Emit machine‑parsable JSON summary to stdout
#   --quiet                      Suppress human readable report (JSON still emitted if --json)
#   --allow-missing-manifest     Do not treat absent manifest as fatal (exit 0 with status=manifest_missing)
#   --recompute-dir-hash         Include aggregate directory hash computations in output (not validated unless manifest adds them)
#   --help                       Show usage
#
# JSON Output (example):
# {
#   "status":"ok",
#   "manifest_path":".../manifest.json",
#   "directories":[
#     {"name":".zshrc.pre-plugins.d.empty","expected_count":5,"actual_count":5,"status":"ok",
#       "files":[{"file":"010-shell-safety-nounset.zsh","expected_sha256":"...","actual_sha256":"...","match":true}, ...],
#       "extra_files":[],"missing_files":[],"aggregate_sha256":"<computed-if-requested>"}
#   ],
#   "drift":false,
#   "errors":[]
# }
#
# Implementation Notes:
#   - Pure zsh (no jq) parsing via minimal grep/awk/sed; robust for stable manifest format.
#   - All helper functions namespaced under zf::*
#   - No mutation of manifest; read-only.
#   - Hash tool preference: shasum -a 256, fallback sha256sum.
#
# Governance:
#   - This checker is part of immutability enforcement; integrate into CI to fail on drift.
#   - If intentional updates occur, generate a NEW manifest file (append-only policy).
#

set -euo pipefail
setopt extendedglob null_glob

zf::usage() {
  cat <<'EOF'
Usage: check-empty-layer-immutability.zsh [options]

Options:
  --manifest <path>            Path to manifest.json (default: <repo-root>/layers/immutable/manifest.json)
  --json                       Emit JSON summary
  --quiet                      Suppress human summary
  --allow-missing-manifest     Treat missing manifest as non-fatal (status=manifest_missing)
  --recompute-dir-hash         Compute aggregate directory hash (sha256 of sorted "<sha256> <file>" lines)
  --help                       Show this help
EOF
}

# ---------- Argument Parsing ----------
MANIFEST_PATH=""
EMIT_JSON=0
QUIET=0
ALLOW_MISSING=0
RECOMPUTE_DIR_HASH=0

while (( $# > 0 )); do
  case "$1" in
    --manifest)
      shift || { echo "ERROR: --manifest requires path" >&2; exit 2; }
      MANIFEST_PATH=$1
      ;;
    --json) EMIT_JSON=1 ;;
    --quiet) QUIET=1 ;;
    --allow-missing-manifest) ALLOW_MISSING=1 ;;
    --recompute-dir-hash) RECOMPUTE_DIR_HASH=1 ;;
    --help|-h) zf::usage; exit 0 ;;
    *) echo "ERROR: Unknown argument: $1" >&2; zf::usage >&2; exit 2 ;;
  esac
  shift
done

# Resolve script directory (repo root assumption: script in zsh/tools/)
SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR%/tools}
: "${MANIFEST_PATH:=$ROOT_DIR/layers/immutable/manifest.json}"

# ---------- Utility ----------
zf::hash_tool() {
  if command -v shasum >/dev/null 2>&1; then
    echo "shasum -a 256"
  elif command -v sha256sum >/dev/null 2>&1; then
    echo "sha256sum"
  else
    echo "ERROR: No sha256 hash tool (shasum or sha256sum) available" >&2
    return 1
  fi
}

zf::compute_file_hash() {
  local file=$1
  local cmd; cmd=$(zf::hash_tool) || return 1
  # output only digest
  $=cmd "$file" | awk '{print $1}'
}

zf::json_escape() {
  # Escape for JSON string
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  print -r -- "$s"
}

# Parse manifest directories section into a neutral, easily iterated representation.
# We'll build arrays keyed by an index.
typeset -a DIR_NAMES DIR_PATHS DIR_EXPECT_COUNTS
typeset -A DIR_FILE_SHA_MAP  # key: "<dir_index>::<file>" => sha
MANIFEST_STATUS="loaded"
PARSE_ERROR=0

if [[ ! -f $MANIFEST_PATH ]]; then
  if (( ALLOW_MISSING )); then
    MANIFEST_STATUS="missing"
  else
    echo "ERROR: Manifest not found: $MANIFEST_PATH" >&2
    exit 3
  fi
fi

if [[ $MANIFEST_STATUS == "loaded" ]]; then
  # Lightweight structural parsing
  manifest_content=$(<"$MANIFEST_PATH") || { echo "ERROR: Unable to read manifest" >&2; exit 4; }

  # Quick validation
  if [[ $manifest_content != *'"directories"'* ]]; then
    echo "ERROR: Manifest missing 'directories' key" >&2
    exit 4
  fi

  # Split directories by '{' occurrences containing "relative_path"
  # We'll use awk to segment the directories array content.
  # Extract the directories JSON array block first (greedy but stable for known format).
  dirs_block=$(printf "%s" "$manifest_content" | sed -n '/"directories"[[:space:]]*:/,/]/p')
  if [[ -z $dirs_block ]]; then
    echo "ERROR: Failed to isolate directories block" >&2
    exit 4
  fi

  # Iterate directory objects
  # Each directory object expected to contain:
  #   "relative_path": "..."
  #   "expected_file_count": N
  #   "files": [ ... ]
  dir_index=0
  IFS=$'\n' read -rA raw_dir_objs <<<"$(printf "%s" "$dirs_block" | awk '
    BEGIN{RS="\\{"; FS="\n"}
    NR>1 {print "{"$0}
  ')"

  for raw in "${raw_dir_objs[@]}"; do
    # Keep only those with "relative_path"
    [[ $raw == *'"relative_path"'* ]] || continue
    rel_path=$(printf "%s" "$raw" | sed -n 's/.*"relative_path"[[:space:]]*:[[:space:]]*"\([^"]\+\)".*/\1/p' | head -n1)
    name=$(printf "%s" "$raw" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]\+\)".*/\1/p' | head -n1)
    exp_count=$(printf "%s" "$raw" | sed -n 's/.*"expected_file_count"[[:space:]]*:[[:space:]]*\([0-9]\+\).*/\1/p' | head -n1)

    if [[ -z $rel_path || -z $name || -z $exp_count ]]; then
      echo "WARN: Skipping malformed directory object (index tentative $dir_index)" >&2
      continue
    fi

    DIR_NAMES+="$name"
    DIR_PATHS+="$rel_path"
    DIR_EXPECT_COUNTS+="$exp_count"

    # Extract files array
    files_block=$(printf "%s" "$raw" | sed -n '/"files"[[:space:]]*:/,/]/p')
    # Each file entry has: "file": "..." and "sha256": "..."
    IFS=$'\n' read -rA file_entries <<<"$(printf "%s" "$files_block" | grep '"file"' || true)"
    for fe in "${file_entries[@]}"; do
      f_name=$(printf "%s" "$fe" | sed -n 's/.*"file"[[:space:]]*:[[:space:]]*"\([^"]\+\)".*/\1/p' | head -n1)
      f_sha=$(printf "%s" "$fe" | sed -n 's/.*"sha256"[[:space:]]*:[[:space:]]*"\([^"]\+\)".*/\1/p' | head -n1)
      if [[ -n $f_name && -n $f_sha ]]; then
        DIR_FILE_SHA_MAP["$dir_index::$f_name"]="$f_sha"
      fi
    done

    ((dir_index++))
  done
fi

# ---------- Validation ----------
total_dirs=${#DIR_NAMES[@]}
typeset -A DIR_RESULT_STATUS DIR_ACTUAL_COUNT
typeset -A DIR_MISSING_FILES DIR_EXTRA_FILES
typeset -A FILE_MATCH FILE_ACTUAL_SHA
typeset -A DIR_AGGREGATE_SHA

DRIFT=0
typeset -a GLOBAL_ERRORS

if [[ $MANIFEST_STATUS == "missing" ]]; then
  # Provide empty set result
  :
else
  for i in {1..$total_dirs}; do
    idx=$((i-1))
    # Nounset-safe retrieval of directory path & expected count (guard against sparse arrays when manifest parse skips malformed objects)
    dpath=${DIR_PATHS[$idx]:-}
    expected_count=${DIR_EXPECT_COUNTS[$idx]:-}
    if [[ -z "$dpath" || -z "$expected_count" ]]; then
      DIR_RESULT_STATUS[$idx]="missing_index"
      GLOBAL_ERRORS+="$idx:dir_index_missing"
      DRIFT=1
      continue
    fi
    abs_dir="$ROOT_DIR/$dpath"
    missing=()
    extra=()
    if [[ ! -d $abs_dir ]]; then
      GLOBAL_ERRORS+="$dpath:directory_missing"
      DIR_RESULT_STATUS[$idx]="missing"
      DRIFT=1
      continue
    fi

    # Collect expected files
    expected_files=()
    for k v in "${(@kv)DIR_FILE_SHA_MAP}"; do
      if [[ $k == "$idx::"* ]]; then
        expected_files+="${k#*::}"
      fi
    done

    # Actual files
    actual_files=(${abs_dir}/*.zsh(N:t))
    # Build lookup
    typeset -A seen
    for ef in "${expected_files[@]}"; do seen[$ef]=1; done

    # Detect missing
    for ef in "${expected_files[@]}"; do
      [[ -f $abs_dir/$ef ]] || missing+="$ef"
    done
    # Detect extra
    for af in "${actual_files[@]}"; do
      [[ -n ${seen[$af]:-} ]] || extra+="$af"
    done

    # Compare counts
    actual_count=${#actual_files[@]}
    DIR_ACTUAL_COUNT[$idx]=$actual_count

    # File hash checks
    dir_drift=0
    for ef in "${expected_files[@]}"; do
      exp_sha=${DIR_FILE_SHA_MAP["$idx::$ef"]}
      if [[ ! -f $abs_dir/$ef ]]; then
        FILE_MATCH["$idx::$ef"]=false
        continue
      fi
      actual_sha=$(zf::compute_file_hash "$abs_dir/$ef" 2>/dev/null || echo "ERROR")
      FILE_ACTUAL_SHA["$idx::$ef"]="$actual_sha"
      if [[ $actual_sha == "$exp_sha" ]]; then
        FILE_MATCH["$idx::$ef"]=true
      else
        FILE_MATCH["$idx::$ef"]=false
        dir_drift=1
      fi
    done

    # Count mismatch
    if (( actual_count != expected_count )); then
      dir_drift=1
    fi
    if (( ${#missing[@]} )); then
      dir_drift=1
    fi
    if (( ${#extra[@]} )); then
      dir_drift=1
    fi

    if (( RECOMPUTE_DIR_HASH )); then
      # Build aggregate list of "sha256 filename" for expected files (sorted by filename)
      aggregate_lines=()
      for ef in "${expected_files[@]}"; do
        act=${FILE_ACTUAL_SHA["$idx::$ef"]:-}
        # If file missing, mark placeholder
        if [[ -z $act ]]; then
          act="MISSING"
        fi
        aggregate_lines+="$act $ef"
      done
      if (( ${#aggregate_lines[@]} )); then
        # sort stable
        IFS=$'\n' sorted=($(printf "%s\n" "${aggregate_lines[@]}" | LC_ALL=C sort))
        tmp_join=$(printf "%s\n" "${sorted[@]}")
        agg_sha=$(printf "%s" "$tmp_join" | shasum -a 256 2>/dev/null | awk '{print $1}' || echo "UNAVAIL")
        DIR_AGGREGATE_SHA[$idx]="$agg_sha"
      else
        DIR_AGGREGATE_SHA[$idx]=""
      fi
    fi

    if (( dir_drift )); then
      DIR_RESULT_STATUS[$idx]="drift"
      DRIFT=1
    else
      DIR_RESULT_STATUS[$idx]="ok"
    fi

    # Serialize missing / extra (space-delimited for later JSON building)
    DIR_MISSING_FILES[$idx]="${(j: :)missing}"
    DIR_EXTRA_FILES[$idx]="${(j: :)extra}"
  done
fi

# ---------- Reporting (Human) ----------
if (( ! QUIET )); then
  if [[ $MANIFEST_STATUS == "missing" ]]; then
    echo "[immutability] Manifest missing: $MANIFEST_PATH"
    (( ALLOW_MISSING )) && echo "[immutability] Allowed missing manifest (no validation performed)."
  else
    echo "[immutability] Manifest: $MANIFEST_PATH"
    for i in {1..$total_dirs}; do
      idx=$((i-1))
      name=${DIR_NAMES[$idx]:-"(index:$idx missing name)"}
      status=${DIR_RESULT_STATUS[$idx]:-unprocessed}
      expc=${DIR_EXPECT_COUNTS[$idx]:-0}
      actc=${DIR_ACTUAL_COUNT[$idx]:-0}
      printf " - %-30s status=%s expected=%s actual=%s\n" "$name" "$status" "$expc" "$actc"
      # Detailed drift reasons
      if [[ $status == drift ]]; then
        # Missing
        if [[ -n ${DIR_MISSING_FILES[$idx]} ]]; then
          echo "    missing: ${DIR_MISSING_FILES[$idx]}"
        fi
        if [[ -n ${DIR_EXTRA_FILES[$idx]} ]]; then
          echo "    extra: ${DIR_EXTRA_FILES[$idx]}"
        fi
        # Hash mismatches
        for k v in "${(@kv)DIR_FILE_SHA_MAP}"; do
          [[ $k == "$idx::"* ]] || continue
          f=${k#*::}
          match=${FILE_MATCH["$idx::$f"]-}
          if [[ $match == false ]]; then
            echo "    hash_mismatch: $f expected=${DIR_FILE_SHA_MAP["$idx::$f"]} actual=${FILE_ACTUAL_SHA["$idx::$f"]-MISSING}"
          fi
        done
      fi
      if (( RECOMPUTE_DIR_HASH )) && [[ -n ${DIR_AGGREGATE_SHA[$idx]:-} ]]; then
        echo "    aggregate_sha256: ${DIR_AGGREGATE_SHA[$idx]}"
      fi
    done
  fi
  if (( DRIFT )); then
    echo "[immutability] RESULT: DRIFT DETECTED"
  else
    echo "[immutability] RESULT: OK"
  fi
fi

# ---------- JSON Output ----------
if (( EMIT_JSON )); then
  json_status="ok"
  if (( DRIFT )); then json_status="drift"; fi
  if [[ $MANIFEST_STATUS == "missing" ]]; then json_status="manifest_missing"; fi

  json_dirs=()
  for i in {1..$total_dirs}; do
    idx=$((i-1))
    name=${DIR_NAMES[$idx]:-"(index:$idx missing name)"}
    expc=${DIR_EXPECT_COUNTS[$idx]:-0}
    actc=${DIR_ACTUAL_COUNT[$idx]:-0}
    status=${DIR_RESULT_STATUS[$idx]:-unprocessed}

    # Build files array JSON
    file_items=()
    for k v in "${(@kv)DIR_FILE_SHA_MAP}"; do
      [[ $k == "$idx::"* ]] || continue
      f=${k#*::}
      exp_sha=$v
      act_sha=${FILE_ACTUAL_SHA["$idx::$f"]-}
      match=${FILE_MATCH["$idx::$f"]-false}
      file_items+="{\"file\":\"$(zf::json_escape "$f")\",\"expected_sha256\":\"$exp_sha\",\"actual_sha256\":\"$(zf::json_escape "$act_sha")\",\"match\":$([[ $match == true ]] && echo true || echo false)}"
    done
    files_json="[${(j:,:)file_items}]"

    # Missing & extra arrays
    missing_json="[]"
    extra_json="[]"
    if [[ -n ${DIR_MISSING_FILES[$idx]} ]]; then
      arr=(${=DIR_MISSING_FILES[$idx]})
      tmp=()
      for mf in "${arr[@]}"; do tmp+="\"$(zf::json_escape "$mf")\""; done
      missing_json="[${(j:,:)tmp}]"
    fi
    if [[ -n ${DIR_EXTRA_FILES[$idx]} ]]; then
      arr=(${=DIR_EXTRA_FILES[$idx]})
      tmp=()
      for ef in "${arr[@]}"; do tmp+="\"$(zf::json_escape "$ef")\""; done
      extra_json="[${(j:,:)tmp}]"
    fi

    agg=""
    if (( RECOMPUTE_DIR_HASH )) && [[ -n ${DIR_AGGREGATE_SHA[$idx]:-} ]]; then
      agg=",\"aggregate_sha256\":\"${DIR_AGGREGATE_SHA[$idx]}\""
    fi

    json_dirs+="{\"name\":\"$(zf::json_escape "$name")\",\"expected_count\":$expc,\"actual_count\":$actc,\"status\":\"$status\",\"files\":$files_json,\"missing_files\":$missing_json,\"extra_files\":$extra_json$agg}"
  done

  errors_json="[]"
  if (( ${#GLOBAL_ERRORS[@]} )); then
    tmp=()
    for e in "${GLOBAL_ERRORS[@]}"; do tmp+="\"$(zf::json_escape "$e")\""; done
    errors_json="[${(j:,:)tmp}]"
  fi

  printf '{'
  printf '"status":"%s",' "$json_status"
  printf '"manifest_path":"%s",' "$(zf::json_escape "$MANIFEST_PATH")"
  printf '"manifest_state":"%s",' "$MANIFEST_STATUS"
  printf '"directories":[%s],' "${(j:,:)json_dirs}"
  printf '"drift":%s,' $(( DRIFT ? 1 : 0 ))
  printf '"errors":%s' "$errors_json"
  printf '}\n'
fi

# ---------- Exit ----------
if [[ $MANIFEST_STATUS == "missing" && $ALLOW_MISSING -eq 1 ]]; then
  exit 0
fi

if (( DRIFT )); then
  exit 1
fi
exit 0
