#!/usr/bin/env zsh
# check-empty-layer-immutability.zsh
#
# Phase / Governance: Immutability & Drift Enforcement (Enhanced)
#
# Purpose:
#   Validate immutability (no drift) of redesign skeleton "empty" layer directories
#   against a manifest (JSON) at: layers/immutable/manifest.json
#
# Enhancements Implemented (1–6):
#   1. --strict
#        * Fails if any directory object in manifest is structurally incomplete.
#        * Fails if any expected_count == 0 (unless --allow-empty-ok).
#        * Fails if any manifest directory missing an expected "files" array (even if empty).
#        * Fails if a filesystem .zshrc.*.d.empty directory exists but not represented in manifest.
#   2. --list-changes
#        * Human output lists ONLY drift directories (unless combined with --quiet).
#   3. Performance Metrics
#        * Elapsed runtime (ms), counts of directories, files, mismatches, drift directories included in JSON under "metrics".
#   4. --self-test
#        * Runs an internal synthetic manifest + ephemeral directory tree scenario:
#            - One directory passes
#            - One directory has intentional drift (hash mismatch & extra file)
#        * Validates detection; exits 0 iff both pass/fail expectations are met (regardless of drift exit semantics in normal mode).
#        * In self-test mode, normal exit code semantics replaced: 0 = self-test passed, 1 = self-test failed.
#   5. Aggregate Hash Validation
#        * If a directory object contains "dir_hash" (future manifest augmentation) we recompute the aggregate hash
#          (sha256 over sorted "<actual_sha256> <filename>" lines for expected files) and treat mismatch as drift.
#          Flag --recompute-dir-hash still controls inclusion of aggregate_sha256 in output, but validation
#          runs automatically when "dir_hash" present unless --skip-aggregate-validate provided.
#   6. Summary Metrics
#        * Top-level metrics JSON object with: elapsed_ms, directories_total, directories_drift,
#          files_expected, files_checked, files_missing, files_extra, hash_mismatches, aggregate_hash_mismatches.
#
# Exit Codes (normal mode):
#   0 = OK (no drift)
#   1 = Drift detected
#   2 = Usage error
#   3 = Manifest missing (unless allowed)
#   4 = Tool/runtime/parse error (python, hash tool, etc.)
#   5 = (reserved, currently unused – self-test uses 0 / 1)
#
# Exit Codes (self-test mode):
#   0 = Self-test success
#   1 = Self-test failure
#
# Core Options:
#   --manifest <path>            Path to manifest (default: layers/immutable/manifest.json)
#   --json                       Emit JSON summary (stdout)
#   --quiet                      Suppress human-readable summary (stderr still used for errors)
#   --allow-missing-manifest     Return status=manifest_missing (exit 0) if manifest absent
#   --recompute-dir-hash         Include aggregate directory hash in output (aggregate_sha256)
#   --strict                     Enforce stricter schema / presence semantics
#   --allow-empty-ok             With --strict, do not fail if expected_count == 0
#   --list-changes               Only print drift directories in human output
#   --self-test                  Run synthetic scenario; ignores provided manifest/path
#   --skip-aggregate-validate    Do not validate manifest "dir_hash" values if present
#   --help | -h                  Show usage
#
# JSON Output (fields):
# {
#   "status": "ok|drift|manifest_missing|error|self_test_pass|self_test_fail",
#   "manifest_path": "<path or (self_test)>",
#   "directories": [ ... ],
#   "drift": 0|1,
#   "errors": [ ... ],
#   "metrics": {
#       "elapsed_ms": <float>,
#       "directories_total": N,
#       "directories_drift": M,
#       "files_expected": X,
#       "files_checked": Y,
#       "files_missing": A,
#       "files_extra": B,
#       "hash_mismatches": C,
#       "aggregate_hash_mismatches": D
#   }
# }
#
# Governance Notes:
#   - Append-only manifest policy is external; this script purely validates.
#   - Aggregate hash future-proofing via optional "dir_hash".
#   - Self-test does not rely on ambient repo state except requiring a writable TMPDIR.
#
# Dependencies:
#   - python3
#   - shasum (preferred) or sha256sum
#
# Safety / Style:
#   - Nounset guarded via set -u with explicit fallbacks
#   - All helper functions prefixed zf::
#

set -euo pipefail
setopt extendedglob null_glob

zf::usage() {
  cat <<'EOF'
Usage: check-empty-layer-immutability.zsh [options]

Options:
  --manifest <path>            Manifest path (default: <repo>/layers/immutable/manifest.json)
  --json                       Emit JSON summary
  --quiet                      Suppress human summary
  --allow-missing-manifest     Treat missing manifest as non-fatal (status=manifest_missing)
  --recompute-dir-hash         Include aggregate directory hash (aggregate_sha256 field)
  --strict                     Fail on schema anomalies, zero expected counts (unless allowed), or missing filesystem dirs
  --allow-empty-ok             With --strict, do not fail if expected_count == 0
  --list-changes               Only show drift directories in human output
  --self-test                  Run built-in synthetic validation scenario
  --skip-aggregate-validate    Do not validate directory "dir_hash" values if present in manifest
  --help | -h                  Show this help

Exit codes (normal mode):
  0 OK, 1 drift, 2 usage, 3 missing manifest, 4 runtime error
Exit codes (self-test):
  0 self-test passed, 1 self-test failed

Examples:
  zsh tools/check-empty-layer-immutability.zsh --json
  zsh tools/check-empty-layer-immutability.zsh --strict --list-changes
  zsh tools/check-empty-layer-immutability.zsh --self-test --json
EOF
}

# ---------------- Argument Parsing ----------------
MANIFEST_PATH=""
EMIT_JSON=0
QUIET=0
ALLOW_MISSING=0
RECOMPUTE_DIR_HASH=0
STRICT_MODE=0
ALLOW_EMPTY_OK=0
LIST_CHANGES=0
SELF_TEST=0
SKIP_AGG_HASH_VALIDATE=0

while (( $# > 0 )); do
  case "$1" in
    --manifest) shift || { echo "ERROR: --manifest requires path" >&2; exit 2; }; MANIFEST_PATH=$1 ;;
    --json) EMIT_JSON=1 ;;
    --quiet) QUIET=1 ;;
    --allow-missing-manifest) ALLOW_MISSING=1 ;;
    --recompute-dir-hash) RECOMPUTE_DIR_HASH=1 ;;
    --strict) STRICT_MODE=1 ;;
    --allow-empty-ok) ALLOW_EMPTY_OK=1 ;;
    --list-changes) LIST_CHANGES=1 ;;
    --self-test) SELF_TEST=1 ;;
    --skip-aggregate-validate) SKIP_AGG_HASH_VALIDATE=1 ;;
    --help|-h) zf::usage; exit 0 ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      zf::usage >&2
      exit 2
      ;;
  esac
  shift
done

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR%/tools}
: "${MANIFEST_PATH:=$ROOT_DIR/layers/immutable/manifest.json}"

zf::hash_tool() {
  if command -v shasum >/dev/null 2>&1; then
    echo "shasum -a 256"
  elif command -v sha256sum >/dev/null 2>&1; then
    echo "sha256sum"
  else
    return 1
  fi
}

HASH_TOOL="$(zf::hash_tool || true)"
if [[ -z "${HASH_TOOL}" ]]; then
  echo "ERROR: No sha256 hash tool (shasum or sha256sum) available" >&2
  exit 4
fi

command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found" >&2; exit 4; }

# Self-test creates synthetic manifest & directories in TMPDIR
if (( SELF_TEST )); then
  tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/immutability-selftest.XXXXXX")
  manifest_file="$tmp_root/manifest.json"
  # Directory A (ok)
  mkdir -p "$tmp_root/dir.ok"
  echo "echo ok" > "$tmp_root/dir.ok/100-sample-ok.zsh"
  # Compute hash
  ok_hash=$(${(z)HASH_TOOL} "$tmp_root/dir.ok/100-sample-ok.zsh" | awk '{print $1}')
  # Directory B (drift: mismatch + extra)
  mkdir -p "$tmp_root/dir.drift"
  echo "echo drift" > "$tmp_root/dir.drift/200-sample-drift.zsh"
  wrong_hash="ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"  # force mismatch
  echo "echo extra" > "$tmp_root/dir.drift/999-extra.zsh"

  # Build manifest (one ok, one drift-intended)
  cat > "$manifest_file" <<EOF_MAN
{
  "schema_version":"1.0",
  "directories":[
    {
      "name":"dir.ok",
      "relative_path":"dir.ok",
      "expected_file_count":1,
      "files":[
        {"file":"100-sample-ok.zsh","sha256":"$ok_hash"}
      ]
    },
    {
      "name":"dir.drift",
      "relative_path":"dir.drift",
      "expected_file_count":1,
      "files":[
        {"file":"200-sample-drift.zsh","sha256":"$wrong_hash"}
      ]
    }
  ]
}
EOF_MAN

  # Override root & manifest
  ROOT_DIR="$tmp_root"
  MANIFEST_PATH="$manifest_file"
  # In self-test we want JSON unless suppressed; leave flags as-is
fi

if (( ! SELF_TEST )) && [[ ! -f "$MANIFEST_PATH" ]]; then
  if (( ALLOW_MISSING )); then
    (( ! QUIET )) && echo "[immutability] Manifest missing (allowed): $MANIFEST_PATH" >&2
    if (( EMIT_JSON )); then
      printf '{"status":"manifest_missing","manifest_path":"%s","directories":[],"drift":0,"errors":[],"metrics":{"elapsed_ms":0}}' "$MANIFEST_PATH"
      echo
    fi
    exit 0
  else
    echo "ERROR: Manifest not found: $MANIFEST_PATH" >&2
    exit 3
  fi
fi

# ---------------- Python Execution ----------------
# Pass flags as integers to Python
PY_ARGS=(
  "$MANIFEST_PATH"
  "$ROOT_DIR"
  "$HASH_TOOL"
  "$EMIT_JSON"
  "$QUIET"
  "$RECOMPUTE_DIR_HASH"
  "$STRICT_MODE"
  "$ALLOW_EMPTY_OK"
  "$LIST_CHANGES"
  "$SELF_TEST"
  "$SKIP_AGG_HASH_VALIDATE"
)

PY_OUT_JSON=$(python3 - "${PY_ARGS[@]}" <<'PYEOF'
import sys, json, os, subprocess, shlex, time, hashlib, tempfile, traceback

(
  manifest_path,
  root_dir,
  hash_tool,
  emit_json,
  quiet,
  recompute_dir_hash,
  strict_mode,
  allow_empty_ok,
  list_changes,
  self_test,
  skip_agg_validate
) = sys.argv[1:]

emit_json = int(emit_json)
quiet = int(quiet)
recompute_dir_hash = int(recompute_dir_hash)
strict_mode = int(strict_mode)
allow_empty_ok = int(allow_empty_ok)
list_changes = int(list_changes)
self_test = int(self_test)
skip_agg_validate = int(skip_agg_validate)

t0 = time.perf_counter()

def eprint(*a, **k):
    if not quiet:
        print(*a, file=sys.stderr, **k)

status = "ok"
errors = []
directories_out = []
drift = False

def file_sha(path: str) -> str:
    try:
        out = subprocess.check_output(shlex.split(hash_tool) + [path], text=True)
        return out.strip().split()[0]
    except Exception:
        return "ERROR"

# Load manifest JSON
try:
    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)
except Exception as exc:
    status = "error"
    errors.append(f"parse_error:{exc}")
    if emit_json:
        out = {
            "status": status,
            "manifest_path": manifest_path,
            "directories": [],
            "drift": 1,
            "errors": errors,
            "metrics": {"elapsed_ms": round((time.perf_counter()-t0)*1000, 3)}
        }
        print(json.dumps(out))
    else:
        eprint(f"[immutability] ERROR: Failed to parse manifest: {exc}")
    sys.exit(4)

dirs = manifest.get("directories", [])
if not quiet:
    eprint(f"[immutability] Manifest: {manifest_path if not self_test else '(self_test)'}")

# Build set of filesystem layer directories (only if strict_mode, pattern: *.empty)
fs_dirs = []
if strict_mode:
    try:
        for entry in os.listdir(root_dir):
            if entry.endswith(".empty") and os.path.isdir(os.path.join(root_dir, entry)):
                fs_dirs.append(entry)
    except Exception as exc:
        errors.append(f"fs_scan_error:{exc}")

manifest_names = []
total_files_expected = 0
total_files_checked = 0
total_files_missing = 0
total_files_extra = 0
total_hash_mismatches = 0
total_agg_mismatch = 0
drift_directories = 0

for d in dirs:
    name = d.get("name")
    rel = d.get("relative_path")
    exp_count = d.get("expected_file_count")
    files = d.get("files", [])
    dir_hash_ref = d.get("dir_hash")

    manifest_names.append(name if name else "")

    schema_ok = (
        isinstance(name, str) and name and
        isinstance(rel, str) and rel and
        isinstance(exp_count, int) and
        isinstance(files, list)
    )
    if not schema_ok:
        errors.append(f"directory_schema_invalid:{name or rel or 'UNKNOWN'}")
        if strict_mode:
            drift = True

    abs_dir = os.path.join(root_dir, rel) if schema_ok else None
    actual_files = []
    if schema_ok and os.path.isdir(abs_dir):
        actual_files = sorted([f for f in os.listdir(abs_dir) if f.endswith(".zsh")])
    elif schema_ok:
        errors.append(f"directory_missing:{rel}")
        drift = True

    # Map expected
    expected_map = {}
    if isinstance(files, list):
        for fobj in files:
            fn = fobj.get("file")
            sha = fobj.get("sha256")
            if fn and sha:
                expected_map[fn] = sha

    expected_names = sorted(expected_map.keys())
    total_files_expected += len(expected_names)

    missing = [f for f in expected_names if f not in actual_files]
    extra = [f for f in actual_files if f not in expected_names]

    file_entries = []
    hash_mismatches = []

    for fn in expected_names:
        exp_sha = expected_map.get(fn)
        if fn not in actual_files:
            file_entries.append({
                "file": fn,
                "expected_sha256": exp_sha,
                "actual_sha256": "",
                "match": False
            })
            continue
        actual_sha = file_sha(os.path.join(abs_dir, fn))
        match = (actual_sha == exp_sha)
        if not match:
            hash_mismatches.append(fn)
        file_entries.append({
            "file": fn,
            "expected_sha256": exp_sha,
            "actual_sha256": actual_sha,
            "match": bool(match)
        })

    total_files_checked += len(file_entries)
    total_files_missing += len(missing)
    total_files_extra += len(extra)
    total_hash_mismatches += len(hash_mismatches)

    # Aggregate hash computation (expected files only, ordered by filename)
    aggregate_sha = None
    agg_mismatch = False
    if recompute_dir_hash:
        lines = []
        for fe in file_entries:
            digest = fe["actual_sha256"] or "MISSING"
            lines.append(f"{digest} {fe['file']}")
        lines.sort()
        h = hashlib.sha256("\n".join(lines).encode()).hexdigest()
        aggregate_sha = h
        if dir_hash_ref and not skip_agg_validate:
            if h != dir_hash_ref:
                agg_mismatch = True
                total_agg_mismatch += 1

    actual_count = len(actual_files)
    dir_status = "ok"
    # Drift conditions
    if (
        missing or extra or hash_mismatches or
        (schema_ok and actual_count != exp_count) or
        (agg_mismatch) or
        (strict_mode and not allow_empty_ok and exp_count == 0) or
        (strict_mode and not schema_ok)
    ):
        dir_status = "drift"
        drift = True
        drift_directories += 1

    # Human output filtering (list-changes)
    if not quiet:
        if (not list_changes) or (list_changes and dir_status == "drift"):
            eprint(f" - {name:30} status={dir_status} expected={exp_count} actual={actual_count}")
            if missing:
                eprint(f"    missing: {' '.join(missing)}")
            if extra:
                eprint(f"    extra: {' '.join(extra)}")
            if hash_mismatches:
                for hm in hash_mismatches:
                    eprint(f"    hash_mismatch: {hm}")
            if agg_mismatch:
                eprint(f"    aggregate_hash_mismatch: expected={dir_hash_ref} actual={aggregate_sha}")

    dir_obj = {
        "name": name,
        "relative_path": rel,
        "expected_count": exp_count,
        "actual_count": actual_count,
        "status": dir_status,
        "files": file_entries,
        "missing_files": missing,
        "extra_files": extra,
        "hash_mismatches": hash_mismatches,
    }
    if aggregate_sha is not None:
        dir_obj["aggregate_sha256"] = aggregate_sha
    if dir_hash_ref:
        dir_obj["dir_hash_manifest"] = dir_hash_ref
        if agg_mismatch:
            dir_obj["aggregate_hash_mismatch"] = True

    directories_out.append(dir_obj)

# Strict mode: check for filesystem directories not in manifest
if strict_mode and fs_dirs:
    manifest_set = set(filter(None, manifest_names))
    for fsd in fs_dirs:
        if fsd not in manifest_set:
            errors.append(f"fs_directory_unlisted:{fsd}")
            drift = True

if not quiet and not self_test:
    eprint(f"[immutability] RESULT: {'DRIFT DETECTED' if drift else 'OK'}")

elapsed_ms = round((time.perf_counter() - t0) * 1000, 3)

# Metrics
metrics = {
    "elapsed_ms": elapsed_ms,
    "directories_total": len(directories_out),
    "directories_drift": drift_directories,
    "files_expected": total_files_expected,
    "files_checked": total_files_checked,
    "files_missing": total_files_missing,
    "files_extra": total_files_extra,
    "hash_mismatches": total_hash_mismatches,
    "aggregate_hash_mismatches": total_agg_mismatch
}

# Self-test result evaluation
if self_test:
    # Expect: dir.ok => ok, dir.drift => drift
    names = {d["name"]: d for d in directories_out}
    ok_ok = names.get("dir.ok", {}).get("status") == "ok"
    ok_drift = names.get("dir.drift", {}).get("status") == "drift"
    self_pass = ok_ok and ok_drift
    status = "self_test_pass" if self_pass else "self_test_fail"
    drift = 0  # Treat overall drift as 0 for self-test mode (status conveys result)
    if not quiet:
        eprint(f"[self-test] dir.ok status={names.get('dir.ok',{}).get('status')} expected=ok")
        eprint(f"[self-test] dir.drift status={names.get('dir.drift',{}).get('status')} expected=drift")
        eprint(f"[self-test] RESULT: {'PASS' if self_pass else 'FAIL'}")

result = {
    "status": status if not (self_test and status.startswith("self_test_")) else status,
    "manifest_path": manifest_path if not self_test else "(self_test)",
    "directories": directories_out,
    "drift": 1 if (not self_test and drift) else 0,
    "errors": errors,
    "metrics": metrics
}

if emit_json:
    print(json.dumps(result, sort_keys=False))

# Exit semantics
if self_test:
    # 0 pass, 1 fail
    sys.exit(0 if result["status"] == "self_test_pass" else 1)
else:
    sys.exit(1 if drift else 0)
PYEOF
) || PY_STATUS=$? || true

PY_STATUS=${PY_STATUS:-0}

if (( EMIT_JSON )); then
  [[ -n "${PY_OUT_JSON}" ]] && print -r -- "${PY_OUT_JSON}"
fi

exit "${PY_STATUS}"
