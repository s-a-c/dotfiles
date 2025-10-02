#!/usr/bin/env bash
# emergency-widget-count.sh
#
# Purpose:
#   Reliably obtain the ZLE widget count from the emergency ZSH configuration
#   by forcing execution inside a real PTY. Non-PTY invocations (plain `zsh -i -c`)
#   can yield 0 widgets because the line editor does not fully initialize.
#
# Strategy:
#   1. Prefer the `script` utility (common on macOS / Linux).
#   2. Fallback to a Python `pty` module runner.
#   3. (Optional future) Could add `expect` fallback.
#
# Output:
#   Default: plain integer widget count (or 0 if not obtainable).
#   With --json: JSON object:
#     {
#       "status": "ok" | "error",
#       "widgets": <int>,
#       "method": "script" | "python-pty" | "none",
#       "notes": "<rationale / warnings>"
#     }
#
# Exit Codes:
#   0  Success (even if widgets=0; rely on JSON/status for diagnostics)
#   1  Usage error (bad flag)
#
# Environment (optional):
#   EMERGENCY_ZSHRC_PATH   Path to emergency config (default: .zshrc.emergency)
#   EMERGENCY_ZSH_BIN      zsh binary (default: output of `command -v zsh`)
#
# Safety:
#   - set -euo pipefail
#   - All optional variables guarded
#
# Example:
#   bash zsh/tools/emergency-widget-count.sh
#   bash zsh/tools/emergency-widget-count.sh --json
#
set -euo pipefail

# ---------------- Configuration ----------------
ZSH_BIN="${EMERGENCY_ZSH_BIN:-$(command -v zsh 2>/dev/null || echo /bin/zsh)}"
EMERGENCY_RC="${EMERGENCY_ZSHRC_PATH:-.zshrc.emergency}"

JSON=0
QUIET=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--json] [--quiet]

Obtain emergency ZLE widget count via PTY to ensure line editor initializes.

Options:
  --json    Emit JSON object instead of plain integer
  --quiet   Suppress non-JSON diagnostics on stderr
  --help    Show this help

Environment Overrides:
  EMERGENCY_ZSHRC_PATH (.zshrc.emergency by default)
  EMERGENCY_ZSH_BIN    Path to zsh binary (auto-detected)

Exit Codes:
  0 success (even if widgets=0)
  1 usage error
EOF
}

log() {
  (( QUIET == 1 )) && return 0
  [[ $JSON -eq 1 ]] && return 0
  printf '[emergency-widgets] %s\n' "$*" >&2
}

while (( $# )); do
  case "$1" in
    --json) JSON=1 ;;
    --quiet) QUIET=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

# ---------------- Preconditions ----------------
if [[ ! -f "$EMERGENCY_RC" ]]; then
  notes="emergency file not found: $EMERGENCY_RC"
  if (( JSON )); then
    printf '{"status":"error","widgets":0,"method":"none","notes":"%s"}\n' "$notes"
  else
    log "$notes"
    echo 0
  fi
  exit 0
fi

if [[ ! -x "$ZSH_BIN" ]]; then
  notes="zsh binary not executable/found: $ZSH_BIN"
  if (( JSON )); then
    printf '{"status":"error","widgets":0,"method":"none","notes":"%s"}\n' "$notes"
  else
    log "$notes"
    echo 0
  fi
  exit 0
fi

# ---------------- Helpers ----------------
extract_count() {
  # Expects full captured PTY output on stdin
  # Looks for marker region; fallback: last numeric line
  awk '
    /__EMERGENCY_WIDGET_COUNT_START__/ {capture=1; next}
    /__EMERGENCY_WIDGET_COUNT_END__/ {capture=0}
    capture && /^[[:space:]]*[0-9]+[[:space:]]*$/ {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0);
      print $0; found=1
    }
    END {
      if (!found) exit 1
    }
  '
}

# ---------------- Execution Methods ----------------
run_with_script() {
  local tmp
  tmp="$(mktemp)"
  # Use the 'script' utility with -c to execute a single composite command inside a PTY.
  # macOS/bsd script may return non-zero even on success; ignore exit status.
  # Escape emergency rc path for safe single-quoted inclusion.
  local EMERGENCY_RC_ESC
  EMERGENCY_RC_ESC="$(printf '%s' "$EMERGENCY_RC" | sed "s/'/'\\\\''/g")"
  # Composite command:
  #  1. source emergency rc
  #  2. load zle
  #  3. emit start marker
  #  4. print widget count (fallback 0 if zle -la fails)
  #  5. emit end marker
  local cmd="source '$EMERGENCY_RC_ESC' 2>/dev/null; zmodload zsh/zle 2>/dev/null || true; echo __EMERGENCY_WIDGET_COUNT_START__; (zle -la 2>/dev/null || echo 0) | wc -l; echo __EMERGENCY_WIDGET_COUNT_END__"
  script -q /dev/null "$ZSH_BIN" -i -c "$cmd" >"$tmp" 2>&1 || true
  cat "$tmp"
  rm -f "$tmp"
}

run_with_python_pty() {
  python3 - <<'PY'
import os, pty, subprocess, sys, re
cmd = [os.environ.get("ZSH_BIN","zsh"), "-i", "-c",
       "source ${EMERGENCY_RC:-.zshrc.emergency} 2>/dev/null; "
       "zmodload zsh/zle 2>/dev/null || true; "
       "echo __EMERGENCY_WIDGET_COUNT_START__; "
       "zle -la 2>/dev/null | wc -l; "
       "echo __EMERGENCY_WIDGET_COUNT_END__;"]
# Expand environment variable inside Python (avoid shell injection)
cmd = [ c.replace("${EMERGENCY_RC:-.zshrc.emergency}", os.environ.get("EMERGENCY_ZSHRC_PATH",".zshrc.emergency")) for c in cmd ]
master, slave = pty.openpty()
p = subprocess.Popen(cmd, stdin=slave, stdout=slave, stderr=slave, text=True)
os.close(slave)
buf = []
try:
    while True:
        try:
            data = os.read(master, 4096)
            if not data:
                break
            buf.append(data.decode(errors="ignore"))
        except OSError:
            break
finally:
    p.wait()
out = "".join(buf)
sys.stdout.write(out)
PY
}

# ---------------- Orchestrate ----------------
method="none"
raw_output=""
widgets=0
notes=""

if command -v script >/dev/null 2>&1; then
  method="script"
  raw_output="$(run_with_script || true)"
  # Try to extract count using markers
  count="$(printf '%s\n' "$raw_output" | extract_count 2>/dev/null || true)"
  if [[ "$count" =~ ^[0-9]+$ ]] && (( count > 0 )); then
    widgets=$count
  else
    # Fallback: last numeric line
    fallback="$(printf '%s\n' "$raw_output" | grep -Eo '[0-9]+' | tail -1 || true)"
    if [[ "$fallback" =~ ^[0-9]+$ ]]; then
      widgets=$fallback
    else
      notes="failed to parse widget count via script; falling back python"
      method="python-pty-fallback"
    fi
  fi
fi

if [[ "$method" == "python-pty-fallback" || "$method" == "none" ]] && command -v python3 >/dev/null 2>&1; then
  method="python-pty"
  raw_output="$(ZSH_BIN="$ZSH_BIN" EMERGENCY_ZSHRC_PATH="$EMERGENCY_RC" run_with_python_pty || true)"
  count="$(printf '%s\n' "$raw_output" | extract_count 2>/dev/null || true)"
  if [[ "$count" =~ ^[0-9]+$ ]] && (( count > 0 )); then
    widgets=$count
  else
    fallback="$(printf '%s\n' "$raw_output" | grep -Eo '[0-9]+' | tail -1 || true)"
    if [[ "$fallback" =~ ^[0-9]+$ ]]; then
      widgets=$fallback
    else
      notes="${notes:+$notes; }could not extract numeric count"
    fi
  fi
fi

# If still zero, annotate notes (0 may be legitimate if ZLE failed).
if (( widgets == 0 )); then
  notes="${notes:+$notes; }ZLE not initialized in PTY or no widgets registered"
fi

# ---------------- Extended Summary Parsing (from extended emergency mode) -------------
# When ZF_EMERGENCY_EXTEND=1 the emergency config may emit a line like:
#   [EMERGENCY] ::extended_summary widgets=474 core=1 synthetic=0
# Capture and surface these as optional JSON fields (extended_*). This does not
# alter the primary "widgets" value which reflects the PTY-evaluated count.
extended_widgets=""
extended_core=""
extended_synthetic=""
if [[ -n "${raw_output:-}" ]]; then
  extended_line="$(printf '%s\n' "$raw_output" | grep -E '\\[EMERGENCY] ::extended_summary ' | tail -1 || true)"
  if [[ -n "$extended_line" ]]; then
    if [[ "$extended_line" =~ widgets=([0-9]+) ]]; then extended_widgets="${BASH_REMATCH[1]}"; fi
    if [[ "$extended_line" =~ core=([0-9]+) ]]; then extended_core="${BASH_REMATCH[1]}"; fi
    if [[ "$extended_line" =~ synthetic=([0-9]+) ]]; then extended_synthetic="${BASH_REMATCH[1]}"; fi
  fi
fi

# ---------------- Output ----------------
if (( JSON )); then
  esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
  status="ok"
  if [[ "$method" == "none" ]]; then
    status="error"
  fi
  printf '{'
  printf '"status":"%s",' "$status"
  printf '"widgets":%s,' "$widgets"
  printf '"method":"%s",' "$method"
  printf '"notes":"%s"' "$(esc "${notes:-}")"
  if [[ -n "${extended_widgets:-}" ]]; then
    # Emit extended fields only when present
    printf ',"extended_widgets":%s,"extended_core":%s,"extended_synthetic":%s' \
      "${extended_widgets}" "${extended_core:-0}" "${extended_synthetic:-0}"
  fi
  printf '}\n'
else
  # Plain numeric output
  echo "$widgets"
  [[ -n "$notes" ]] && log "$notes"
fi

exit 0
