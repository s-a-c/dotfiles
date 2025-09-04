#!/usr/bin/env zsh
# integrity-hash-preplugin.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Generate a JSON manifest of cryptographic (SHA‑256) hashes for critical *pre‑plugin*
#   initialization files so that promotion guard & security tests can detect
#   unauthorized or accidental modifications.
#
#   Produces (by default):
#     integrity-current.json
#   Optionally (first-run or explicit):
#     integrity-baseline.json  (created if --write-baseline and no existing baseline)
#
# SCOPE / FILE SET:
#   - .zshenv (root-level env contract)
#   - .zshrc.pre-plugins.d.REDESIGN/*.zsh (ordered, deterministic)
#   - Optionally extra files added via --include <glob> (can be repeated)
#
# OUTPUT SCHEMA (preplugin-integrity.v1):
# {
#   "schema": "preplugin-integrity.v1",
#   "timestamp": "UTC ISO basic",
#   "guidelines_checksum": "<sha256 or unknown>",
#   "aggregate_sha256": "<sha256 over ordered file hashes + paths>",
#   "files": [
#     {"path":"RELATIVE","sha256":"...","size":1234,"mtime":"2025-09-02T01:23:45Z"}
#   ]
# }
#
# EXIT CODES:
#   0 success
#   1 generic failure (unexpected)
#   2 no target files discovered
#   3 hashing tool unavailable
#   4 JSON write failure
#
# OPTIONS:
#   --metrics-dir <dir>      Override metrics artifact directory
#   --write-baseline         Also write / seed integrity-baseline.json if absent
#   --force-baseline         Overwrite existing baseline (use sparingly)
#   --include <glob>         Additional glob (relative to repo root) to include (repeatable)
#   --pretty                 Pretty-print JSON (otherwise compact)
#   --show                   Print JSON to stdout (in addition to file write)
#   -q / --quiet             Suppress informational stderr output
#   -h / --help              Show usage
#
# SECURITY NOTES:
#   - Uses only standard utilities: shasum or openssl.
#   - Deterministic ordering ensures reproducible aggregate hash.
#
# DESIGN CHOICES:
#   - Avoid jq requirement; pure shell + awk + sed.
#   - Aggregate hash = sha256 over newline-joined "<path>\t<sha256>" list.
+#
+# PATCH NOTE:
+#   Added SAFE_PATH bootstrap to ensure core utilities (shasum / openssl) are discoverable
+#   even if pre-plugin PATH normalization removed system dirs. Also made hashing routine
+#   resilient with absolute fallbacks.
 set -euo pipefail

quiet=0
write_baseline=0
force_baseline=0
pretty=0
show=0
extra_globs=()

print_err() { (( quiet )) || print -u2 -- "$*"; }
die() { print -u2 -- "[integrity] ERROR: $*"; exit "${2:-1}"; }

usage() {
    cat <<'EOF'
Usage: tools/integrity-hash-preplugin.zsh [options]

Options:
    --metrics-dir <dir>   Override metrics directory
    --write-baseline      Create baseline file if missing
    --force-baseline      Overwrite existing baseline file
    --include <glob>      Additional glob (repeat; relative to repo root)
    --pretty              Pretty-print JSON
    --show                Emit JSON to stdout
    -q, --quiet           Suppress info logs
    -h, --help            Show help

Exit Codes:
    0 success
    2 no files
    3 no hashing tool
    4 write failure
EOF
}

while (( $# )); do
    case "$1" in
        --metrics-dir) METRICS_OVERRIDE="$2"; shift 2 ;;
        --write-baseline) write_baseline=1; shift ;;
        --force-baseline) force_baseline=1; shift ;;
        --include) extra_globs+=("$2"); shift 2 ;;
        --pretty) pretty=1; shift ;;
        --show) show=1; shift ;;
        -q|--quiet) quiet=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" 1 ;;
    esac
done

# Resolve repo root (script located at .../tools/) - resilient (avoids direct ${0:A:h})
if typeset -f zf::script_dir >/dev/null 2>&1; then
    SCRIPT_DIR="$(zf::script_dir "${(%):-%N}")"
elif typeset -f resolve_script_dir >/dev/null 2>&1; then
    SCRIPT_DIR="$(resolve_script_dir "${(%):-%N}")"
else
    _ih_src="${(%):-%N}"
    [[ -z "$_ih_src" ]] && _ih_src="$0"
    if [[ -h "$_ih_src" ]]; then
        _ih_link="$(readlink "$_ih_src" 2>/dev/null || true)"
        [[ -n "$_ih_link" ]] && _ih_src="$_ih_link"
        unset _ih_link
    fi
    SCRIPT_DIR="${_ih_src:h}"
    unset _ih_src
fi
ROOT="${SCRIPT_DIR:h}"
cd "$ROOT"

ZDOTDIR_DEFAULT="${ROOT}"
# Metrics directory resolution (prefer redesignv2)
if [[ -n ${METRICS_OVERRIDE:-} ]]; then
    METRICS_DIR="$METRICS_OVERRIDE"
else
    if [[ -d "${ROOT}/docs/redesignv2/artifacts/metrics" ]]; then
        METRICS_DIR="${ROOT}/docs/redesignv2/artifacts/metrics"
    else
        METRICS_DIR="${ROOT}/docs/redesign/metrics"
    fi
fi
mkdir -p "$METRICS_DIR"

timestamp=$(date -u +%Y%m%dT%H%M%SZ 2>/dev/null || date +%Y%m%dT%H%M%S)

# Hash utility
# Bootstrap a safe PATH (prepend) to avoid loss of core utilities after .zshenv PATH hygiene.
SAFE_PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
PATH="${SAFE_PATH}:${PATH}"
hash_cmd=""
if command -v shasum >/dev/null 2>&1; then
    hash_cmd="$(command -v shasum) -a 256"
elif command -v gshasum >/dev/null 2>&1; then
    hash_cmd="$(command -v gshasum) -a 256"
elif command -v openssl >/dev/null 2>&1; then
    hash_cmd="$(command -v openssl) dgst -sha256" # output: SHA256(file)= <hash>
else
    die "No sha256 hashing tool found (shasum / openssl)" 3
fi

hash_file() {
    local f=$1 raw out
    # Try primary command
    if [[ $hash_cmd == *openssl* ]]; then
        raw=$($hash_cmd "$f" 2>/dev/null || true)
        [[ -n $raw ]] && out=$(print -r -- "$raw" | awk -F'= ' '{print $2}')
    else
        raw=$($hash_cmd "$f" 2>/dev/null || true)
        [[ -n $raw ]] && out=$(print -r -- "$raw" | awk '{print $1}')
    fi
    # Fallbacks (absolute binaries) if empty
    if [[ -z ${out:-} ]]; then
        if [[ -x /usr/bin/shasum ]]; then
        out=$(/usr/bin/shasum -a 256 "$f" 2>/dev/null | awk '{print $1}')
        elif [[ -x /usr/bin/openssl ]]; then
        out=$(/usr/bin/openssl dgst -sha256 "$f" 2>/dev/null | awk -F'= ' '{print $2}')
        fi
    fi
    [[ -n ${out:-} ]] || return 1
    print -r -- "$out"
}

# Guidelines checksum (best-effort)
guidelines_path="${ROOT}/dot-config/ai/guidelines.md"
guidelines_checksum="unknown"
if [[ -f $guidelines_path ]]; then
    if gc=$(hash_file "$guidelines_path" 2>/dev/null); then
        guidelines_checksum="$gc"
    fi
fi

# Collect target files
targets=()
pre_dir=".zshrc.pre-plugins.d.REDESIGN"
if [[ -d $pre_dir ]]; then
    while IFS= read -r f; do
        targets+=("$f")
    done < <(LC_ALL=C find "$pre_dir" -type f -name '*.zsh' -maxdepth 1 -print | LC_ALL=C sort)
fi

# Ensure .zshenv is recorded with repository-relative path (dot-config/zsh/.zshenv)
# Include root .zshenv explicitly as first manifest entry (relative to tool ROOT which is dot-config/zsh)
if [[ -f ".zshenv" ]]; then
    targets=(".zshenv" "${targets[@]}")
fi

# Extra globs
for g in "${extra_globs[@]}"; do
    while IFS= read -r f; do
        [[ -n $f ]] && targets+=("$f")
    done < <(eval "printf '%s\n' $g" | while read -r pat; do
        LC_ALL=C compgen -G "$pat" 2>/dev/null || echo ""
        done | LC_ALL=C sort -u)
done

# Deduplicate preserving order
typeset -A _seen
ordered=()
for f in "${targets[@]}"; do
    [[ -z $f ]] && continue
    [[ -f $f ]] || continue
    if [[ -z ${_seen[$f]:-} ]]; then
        _seen[$f]=1
        ordered+=("$f")
    fi
done
unset _seen targets

if (( ${#ordered[@]} == 0 )); then
    print_err "[integrity] No pre-plugin files found – skipping"
    exit 2
fi

print_err "[integrity] Hashing ${#ordered[@]} files..."

json_files=()         # to build file objects
aggregate_lines=()    # "<path>\t<hash>" lines

# Collect metadata & hashes
for rel in "${ordered[@]}"; do
    # Hash file using manifest path directly (preserve full relative path so .zshenv resolves)
    sha=$(hash_file "$rel" || true)
    if [[ -z $sha ]]; then
        die "Failed to hash $rel" 3
    fi

    # size
    size=$(wc -c <"$rel" 2>/dev/null || echo 0)
    # mtime (UTC ISO8601 basic)
    # macOS vs GNU stat portability
    if stat -f %m "$rel" >/dev/null 2>&1; then
        epoch=$(stat -f %m "$rel")
    else
        epoch=$(stat -c %Y "$rel" 2>/dev/null || echo 0)
    fi
    mtime=$(date -u -r "$epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)

    json_files+=("{\"path\":\"$rel\",\"sha256\":\"$sha\",\"size\":$size,\"mtime\":\"$mtime\"}")
    aggregate_lines+=("${rel}\t${sha}")
done

# Aggregate hash (ordered)
aggregate_input=$(printf '%s\n' "${aggregate_lines[@]}")
aggregate_sha=$(printf '%s\n' "$aggregate_input" | {
    if command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}'; \
    elif command -v gshasum >/dev/null 2>&1; then gshasum -a 256 | awk '{print $1}'; \
    else openssl dgst -sha256 | awk '{print $2}'; fi
})

# Construct JSON
if (( pretty )); then
    sep=$'\n'
    indent="  "
else
    sep=""
    indent=""
fi

files_json=$(IFS=,; print -r -- "${json_files[*]}")

current_json="${indent}{${sep}${indent}\"schema\": \"preplugin-integrity.v1\",${sep}${indent}\"timestamp\": \"${timestamp}\",${sep}${indent}\"guidelines_checksum\": \"${guidelines_checksum}\",${sep}${indent}\"aggregate_sha256\": \"${aggregate_sha}\",${sep}${indent}\"file_count\": ${#ordered[@]},${sep}${indent}\"files\": [${sep}${indent}${files_json}${sep}${indent}]${sep}${indent}}"

current_path="${METRICS_DIR}/integrity-current.json"
baseline_path="${METRICS_DIR}/integrity-baseline.json"

# Write current
printf '%s\n' "$current_json" >"$current_path" || die "Failed to write $current_path" 4
print_err "[integrity] Wrote $current_path"

# Baseline logic
if (( write_baseline )); then
    if [[ -f $baseline_path && $force_baseline -eq 0 ]]; then
        print_err "[integrity] Baseline exists (use --force-baseline to overwrite)"
    else
        printf '%s\n' "$current_json" >"$baseline_path" || die "Failed to write baseline $baseline_path" 4
        print_err "[integrity] Wrote/updated baseline $baseline_path"
    fi
fi

if (( show )); then
    printf '%s\n' "$current_json"
fi

print_err "[integrity] Done (aggregate=${aggregate_sha})"
exit 0
