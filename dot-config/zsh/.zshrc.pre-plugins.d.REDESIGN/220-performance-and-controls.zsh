#!/usr/bin/env zsh
# 220-PERFORMANCE-AND-CONTROLS.ZSH - Inlined (was sourcing 80-performance-and-controls.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
if [[ -n ${_LOADED_PERF_CONTROLS_REDESIGN:-} ]]; then return 0; fi
export _LOADED_PERF_CONTROLS_REDESIGN=1
export ZSH_PERF_START_TIME="${ZSH_PERF_START_TIME:-$(date +%s000 2>/dev/null || echo $(date +%s)000)}"
export ZSH_PERF_LAST_CHECKPOINT="$ZSH_PERF_START_TIME"
export PERF_SEGMENT_LOG="${PERF_SEGMENT_LOG:-${ZDOTDIR:-$HOME}/logs/perf-segments.log}"
export PERF_SEGMENT_TRACE="${PERF_SEGMENT_TRACE:-0}"
[[ -n $PERF_SEGMENT_LOG ]] && mkdir -p "${PERF_SEGMENT_LOG:h}" 2>/dev/null || true
zf::debug "[PERF-CONTROLS] Loading performance and controls (v2.0.0)"
perf_checkpoint(){ zf::perf_checkpoint "$@"; }
perf_checkpoint pre-plugin-40-start
export ZSH_AUTOSUGGEST_MANUAL_REBIND="${ZSH_AUTOSUGGEST_MANUAL_REBIND:-1}" ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="${ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE:-20}" ZSH_AUTOSUGGEST_USE_ASYNC="${ZSH_AUTOSUGGEST_USE_ASYNC:-1}" ZSH_AUTOSUGGEST_HISTORY_IGNORE="${ZSH_AUTOSUGGEST_HISTORY_IGNORE:-"(cd *|ls *|ll *|la *)"}" ZSH_AUTOSUGGEST_STRATEGY=(history completion) ZSH_AUTOSUGGEST_COMPLETION_IGNORE="git *"
_setup_autosuggest_performance(){ if [[ ${TERM:-} =~ ^(dumb|emacs|screen\.linux)$ ]]; then export ZSH_AUTOSUGGEST_DISABLE=1; zf::debug "[PERF-CONTROLS] Autosuggestions disabled for terminal: $TERM"; return; fi; if [[ -n ${SSH_CLIENT:-} && ${ZSH_AUTOSUGGEST_SSH_DISABLE:-0} == 1 ]]; then export ZSH_AUTOSUGGEST_DISABLE=1; zf::debug "[PERF-CONTROLS] Autosuggestions disabled for SSH session"; return; fi; zf::debug "[PERF-CONTROLS] Autosuggestions configured for optimal performance"; }
_setup_autosuggest_performance
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_MINUS HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS HIST_VERIFY NO_BEEP NO_FLOW_CONTROL INTERACTIVE_COMMENTS
zf::debug "[PERF-CONTROLS] Shell performance options configured"
export ZSH_COMPLETION_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"; mkdir -p "$ZSH_COMPLETION_CACHE_DIR" 2>/dev/null || true; export ZSH_DISABLE_COMPFIX="${ZSH_DISABLE_COMPFIX:-true}"
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$ZSH_COMPLETION_CACHE_DIR"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*' max-errors 2
zstyle ':completion:*:functions' ignored-patterns '_*'
zf::debug "[PERF-CONTROLS] Completion performance optimization configured"
ulimit -c 0
export HISTFILE="${HISTFILE:-${ZDOTDIR:-$HOME}/.zsh_history}" HISTSIZE="${HISTSIZE:-50000}" SAVEHIST="${SAVEHIST:-50000}" LS_COLORS="${LS_COLORS:-di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=0;41:sg=0;46:tw=0;42:ow=0;43:}"
zf::debug "[PERF-CONTROLS] Memory and resource optimization applied"
measure_startup_time(){ zf::perf_measure_startup "$@"; }
profile_zsh_startup(){ local profile_file="${1:-${ZDOTDIR:-$HOME}/zsh-startup-profile.log}" temp_zprofile="${ZDOTDIR:-$HOME}/.zprofile.temp"; echo 'zmodload zsh/zprof' > $temp_zprofile; ZDOTDIR="${ZDOTDIR:-$HOME}" zsh -c "source '$temp_zprofile'; source '${ZDOTDIR:-$HOME}/.zshrc'; zprof" > $profile_file 2>&1; rm -f $temp_zprofile; echo "Profile complete. View with: cat '$profile_file'"; }
perf_report(){ local current_time total_elapsed=0; current_time="$(date +%s000 2>/dev/null || echo $(date +%s)000)"; if [[ $current_time =~ ^[0-9]+$ && $ZSH_PERF_START_TIME =~ ^[0-9]+$ ]]; then total_elapsed=$((current_time - ZSH_PERF_START_TIME)); fi; echo '=== ZSH Performance Report ==='; echo "Total pre-plugin time: ${total_elapsed}ms"; echo "Performance log: ${PERF_SEGMENT_LOG:-not enabled}"; if [[ -f $PERF_SEGMENT_LOG ]]; then echo 'Recent checkpoints:'; tail -10 $PERF_SEGMENT_LOG 2>/dev/null || echo '  (log file not readable)'; fi; echo "System load: $(uptime | awk -F'load average:' '{print $2}')"; echo "Shell level: $SHLVL"; echo "Terminal: ${TERM:-unknown}"; }
toggle_feature(){ zf::perf_feature_toggle "$@"; }
perf_checkpoint pre-plugin-40-complete
_pre_plugin_summary(){ if [[ ${ZSH_DEBUG:-0} == 1 ]]; then local current_time total_elapsed=0; current_time="$(date +%s000 2>/dev/null || echo $(date +%s)000)"; if [[ $current_time =~ ^[0-9]+$ && $ZSH_PERF_START_TIME =~ ^[0-9]+$ ]]; then total_elapsed=$((current_time - ZSH_PERF_START_TIME)); fi; echo '=== Pre-Plugin Phase Complete ==='; echo "Total time: ${total_elapsed}ms"; echo 'Features configured:'; for f in 'Path safety and normalization' 'Environment setup and toggles' 'FZF initialization' 'Lazy loading framework' 'Node.js runtime environment' 'macOS integration' 'Development tool integrations' 'SSH agent and security' 'Performance monitoring and controls'; do echo "  - $f"; done; echo '=== Ready for Plugin Loading ==='; fi }
_pre_plugin_summary
export PERF_CONTROLS_VERSION="2.0.0" PERF_CONTROLS_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo unknown)" PRE_PLUGIN_PHASE_COMPLETE=1
zf::debug "[PERF-CONTROLS] Performance and controls ready - pre-plugin phase complete"
perf_checkpoint pre-plugin-phase-complete
unset -f _setup_autosuggest_performance _pre_plugin_summary
return 0
