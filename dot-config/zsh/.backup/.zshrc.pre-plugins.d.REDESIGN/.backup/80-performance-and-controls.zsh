#!/usr/bin/env zsh
# LEGACY STUB: 80-performance-and-controls.zsh (migrated to 220-performance-and-controls.zsh)
return 0
export _LOADED_PERF_CONTROLS_REDESIGN=1

# Use direct zf:: debug calls
zf::debug "[PERF-CONTROLS] Loading performance and controls (v2.0.0)"

# ==============================================================================
# SECTION 1: PERFORMANCE MONITORING INITIALIZATION
# ==============================================================================

# Performance tracking setup
# Use milliseconds if available, otherwise fall back to seconds with 000 suffix
export ZSH_PERF_START_TIME="${ZSH_PERF_START_TIME:-$(date +%s000 2>/dev/null || echo "$(date +%s)000")}"
export ZSH_PERF_LAST_CHECKPOINT="$ZSH_PERF_START_TIME"

# Performance logging configuration
export PERF_SEGMENT_LOG="${PERF_SEGMENT_LOG:-${ZDOTDIR:-$HOME}/logs/perf-segments.log}"
export PERF_SEGMENT_TRACE="${PERF_SEGMENT_TRACE:-0}"

# Create performance log directory
if [[ -n "$PERF_SEGMENT_LOG" ]]; then
    mkdir -p "$(dirname "$PERF_SEGMENT_LOG")" 2>/dev/null || true
fi

# Performance checkpoint function (now using zf:: namespace)
perf_checkpoint() {
    zf::perf_checkpoint "$@"
}

# Initial performance checkpoint
perf_checkpoint "pre-plugin-40-start"

# ==============================================================================
# SECTION 2: AUTOSUGGESTIONS CONTROL
# ==============================================================================

# Autosuggestions configuration
export ZSH_AUTOSUGGEST_MANUAL_REBIND="${ZSH_AUTOSUGGEST_MANUAL_REBIND:-1}"
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="${ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE:-20}"
export ZSH_AUTOSUGGEST_USE_ASYNC="${ZSH_AUTOSUGGEST_USE_ASYNC:-1}"
export ZSH_AUTOSUGGEST_HISTORY_IGNORE="${ZSH_AUTOSUGGEST_HISTORY_IGNORE:-"(cd *|ls *|ll *|la *)"}"

# Autosuggestions performance tuning
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_COMPLETION_IGNORE="git *"

# Dynamic autosuggestions control based on terminal performance
_setup_autosuggest_performance() {
    # Disable autosuggestions for slow terminals or limited environments
    if [[ "${TERM:-}" =~ ^(dumb|emacs|screen\.linux)$ ]]; then
        export ZSH_AUTOSUGGEST_DISABLE=1
        zf::debug "[PERF-CONTROLS] Autosuggestions disabled for terminal: $TERM"
        return
    fi

    # Disable for SSH sessions with high latency (heuristic)
    if [[ -n "${SSH_CLIENT:-}" ]] && [[ "${ZSH_AUTOSUGGEST_SSH_DISABLE:-0}" == "1" ]]; then
        export ZSH_AUTOSUGGEST_DISABLE=1
        zf::debug "[PERF-CONTROLS] Autosuggestions disabled for SSH session"
        return
    fi

    # Enable optimized autosuggestions
    zf::debug "[PERF-CONTROLS] Autosuggestions configured for optimal performance"
}

_setup_autosuggest_performance

# ==============================================================================
# SECTION 3: SHELL PERFORMANCE OPTIMIZATION
# ==============================================================================

# Shell options for performance
setopt AUTO_CD              # cd to directory by typing name
setopt AUTO_PUSHD           # pushd automatically
setopt PUSHD_IGNORE_DUPS    # ignore duplicate directories
setopt PUSHD_MINUS          # use - instead of + for directory stack

# History performance settings
setopt HIST_EXPIRE_DUPS_FIRST   # expire duplicate entries first
setopt HIST_IGNORE_DUPS         # ignore duplicate commands
setopt HIST_IGNORE_ALL_DUPS     # remove older duplicate entries
setopt HIST_IGNORE_SPACE        # ignore commands starting with space
setopt HIST_SAVE_NO_DUPS        # don't save duplicates
setopt HIST_REDUCE_BLANKS       # remove extra blanks
setopt HIST_VERIFY              # verify history expansion

# Performance-oriented shell settings
setopt NO_BEEP              # disable beep on errors
setopt NO_FLOW_CONTROL      # disable flow control (Ctrl-S/Ctrl-Q)
setopt INTERACTIVE_COMMENTS # allow comments in interactive shells

zf::debug "[PERF-CONTROLS] Shell performance options configured"

# ==============================================================================
# SECTION 4: COMPLETION PERFORMANCE OPTIMIZATION
# ==============================================================================

# Completion performance settings
export ZSH_COMPLETION_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$ZSH_COMPLETION_CACHE_DIR" 2>/dev/null || true

# Completion optimization flags
export ZSH_DISABLE_COMPFIX="${ZSH_DISABLE_COMPFIX:-true}"

# Pre-configure completion settings for performance
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$ZSH_COMPLETION_CACHE_DIR"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'

# Reduce completion candidates for performance
zstyle ':completion:*' max-errors 2
zstyle ':completion:*:functions' ignored-patterns '_*'

zf::debug "[PERF-CONTROLS] Completion performance optimization configured"

# ==============================================================================
# SECTION 5: MEMORY AND RESOURCE OPTIMIZATION
# ==============================================================================

# Shell resource limits (conservative defaults)
ulimit -c 0  # Disable core dumps for performance

# Memory optimization
export HISTFILE="${HISTFILE:-${ZDOTDIR:-$HOME}/.zsh_history}"
export HISTSIZE="${HISTSIZE:-50000}"
export SAVEHIST="${SAVEHIST:-50000}"

# Reduce memory usage for large directories
export LS_COLORS="${LS_COLORS:-di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=0;41:sg=0;46:tw=0;42:ow=0;43:}"

zf::debug "[PERF-CONTROLS] Memory and resource optimization applied"

# ==============================================================================
# SECTION 6: PERFORMANCE MONITORING TOOLS
# ==============================================================================

# Performance measurement functions (now using zf:: namespace)
measure_startup_time() {
    zf::perf_measure_startup "$@"
}

# Performance profile function
profile_zsh_startup() {
    local profile_file="${1:-${ZDOTDIR:-$HOME}/zsh-startup-profile.log}"

    echo "Profiling ZSH startup, output: $profile_file"

    # Enable zprof temporarily
    local temp_zprofile="${ZDOTDIR:-$HOME}/.zprofile.temp"
    echo "zmodload zsh/zprof" > "$temp_zprofile"

    # Run profiled shell
    ZDOTDIR="${ZDOTDIR:-$HOME}" zsh -c "source '$temp_zprofile'; source '${ZDOTDIR:-$HOME}/.zshrc'; zprof" > "$profile_file" 2>&1

    # Clean up
    rm -f "$temp_zprofile"

    echo "Profile complete. View with: cat '$profile_file'"
}

# Performance reporting function
perf_report() {
    local current_time
    current_time="$(date +%s000 2>/dev/null || echo "$(date +%s)000")"
    local total_elapsed=0
    if [[ "$current_time" =~ ^[0-9]+$ ]] && [[ "$ZSH_PERF_START_TIME" =~ ^[0-9]+$ ]]; then
        total_elapsed=$((current_time - ZSH_PERF_START_TIME))
    fi

    echo "=== ZSH Performance Report ==="
    echo "Total pre-plugin time: ${total_elapsed}ms"
    echo "Performance log: ${PERF_SEGMENT_LOG:-not enabled}"

    if [[ -f "$PERF_SEGMENT_LOG" ]]; then
        echo "Recent checkpoints:"
        tail -10 "$PERF_SEGMENT_LOG" 2>/dev/null || echo "  (log file not readable)"
    fi

    # System performance indicators
    echo "System load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Shell level: $SHLVL"
    echo "Terminal: ${TERM:-unknown}"
}

# ==============================================================================
# SECTION 7: FEATURE TOGGLES AND CONTROLS
# ==============================================================================

# Feature toggle system (now using zf:: namespace)
toggle_feature() {
    zf::perf_feature_toggle "$@"
}

# ==============================================================================
# SECTION 8: PRE-PLUGIN FINALIZATION
# ==============================================================================

# Final pre-plugin checkpoint
perf_checkpoint "pre-plugin-40-complete"

# Pre-plugin summary
_pre_plugin_summary() {
    if [[ "${ZSH_DEBUG:-0}" == "1" ]]; then
        local current_time
        current_time="$(date +%s000 2>/dev/null || echo "$(date +%s)000")"
        local total_elapsed=0
        if [[ "$current_time" =~ ^[0-9]+$ ]] && [[ "$ZSH_PERF_START_TIME" =~ ^[0-9]+$ ]]; then
            total_elapsed=$((current_time - ZSH_PERF_START_TIME))
        fi

        echo "=== Pre-Plugin Phase Complete ==="
        echo "Total time: ${total_elapsed}ms"
        echo "Features configured:"
        echo "  - Path safety and normalization"
        echo "  - Environment setup and toggles"
        echo "  - FZF initialization"
        echo "  - Lazy loading framework"
        echo "  - Node.js runtime environment"
        echo "  - macOS integration"
        echo "  - Development tool integrations"
        echo "  - SSH agent and security"
        echo "  - Performance monitoring and controls"
        echo "=== Ready for Plugin Loading ==="
    fi
}

# Display summary if in debug mode
_pre_plugin_summary

# ==============================================================================
# MODULE COMPLETION
# ==============================================================================

export PERF_CONTROLS_VERSION="2.0.0"
export PERF_CONTROLS_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"
export PRE_PLUGIN_PHASE_COMPLETE=1

zf::debug "[PERF-CONTROLS] Performance and controls ready - pre-plugin phase complete"

# Final checkpoint before plugins
perf_checkpoint "pre-plugin-phase-complete"

# Legacy functions removed - using zf:: namespace directly
unset -f _setup_autosuggest_performance _pre_plugin_summary

# ==============================================================================
# END OF PERFORMANCE AND CONTROLS MODULE
# ==============================================================================
