# ZSH Completion System Preparation - PRE-PLUGIN PHASE
# This file handles BASIC completion initialization BEFORE plugins load
# SPLIT FROM: 090-compinit.zsh (final completion setup moved to post-plugins)

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    echo "# [completion-prep] Basic completion initialization BEFORE plugins" >&2
}

# CRITICAL: Only basic completion setup here - styling/finalization happens AFTER plugins

## [completion-prep.basic-init] - Essential completion initialization
# Initialize completion system early so plugins can add completions
autoload -Uz compinit

# Fast completion cache check - only rebuild if needed
setopt GLOB_COMPLETE
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

## [completion-prep.cache-management] - Optimized completion cache
# Set up completion cache directory
local comp_cache_dir="${ZDOTDIR:-$HOME}/.zsh/cache"
[[ ! -d "$comp_cache_dir" ]] && mkdir -p "$comp_cache_dir"

# Fast compinit with cache optimization
local comp_dump="${ZDOTDIR:-$HOME}/.zcompdump"
local comp_security_check=false

# Check if we need to rebuild completion cache
if [[ "$comp_dump" -nt ~/.zshrc ]] && [[ -s "$comp_dump" ]]; then
    # Cache is newer than zshrc, use fast loading
    compinit -C -d "$comp_dump"
else
    # Rebuild cache with security check
    compinit -d "$comp_dump"
    comp_security_check=true
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [completion-prep] Rebuilt completion cache" >&2
fi

## [completion-prep.basic-options] - Essential completion options only
# Set ONLY the essential completion options that plugins need
setopt AUTO_MENU              # Show completion menu on successive tab press
setopt COMPLETE_ALIASES        # Complete aliases
setopt LIST_PACKED            # Smaller completion lists
setopt LIST_TYPES             # Show file types in completion

## [completion-prep.security] - Completion security setup
# Handle completion security without impacting performance
if [[ "$comp_security_check" == true ]]; then
    # Only run security check when cache was rebuilt
    if command -v compaudit >/dev/null 2>&1; then
        local insecure_dirs
        insecure_dirs=$(compaudit 2>/dev/null)
        if [[ -n "$insecure_dirs" ]]; then
            [[ "$ZSH_DEBUG" == "1" ]] && echo "# [completion-prep] Warning: Insecure completion directories detected" >&2
        fi
    fi
fi

## [completion-prep.bashcompinit] - Bash completion compatibility
# Initialize bash completion compatibility for plugins that need it
if ! command -v bashcompinit >/dev/null 2>&1; then
    autoload -Uz bashcompinit
    bashcompinit 2>/dev/null
fi

## [completion-prep.minimal-zstyle] - Only essential zstyle settings
# Set ONLY the most basic zstyle settings that plugins depend on
# (Full zstyle configuration happens in post-plugins phase)
zstyle ':completion:*' cache-path "$comp_cache_dir"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' rehash true

## [completion-prep.plugin-preparation] - Prepare for plugin completions
# Set up completion system to accept plugin contributions
# Ensure completion system is ready for plugins to add their completions
fpath=("${ZDOTDIR:-$HOME}/.zsh-completions.d" $fpath)

# Create completions directory if it doesn't exist
[[ ! -d "${ZDOTDIR:-$HOME}/.zsh-completions.d" ]] && mkdir -p "${ZDOTDIR:-$HOME}/.zsh-completions.d"

## [completion-prep.performance] - Performance optimization setup
# Set up for optimal completion performance
setopt HASH_LIST_ALL          # Hash entire command path first time
setopt LIST_AMBIGUOUS         # List completions when ambiguous

# Disable expensive features during plugin loading phase
unsetopt MENU_COMPLETE        # Don't select first completion immediately
unsetopt AUTO_LIST            # Don't list completions automatically

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [completion-prep] ✅ Basic completion system prepared for plugin loading" >&2
