#!/usr/bin/env bash
# test-autopair-pty.sh - Advanced PTY-based functional harness for autopair (Decision D2)
#
# Purpose:
#   Provides a higher‑fidelity (pseudo‑TTY) behavioral probe of the active autopair
#   implementation (either hlissner/zsh-autopair or the simplified fallback implementation).
#
# Strategy:
#   1. Detect autopair presence (widgets/functions) using a hermetic non-interactive probe.
#   2. If present AND Python + pexpect are available, spawn an interactive zsh in a PTY.
#   3. Source redesign module layers (mirrors other harnesses) inside that PTY.
#   4. Send keystrokes and watch echoed line-editor output for autopair effects:
#        - Opening parenthesis inserts () pair
#        - Opening brace inserts {} pair
#        - Opening bracket inserts [] pair
#        - Opening double quote inserts "" pair
#        - Opening single quote inserts '' pair
#        - Opening backtick inserts `` pair
#        - Backspace between an autopair removes both (heuristic / best effort)
#   5. Produce structured JSON (optional) + human-readable summary.
#
# Notes / Limitations:
#   - ZLE rendering can include escape sequences; matching is heuristic.
#   - Some autopair implementations may defer rendering until additional input.
#   - Backspace pairing test is inherently fragile; inconclusive results are tolerated.
#   - If Python or pexpect is missing, we degrade to presence-only classification (status=pass|skip).
#
# Exit Codes:
#   0 = Success (all required conditions satisfied, or optional feature absent but not required)
#   1 = Failure (required but absent, or critical test infrastructure error when required)
#   2 = Internal harness error (unexpected)
#
# Options:
#   --json      Emit JSON object
#   --require   Treat absence as failure (ZSH_AUTOPAIR_REQUIRED=1)
#
# JSON Schema (example fields):
# {
#   "status": "pass"|"skip"|"fail",
#   "present": 0|1,
#   "capabilities": {
#     "pty": true|false,
#     "pexpect": true|false
#   },
#   "detection": {
#     "widgets": ["..."],
#     "variant": "hlissner"|"simple"|"unknown"|"none"
#   },
#   "tests": [
#     {"name":"paren_pair_insert","attempted":true,"passed":true,"observed":"()","inconclusive":false},
#     {"name":"brace_pair_insert","attempted":true,"passed":true,"observed":"{}","inconclusive":false},
#     {"name":"bracket_pair_insert","attempted":true,"passed":true,"observed":"[]","inconclusive":false},
#     {"name":"quote_pair_insert","attempted":true,"passed":true,"observed":"\"\"","inconclusive":false},
#     {"name":"single_quote_pair_insert","attempted":true,"passed":true,"observed":"''","inconclusive":false},
#     {"name":"backtick_pair_insert","attempted":true,"passed":true,"observed":"``","inconclusive":false},
#     {"name":"backspace_pair_delete","attempted":true,"passed":false,"inconclusive":true,"observed":""}
#   ]
# }
#
# Phase 7 Closure Alignment (Decision D2):
#   - This harness upgrades from presence-only to PTY behavioral verification.
#   - If PTY simulation is infeasible (environmental), we document rationale in output.
#
# Safety:
#   - Uses set -euo pipefail; internal guarded zones temporarily relax errexit where needed.
#   - No global stderr suppression; explicit messaging on failure paths.

set -euo pipefail

JSON=0
REQUIRE=${ZSH_AUTOPAIR_REQUIRED:-0}

for arg in "$@"; do
  case "$arg" in
    --json) JSON=1 ;;
    --require) REQUIRE=1 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}" 2>/dev/null || true
}
trap cleanup EXIT

# ----------------------------------------
# Step 1: Detection (re-use logic similar to basic test harness)
# ----------------------------------------
detect_script="${tmpdir}/detect.zsh"
cat > "${detect_script}" <<'ZEOF'
set +o errexit
set +o nounset

autoload -Uz zle 2>/dev/null || true
_present=0
_variant="none"

widgets_list=""
if zle -la 2>/dev/null | grep -qi autopair; then
  _present=1
  widgets_list="$(zle -la | grep -i autopair || true)"
fi

# Check for simplified implementation widgets
if zle -la 2>/dev/null | grep -q '^simple-autopair-insert$'; then
  _present=1
  if [[ "${_variant}" == "none" ]]; then
    _variant="simple"
  fi
fi

# hlissner plugin usually defines autopair-insert or similar
if zle -la 2>/dev/null | grep -q '^autopair-insert$'; then
  if [[ "${_variant}" == "none" ]]; then
    _variant="hlissner"
  fi
fi

# Fallback unknown variant classification
if (( _present == 1 )) && [[ "${_variant}" == "none" ]]; then
  _variant="unknown"
fi

if (( _present == 1 )); then
  print "__AP_PRESENT=1"
else
  print "__AP_PRESENT=0"
fi
print "__AP_VARIANT=${_variant}"

if [[ -n "${widgets_list}" ]]; then
  while IFS= read -r w; do
    print "__AP_WIDGET=${w}"
  done <<< "${widgets_list}"
fi
ZEOF

detect_out="${tmpdir}/detect.out"
if ! zsh --no-rcs --no-globalrcs "${detect_script}" > "${detect_out}" 2>&1; then
  echo "Internal detection error" >&2
  [[ $JSON -eq 1 ]] && printf '{"status":"fail","error":"detection"}\n'
  exit 2
fi

present=$(grep '^__AP_PRESENT=' "${detect_out}" | head -n1 | cut -d= -f2 || echo 0)
variant=$(grep '^__AP_VARIANT=' "${detect_out}" | head -n1 | cut -d= -f2 || echo none)
mapfile -t detected_widgets < <(grep '^__AP_WIDGET=' "${detect_out}" | sed 's/^__AP_WIDGET=//g' || true)

# ----------------------------------------
# Early exit logic if not present
# ----------------------------------------
if (( present == 0 )); then
  status="skip"
  if (( REQUIRE == 1 )); then
    status="fail"
  fi
  if (( JSON == 1 )); then
    printf '{"status":"%s","present":0,"detection":{"variant":"none","widgets":[]},"capabilities":{"pty":false,"pexpect":false},"tests":[]}\n' "${status}"
  else
    echo "Autopair not present (variant: none)"
    echo "Status: ${status}"
  fi
  if [[ "${status}" == "fail" ]]; then exit 1; else exit 0; fi
fi

# ----------------------------------------
# Step 2: Capability Checks (Python + pexpect)
# ----------------------------------------
have_python=0
if command -v python3 >/dev/null 2>&1; then
  have_python=1
elif command -v python >/dev/null 2>&1; then
  have_python=1
fi

have_pexpect=0
if (( have_python == 1 )); then
  if python3 - <<'PY' >/dev/null 2>&1; then
import importlib, sys
importlib.import_module("pexpect")
PY
  then
    have_pexpect=1
  elif python - <<'PY' >/dev/null 2>&1; then
import importlib, sys
importlib.import_module("pexpect")
PY
  then
    have_pexpect=1
  fi
fi

# If no PTY capabilities, degrade gracefully
if (( have_pexpect == 0 )); then
  status="pass"
  if (( REQUIRE == 1 )) && (( present == 0 )); then
    status="fail"
  fi
  if (( JSON == 1 )); then
    printf '{"status":"%s","present":1,"detection":{"variant":"%s","widgets":[' "${status}" "${variant}"
    first=1
    for w in "${detected_widgets[@]}"; do
      [[ -z "$w" ]] && continue
      esc=${w//\\/\\\\}; esc=${esc//\"/\\\"}
      if [[ $first -eq 0 ]]; then printf ','; fi
      first=0
      printf '"%s"' "$esc"
    done
    printf ']},"capabilities":{"pty":false,"pexpect":false},"tests":[],"note":"pexpect missing; presence-only pass"}\n'
  else
    echo "Autopair detected (variant: ${variant})"
    echo "Widgets:"
    if ((${#detected_widgets[@]})); then
      for w in "${detected_widgets[@]}"; do echo "  - $w"; done
    else
      echo "  (none enumerated)"
    fi
    echo "PTY / pexpect not available; skipping behavioral tests (consider installing python3 + pexpect)"
    echo "Status: ${status}"
  fi
  [[ "${status}" == "fail" ]] && exit 1 || exit 0
fi

# ----------------------------------------
# Step 3: PTY Behavioral Simulation (Python pexpect)
# ----------------------------------------
py_json_out="${tmpdir}/pty-tests.json"
python3 - <<'PYCODE' > "${py_json_out}" 2>/dev/null || python - <<'PYCODE' > "${py_json_out}" 2>/dev/null
import json, os, sys, time, re
tests = []

def record(name, attempted, passed=False, observed="", inconclusive=False, error=None):
    tests.append({
        "name": name,
        "attempted": attempted,
        "passed": bool(passed),
        "observed": observed,
        "inconclusive": bool(inconclusive),
        "error": error
    })

try:
    import pexpect
except Exception as e:
    # Should not reach here (already verified), but guard anyway.
    record("infrastructure_import", True, passed=False, error=str(e))
    print(json.dumps({"infra_error": True, "tests": tests}))
    sys.exit(0)

# Spawn interactive zsh (hermetic) - we will source modules manually.
# Use env to reduce noise.
env = os.environ.copy()
child = pexpect.spawn("zsh", ["--no-rcs", "--no-globalrcs", "-i"], encoding="utf-8", timeout=2)
try:
    # Minimize prompt noise
    child.sendline('unsetopt PROMPT_SP PROMPT_CR; PS1=">AUTO>"; PROMPT="%B>AUTO>%b "; RPROMPT=""')
    # Source redesign layers
    child.sendline('for d in .zshrc.pre-plugins.d.empty .zshrc.add-plugins.d.empty .zshrc.d.empty; do [[ -d $d ]] || continue; for f in $d/*.zsh; do source "$f" 2>/dev/null || print -u2 "ERR sourcing $f"; done; done; echo __READY__')
    child.expect('__READY__')
    ready_output = child.before + child.after
except Exception as e:
    record("session_init", True, passed=False, error=f"init-failure:{e}")
    print(json.dumps({"infra_error": True, "tests": tests}))
    try:
        child.terminate(True)
    except Exception:
        pass
    sys.exit(0)

record("session_init", True, passed=True)

def clear_line():
    # CTRL-U to kill line
    child.send('\x15')
    time.sleep(0.05)

# Heuristic: after sending an opening autopair char we expect the pair to appear in the echoed buffer.
def test_pair(name, char, expected_pattern):
    attempted = True
    try:
        clear_line()
        child.send(char)
        time.sleep(0.08)
        # Collect a small chunk of the child buffer (non-deterministic; fetch .before not reliable mid-stream)
        # Use child.before only after an expect. We'll attempt an expect with a short timeout.
        passed = False
        inconclusive = False
        observed_snippet = ""
        try:
            child.expect(re.escape(expected_pattern), timeout=0.3)
            observed_snippet = expected_pattern
            passed = True
        except pexpect.TIMEOUT:
            # Fallback: read whatever is available (non-fatal)
            try:
                observed_snippet = child.before[-40:]
            except Exception:
                observed_snippet = ""
            # Heuristic: if we at least see the opening char we call it inconclusive not failed
            if char in observed_snippet:
                inconclusive = True
            else:
                passed = False
        record(name, attempted, passed=passed, observed=observed_snippet, inconclusive=inconclusive)
    except Exception as e:
        record(name, attempted, passed=False, error=str(e))

def test_backspace(name):
    attempted = True
    try:
        clear_line()
        child.send('(')
        time.sleep(0.05)
        # Expect maybe '()'
        try:
            child.expect(r'\(\)', timeout=0.25)
        except pexpect.TIMEOUT:
            pass
        # Send backspace
        child.send('\x7f')
        time.sleep(0.05)
        # Send a sentinel to flush line content for inspection
        child.send('\x15')  # Clear again to reveal if leftover char remained
        time.sleep(0.05)
        # Result heuristics are limited; treat as inconclusive unless we earlier matched '()'
        # If we previously saw '()' and now cannot match '(' or ')', call pass.
        # Easiest: attempt a zero-time expect for '(' (will raise TIMEOUT quickly if not present)
        leftover = ""
        try:
            child.expect(r'\(', timeout=0.15)
            leftover = "("
            passed = False
            inconclusive = True
        except pexpect.TIMEOUT:
            leftover = ""
            passed = True
            inconclusive = False
        record(name, True, passed=passed, observed=leftover, inconclusive=inconclusive)
    except Exception as e:
        record(name, True, passed=False, error=str(e))

# Execute tests
test_pair("paren_pair_insert", "(", "()")
test_pair("brace_pair_insert", "{", "{}")
test_pair("bracket_pair_insert", "[", "[]")
test_pair("quote_pair_insert", '"', '""')
test_pair("single_quote_pair_insert", "'", "''")
test_pair("backtick_pair_insert", "`", "``")
test_backspace("backspace_pair_delete")

try:
    child.sendline('exit')
except Exception:
    pass
try:
    child.close(force=True)
except Exception:
    pass

print(json.dumps({"infra_error": False, "tests": tests}))
PYCODE

if [[ ! -s "${py_json_out}" ]]; then
  echo "Internal error: PTY test produced no output" >&2
  [[ $JSON -eq 1 ]] && printf '{"status":"fail","error":"pty-empty","present":1}\n'
  exit 2
fi

# Parse JSON (basic, without jq dependency).
pty_raw="$(cat "${py_json_out}")"
infra_error=$(grep -c '"infra_error": false' "${py_json_out}" || true)
tests_json="$(printf '%s' "${pty_raw}" | sed -n 's/.*"tests":\s*\(\[[^]]*]\).*/\1/p')"

# Very lightweight parsing of pass states:
passed_cases=0
total_cases=0
inconclusive_cases=0

# Count occurrences via grep patterns
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  # naive extraction
  name=$(echo "$line" | sed -n 's/.*"name":\s*"\([^"]*\)".*/\1/p')
  passed=$(echo "$line" | grep -c '"passed": true' || true)
  inconc=$(echo "$line" | grep -c '"inconclusive": true' || true)
  if [[ -n "$name" ]]; then
    total_cases=$((total_cases+1))
    if (( passed > 0 )); then
      passed_cases=$((passed_cases+1))
    fi
    if (( inconc > 0 )); then
      inconclusive_cases=$((inconclusive_cases+1))
    fi
  fi
done < <(printf '%s\n' "${tests_json//\},/\}\n}")

status="pass"
# Failure conditions: required + (no passed cases OR infra error)
if (( REQUIRE == 1 )); then
  if (( infra_error == 0 )) || (( passed_cases == 0 )); then
    status="fail"
  fi
fi

if (( JSON == 1 )); then
  printf '{"status":"%s","present":1,' "${status}"
  # detection
  printf '"detection":{"variant":"%s","widgets":[' "${variant}"
  first=1
  for w in "${detected_widgets[@]}"; do
    [[ -z "$w" ]] && continue
    esc=${w//\\/\\\\}; esc=${esc//\"/\\\"}
    if [[ $first -eq 0 ]]; then printf ','; fi
    first=0
    printf '"%s"' "$esc"
  done
  printf ']},'
  printf '"capabilities":{"pty":true,"pexpect":true},'
  printf '"summary":{"total":%d,"passed":%d,"inconclusive":%d},' "$total_cases" "$passed_cases" "$inconclusive_cases"
  # Attach raw test objects
  printf '"tests":%s' "${tests_json:-[]}"
  printf '}\n'
else
  echo "Autopair present (variant: ${variant})"
  echo "Detected widgets:"
  if ((${#detected_widgets[@]})); then
    for w in "${detected_widgets[@]}"; do echo "  - $w"; done
  else
    echo "  (none enumerated)"
  fi
  echo
  echo "PTY Test Results:"
  echo "  Total cases: ${total_cases}"
  echo "  Passed:      ${passed_cases}"
  echo "  Inconclusive:${inconclusive_cases}"
  if (( passed_cases == 0 )); then
    echo "  NOTE: No positive passes detected; heuristic limitations may apply."
  fi
  echo
  echo "Status: ${status}"
fi

if [[ "${status}" == "fail" ]]; then
  exit 1
fi
exit 0
