#!/usr/bin/env zsh
# ============================================================================
# test-path-hygiene.zsh
#
# Purpose:
#   Validates Stage 3 PATH hygiene guarantees after sourcing the redesigned
#   .zshenv and security integrity scaffold (00-security-integrity.zsh).
#
# Assertions:
#   A1: Core system utility directories that exist on the host are present
#       in $PATH (e.g. /usr/bin, /bin, /usr/sbin, /sbin).
#   A2: Optional platform dirs (/opt/homebrew/bin, /usr/local/bin, /usr/local/sbin)
#       are appended if they exist and were missing initially.
#   A3: No duplicate path segments (first occurrence preserved).
#   A4: PATH append fix works when starting from an *empty* PATH.
#   A5: Sourcing security module does not destructively reorder earlier segments.
#
# Strategy:
#   1. Spawn a *clean* zsh with an empty PATH (env -i PATH="").
#   2. Allow native .zshenv to run (zsh always sources .zshenv).
#   3. Explicitly source 00-security-integrity.zsh (Stage 3 scaffold).
#   4. Capture resulting PATH and run validations inside the spawned shell.
#
# Output:
#   Prints "PASS: <assertion>" or "FAIL: <assertion> - <reason>" lines.
#   Exits non-zero if any assertion fails.
#
# Notes:
#   - Keeps logic self‑contained; does not rely on external tools beyond
#     standard shell built-ins and testable coreutils that should now be
#     on PATH after fix.
#   - Avoids assuming Homebrew presence (only checks if directory exists).
#
# Environment:
#   Executed from repository root (tests harness convention). If not, attempt
#   to derive the repo root relative to this script.
# ============================================================================

set -euo pipefail

# Resolve repo root (directory containing dot-config/)
SCRIPT_DIR="$(cd -- "$(dirname -- "${(%):-%N}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"

ZSH_DIR="${REPO_ROOT}/dot-config/zsh"
ZDOTDIR="${ZSH_DIR}"

SEC_MODULE_REL=".zshrc.d.REDESIGN/POSTPLUGIN/00-security-integrity.zsh"
SEC_MODULE="${ZSH_DIR}/${SEC_MODULE_REL}"

if [[ ! -f "${ZSH_DIR}/.zshenv" ]]; then
    print -u2 "FAIL: prerequisite - .zshenv not found at ${ZSH_DIR}/.zshenv"
    exit 1
fi
if [[ ! -f "${SEC_MODULE}" ]]; then
    print -u2 "FAIL: prerequisite - security module not found at ${SEC_MODULE}"
    exit 1
fi

# Spawn a clean zsh environment:
#  - env -i : empty environment baseline
#  - Set only essentials: HOME, ZDOTDIR, PATH (empty), TERM (avoid tput noise)
#  - -f : skip .zshrc
#  - -d : skip global rc files
#  .zshenv will *still* be processed automatically.
#
# Inside command:
#   1. Export a marker for test context.
#   2. Source the security module (Stage 3).
#   3. Run validation function; emit a serialized report.
#
read -r -d '' ZSH_PAYLOAD <<'__ZSH_EOF__'
set -euo pipefail

_failures=()
_passes=()

record_pass() { _passes+=("$1"); }
record_fail() { _failures+=("$1"); }

# Ensure we are really starting from an empty or near-empty PATH scenario
# (After .zshenv it will no longer be empty; we capture what it became.)
ORIGINAL_PATH_AFTER_ZSHENV="$PATH"

# Source security module (idempotent registration)
# shellcheck disable=SC1090
if ! source "$SEC_MODULE"; then
    record_fail "A0: source-security-module - failed to source 00-security-integrity.zsh"
else
    record_pass "A0: source-security-module"
fi

TEST_PATH="$PATH"

# A1: Core directories present if they exist on filesystem
typeset -a core_dirs
core_dirs=( /usr/bin /bin /usr/sbin /sbin )
for d in "${core_dirs[@]}"; do
    if [[ -d "$d" ]]; then
        case ":$TEST_PATH:" in
            *:"$d":*) ;; # present
            *) record_fail "A1: core-dir-missing ($d not in PATH)" ;;
        esac
    fi
done
# If no failures added for A1 core set:
if ! printf '%s\n' "${_failures[@]}" | grep -q 'A1: core-dir-missing' 2>/dev/null; then
    record_pass "A1: core-core-dirs-present"
fi

# A2: Platform optional dirs appended if exist and were not in initial (post-.zshenv) PATH
typeset -a opt_dirs
opt_dirs=( /opt/homebrew/bin /usr/local/bin /usr/local/sbin )
for d in "${opt_dirs[@]}"; do
    [[ -d "$d" ]] || continue
    # Must be present now:
    case ":$TEST_PATH:" in
        *:"$d":*) ;;
        *) record_fail "A2: optional-dir-missing ($d exists but not in PATH)" ;;
    esac
done
if ! printf '%s\n' "${_failures[@]}" | grep -q 'A2:' 2>/dev/null; then
    record_pass "A2: optional-platform-dirs-appended"
fi

# A3: No duplicate segments
typeset -A seen
dup_found=0
OLD_IFS="$IFS"
IFS=":"
for seg in $TEST_PATH; do
    [[ -z "$seg" ]] && continue
    if [[ -n "${seen[$seg]:-}" ]]; then
        dup_found=1
        record_fail "A3: duplicate-segment ($seg)"
        break
    fi
    seen[$seg]=1
done
IFS="$OLD_IFS"
(( dup_found == 0 )) && record_pass "A3: no-duplicates"

# A4: Append semantics (since we started with empty PATH, ordering does not
#     need strict preservation, but security module must NOT have *removed*
#     segments that .zshenv already placed).
missing_after_module=0
OLD_IFS="$IFS"
IFS=":"
for seg in $ORIGINAL_PATH_AFTER_ZSHENV; do
    [[ -z "$seg" ]] && continue
    case ":$TEST_PATH:" in
        *:"$seg":*) ;;
        *) missing_after_module=1; record_fail "A4: segment-missing-post-module ($seg)" ;;
    esac
done
IFS="$OLD_IFS"
(( missing_after_module == 0 )) && record_pass "A4: append-non-destructive"

# A5: Idempotency of security module (re-source should not change PATH)
PATH_BEFORE_RESOURCE="$TEST_PATH"
# shellcheck disable=SC1090
source "$SEC_MODULE"
PATH_AFTER_RESOURCE="$PATH"
if [[ "$PATH_BEFORE_RESOURCE" == "$PATH_AFTER_RESOURCE" ]]; then
    record_pass "A5: idempotent-resourcing"
else
    record_fail "A5: idempotent-resourcing (PATH changed)"
fi

# Emit results
for p in "${_passes[@]}"; do
    print "PASS: $p"
done
for f in "${_failures[@]}"; do
    print "FAIL: $f"
done

# Summary line
print "---"
print "SUMMARY: passes=${#_passes[@]} fails=${#_failures[@]}"

# Exit with failure count status
(( ${#_failures[@]} == 0 )) || exit 1
exit 0
__ZSH_EOF__

set +e
RAW_OUTPUT="$(env -i \
    HOME="$HOME" \
    ZDOTDIR="$ZDOTDIR" \
    SEC_MODULE="$SEC_MODULE" \
    PATH="" \
    TERM=dumb \
    ZSH_DEBUG=0 \
    zsh -dfc "${ZSH_PAYLOAD}")"
rc=$?
set -e

print -- "$RAW_OUTPUT"

if (( rc != 0 )); then
    print -u2 "TEST RESULT: FAIL (rc=$rc)"
    exit $rc
fi

print "TEST RESULT: PASS"
exit 0
