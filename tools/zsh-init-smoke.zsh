#!/usr/bin/env zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v9ab717af287538a58515d2f3369d011f40ef239829ec614afadfc1cc419e5f20
# Sensitive rules:
# - CI configuration: [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md:8)
# - Security & secret handling: [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md:16)
# - Path policy: [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md:23)

set -euo pipefail
emulate -L zsh -o extendedglob -o typeset_silent

# XDG cache configuration for deterministic compdump path
: ${XDG_CACHE_HOME:="$HOME/.cache"}
typeset -g ZSH_COMPDUMP="${XDG_CACHE_HOME}/zsh/.zcompdump"
mkdir -p -- "${ZSH_COMPDUMP:h}"

# Telemetry gates
integer TELE_ON=${ZSH_FEATURE_TELEMETRY:-0}
integer PERF_JSON=${ZSH_PERF_JSON:-0}
typeset -gA ZSH_FEATURE_TIMINGS_SYNC

# Required modules for timing and math; if missing, disable telemetry to remain robust under set -e
if ! zmodload zsh/datetime 2>/dev/null || ! zmodload zsh/mathfunc 2>/dev/null; then
  TELE_ON=0
  PERF_JSON=0
fi

_tel_emit_json() {
  local name=$1 ms=$2
  if (( PERF_JSON == 1 )); then
    # EPOCHREALTIME is float seconds; convert to integer ms epoch
    local ts_ms
    ts_ms=$(( int(EPOCHREALTIME * 1000) ))
    print -r -- "{\"type\":\"feature_timing\",\"name\":\"$name\",\"ms\":$ms,\"phase\":\"init\",\"ts\":$ts_ms}" >> telemetry.log
  fi
}

_feature_time() {
  local name=$1; shift
  if (( TELE_ON != 1 )); then
    "$@"
    return $?
  fi
  local start end ms
  start=$EPOCHREALTIME
  "$@"
  end=$EPOCHREALTIME
  ms=$(( int((end - start) * 1000) ))
  ZSH_FEATURE_TIMINGS_SYNC[$name]=$ms
  _tel_emit_json "$name" "$ms"
}

# Header
print -r -- "[smoke] shell=${ZSH_VERSION:-unknown} interactive=$([[ $- == *i* ]] && print 1 || print 0)"
print -r -- "[smoke] compdump_path=${ZSH_COMPDUMP}"

# Compinit timing & setup (single compdump path)
autoload -Uz compinit
_feature_time compinit compinit -d "${ZSH_COMPDUMP}"

# fpath determinism summary
print -r -- "[smoke] fpath_count=${#fpath}"
for p in "${fpath[@]}"; do
  print -r -- "[smoke] fpath=$p"
done

# Submodule/plugin presence (deterministic listing only, no mutation)
if [[ -d "./dot-config/zsh/zsh-quickstart-kit" ]]; then
  print -r -- "[smoke] zqsk_present=1 path=dot-config/zsh/zsh-quickstart-kit"
else
  print -r -- "[smoke] zqsk_present=0"
fi

# Minimal ZLE mappings (guarded)
zmodload zsh/zle 2>/dev/null || true
local has_zle=0
if zle -l >/dev/null 2>&1; then has_zle=1; fi
local ctrl_r_target alt_c_target
if command -v fzf >/dev/null 2>&1; then ctrl_r_target="fzf-history-widget"; else ctrl_r_target="history-incremental-pattern-search-backward"; fi
if command -v zoxide >/dev/null 2>&1; then alt_c_target="z -I"; else alt_c_target="noop"; fi
print -r -- "[smoke] zle_active=$has_zle"
print -r -- "[smoke] binding.ctrl-R=$ctrl_r_target"
print -r -- "[smoke] binding.Alt-C=$alt_c_target"

# Prompt-ready boundary
print -r -- "[smoke] prompt_ready=1"

# Emit timing summary lines (human readable)
if (( TELE_ON == 1 )); then
  local k
  for k in ${(k)ZSH_FEATURE_TIMINGS_SYNC}; do
    print -r -- "[smoke] timing.$k=${ZSH_FEATURE_TIMINGS_SYNC[$k]}ms"
  done
fi
