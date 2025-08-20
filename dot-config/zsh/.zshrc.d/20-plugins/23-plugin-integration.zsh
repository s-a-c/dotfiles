# Plugin Integration and Configuration - POST-PLUGIN PHASE
# CRITICAL: This file MUST run AFTER plugins are loaded
# Moved from pre-plugins phase to fix 40% failed operations issue

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    echo "# [plugin-integration] Configuring plugins AFTER they are loaded" >&2
}

## [plugin-configurations] - MOVED FROM PRE-PLUGINS TO POST-PLUGINS FOR PROPER TIMING
## These configurations now run AFTER plugins have been loaded and initialized

## [plugins.zsh-abbr.configuration] - Configure zsh-abbr after plugin loads
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.zsh-abbr.configuration]" >&2

    # Performance and behavior settings (now applied after plugin loads)
    export ABBR_DEBUG=0                       # Disable debug output (set to 1 for debugging)
    export ABBR_DRY_RUN=0                     # Disable dry-run mode
    export ABBR_FORCE=0                       # Don't force operations without confirmation
    export ABBR_QUIET=1                       # Enable quiet mode (less verbose output)
    export ABBR_QUIETER=1                     # Enable quieter mode (minimal output)

    # Storage and temporary files
    export ABBR_TMPDIR="${XDG_RUNTIME_DIR:-/tmp}/zsh-abbr"
    mkdir -p "${ABBR_TMPDIR}" 2>/dev/null

    # Advanced configuration
    export ABBR_PRECMD_LOGS=0                 # Disable precmd logging
    export ABBR_SET_EXPANSION_CURSOR=1        # Enable cursor positioning after expansion
    export ABBR_SET_LINE_CURSOR=1             # Set cursor position in line

    # Color output (set NO_COLOR to disable colors)
    unset NO_COLOR
    # Verify abbr plugin is loaded and functional
    if command -v abbr > /dev/null 2>&1; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.zsh-abbr] Plugin loaded and configured successfully" >&2
    elif [[ -f "${ZDOTDIR:-$HOME}/.zgenom/olets/zsh-abbr/v6/zsh-abbr.zsh" ]]; then
        # Plugin files exist but may not be loaded yet - try loading manually
        local abbr_dir="${ZDOTDIR:-$HOME}/.zgenom/olets/zsh-abbr/v6"
        [[ -d "$abbr_dir/completions" ]] && fpath+="$abbr_dir/completions"
        source "$abbr_dir/zsh-abbr.zsh" 2>/dev/null
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.zsh-abbr] Manually loaded plugin" >&2
    else
        echo "⚠️  zsh-abbr plugin not found - configuration may not take effect" >&2
    fi
}

## [plugins.zsh-alias-tips.configuration] - Configure alias tips after plugin loads
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.zsh-alias-tips.configuration]" >&2

    export ZSH_PLUGINS_ALIAS_TIPS_REVEAL=1
    #export ZSH_PLUGINS_ALIAS_TIPS_REVEAL_EXCLUDES=(_ ll vi)
    export ZSH_PLUGINS_ALIAS_TIPS_REVEAL_TEXT="Alias tip: "

    # Verify alias-tips functionality
    if [[ -n "${preexec_functions[(r)_alias_tips_preexec]}" ]]; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.zsh-alias-tips] Plugin configured successfully" >&2
    fi
}

## [plugins.zsh-async.configuration] - Configure async functionality after plugin loads
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.zsh-async.configuration]" >&2

    export ASYNC_PROMPT="async> "

    # Verify async plugin functionality
    if command -v async_init >/dev/null 2>&1; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.zsh-async] Plugin configured successfully" >&2
    fi
}

## [plugins.zsh-autosuggestions.configuration] - Configure autosuggestions after plugin loads
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.zsh-autosuggestions.configuration]" >&2

    # Strategy configuration (now properly applied after plugin loads)
    typeset -ga ZSH_AUTOSUGGEST_STRATEGY
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)

    # Appearance and behavior
    export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585b70"
    export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

    # Performance optimizations
    export ZSH_AUTOSUGGEST_USE_ASYNC=1
    export ZSH_AUTOSUGGEST_MANUAL_REBIND=1

    # Initialize autosuggestions widgets and bindings
    if [[ -n "${widgets[autosuggest-accept]}" ]]; then
        # Check if key bindings are missing and establish them
        if ! bindkey | grep -q "autosuggest-accept"; then
            [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.zsh-autosuggestions] Setting up key bindings" >&2
            
            # Manual key bindings for autosuggestions
            bindkey '^[[C' autosuggest-accept      # Right arrow
            bindkey '^[f' autosuggest-accept       # Alt+f (alternative)
            bindkey '^F' autosuggest-accept        # Ctrl+F (alternative)
            bindkey '^[[1;5C' autosuggest-accept   # Ctrl+Right arrow
            
            # Additional useful bindings
            bindkey '^[^M' autosuggest-execute     # Alt+Enter (execute suggestion)
            bindkey '^[[A' history-substring-search-up    # Up arrow for history search
            bindkey '^[[B' history-substring-search-down  # Down arrow for history search
        fi
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.zsh-autosuggestions] Plugin configured successfully" >&2
    else
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.zsh-autosuggestions] Widget not found, attempting manual initialization" >&2
        # Try to manually start autosuggestions if functions are available
        if type _zsh_autosuggest_start >/dev/null 2>&1; then
            _zsh_autosuggest_start 2>/dev/null
            # Manual bindings after initialization
            bindkey '^[[C' autosuggest-accept 2>/dev/null
        fi
    fi
}

## [plugins.fast-syntax-highlighting.configuration] - Configure syntax highlighting after plugin loads
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.fast-syntax-highlighting.configuration]" >&2

    # Theme and appearance settings
    export FAST_HIGHLIGHT_STYLES[default]="none"
    export FAST_HIGHLIGHT_STYLES[unknown-token]="fg=red,bold"
    export FAST_HIGHLIGHT_STYLES[reserved-word]="fg=yellow"
    export FAST_HIGHLIGHT_STYLES[alias]="fg=green"
    export FAST_HIGHLIGHT_STYLES[builtin]="fg=green"
    export FAST_HIGHLIGHT_STYLES[function]="fg=green"
    export FAST_HIGHLIGHT_STYLES[command]="fg=green"
    export FAST_HIGHLIGHT_STYLES[precommand]="fg=green,underline"
    export FAST_HIGHLIGHT_STYLES[commandseparator]="none"
    export FAST_HIGHLIGHT_STYLES[hashed-command]="fg=green"
    export FAST_HIGHLIGHT_STYLES[path]="fg=magenta"
    export FAST_HIGHLIGHT_STYLES[path_pathseparator]="fg=magenta,bold"
    export FAST_HIGHLIGHT_STYLES[globbing]="fg=blue,bold"
    export FAST_HIGHLIGHT_STYLES[history-expansion]="fg=blue,bold"
    export FAST_HIGHLIGHT_STYLES[single-hyphen-option]="fg=cyan"
    export FAST_HIGHLIGHT_STYLES[double-hyphen-option]="fg=cyan"
    export FAST_HIGHLIGHT_STYLES[back-quoted-argument]="fg=yellow"
    export FAST_HIGHLIGHT_STYLES[single-quoted-argument]="fg=yellow"
    export FAST_HIGHLIGHT_STYLES[double-quoted-argument]="fg=yellow"
    export FAST_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=yellow"
    export FAST_HIGHLIGHT_STYLES[back-or-dollar-double-quoted-argument]="fg=cyan"
    export FAST_HIGHLIGHT_STYLES[back-dollar-quoted-argument]="fg=cyan"
    export FAST_HIGHLIGHT_STYLES[assign]="none"
    export FAST_HIGHLIGHT_STYLES[redirection]="fg=magenta,bold"
    export FAST_HIGHLIGHT_STYLES[comment]="fg=black,bold"

    # Performance settings
    export FAST_HIGHLIGHT[use_async]=1

    # Verify syntax highlighting plugin
    if [[ -n "${_FAST_HIGHLIGHT_VERSION}" ]]; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.fast-syntax-highlighting] Plugin configured successfully" >&2
    fi
}

## [plugins.fzf-tab.configuration] - Configure fzf-tab after plugin loads
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.fzf-tab.configuration]" >&2

    # Disable sort when completing `git checkout`
    zstyle ':fzf-tab:complete:git-checkout:*' sort false

    # Set descriptions format to enable group support
    zstyle ':completion:*:descriptions' format '[%d]'

    # Set list-colors to enable filename colorizing
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

    # Preview directory's content with eza when completing cd
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

    # Switch group using `,` and `.`
    zstyle ':fzf-tab:*' switch-group ',' '.'

    # Verify fzf-tab plugin
    if [[ -n "${fzf_tab_completion_colors}" ]]; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.fzf-tab] Plugin configured successfully" >&2
    fi
}

## [plugins.oh-my-zsh.configuration] - Configure Oh-My-Zsh plugins after they load
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.oh-my-zsh.configuration]" >&2

    # Git plugin configuration
    export GIT_AUTO_FETCH_INTERVAL=1200  # Auto-fetch every 20 minutes

    # Docker plugin configuration
    export DOCKER_HOST="unix:///var/run/docker.sock"

    # Node/NPM plugin configuration
    # CRITICAL: Only set NPM_CONFIG_PREFIX if NVM is not active
    # NVM requires NPM_CONFIG_PREFIX to be unset to function properly
    if [[ -z "${NVM_DIR:-}" ]] || [[ "${NODE_VERSION_MANAGER:-}" != "nvm" ]]; then
        # NVM not detected or not configured, safe to set NPM_CONFIG_PREFIX
        export NPM_CONFIG_PREFIX="$HOME/.local/share/npm"
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.oh-my-zsh] NPM_CONFIG_PREFIX set (NVM not active)" >&2
    else
        # NVM is active, ensure NPM_CONFIG_PREFIX is not set
        unset NPM_CONFIG_PREFIX
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.oh-my-zsh] NPM_CONFIG_PREFIX unset (NVM is active)" >&2
    fi

    # Verify Oh-My-Zsh functionality
    if [[ -n "$ZSH" ]]; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.oh-my-zsh] Plugins configured successfully" >&2
    fi
}

## [plugins.globalias.configuration] - Configure globalias after plugin loads
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.globalias.configuration]" >&2

    # Configure globalias filter values (now properly set after plugin loads)
    typeset -ga GLOBALIAS_FILTER_VALUES
    GLOBALIAS_FILTER_VALUES=("sudo" "man" "which" "where" "type" "command")

    # Verify globalias plugin
    if [[ -n "${widgets[globalias]}" ]]; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugins.globalias] Plugin configured successfully" >&2
    fi
}
## [plugin-health-check] - Verify all critical plugins are loaded and configured
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-health-check] Verifying plugin configuration" >&2

    local failed_plugins=()
    local configured_plugins=()
    local partially_loaded_plugins=()

    # Check zsh-abbr - multiple detection methods
    if command -v abbr > /dev/null 2>&1; then
        configured_plugins+=("zsh-abbr")
    elif [[ -f "${ZDOTDIR:-$HOME}/.zgenom/olets/zsh-abbr/v6/zsh-abbr.zsh" ]]; then
        partially_loaded_plugins+=("zsh-abbr")
    else
        failed_plugins+=("zsh-abbr")
    fi

    # Check zsh-autosuggestions - multiple detection methods
    if [[ -n "${widgets[autosuggest-accept]}" ]]; then
        configured_plugins+=("zsh-autosuggestions")
    elif type _zsh_autosuggest_start > /dev/null 2>&1; then
        partially_loaded_plugins+=("zsh-autosuggestions")
    else
        failed_plugins+=("zsh-autosuggestions")
    fi

    # Check fast-syntax-highlighting - improved detection
    if [[ -n "${_FAST_HIGHLIGHT_VERSION}" ]] || type _fast_highlight > /dev/null 2>&1; then
        configured_plugins+=("fast-syntax-highlighting")
    elif [[ -f "${ZDOTDIR:-$HOME}/.zgenom/zdharma-continuum/fast-syntax-highlighting/___/fast-syntax-highlighting.plugin.zsh" ]]; then
        partially_loaded_plugins+=("fast-syntax-highlighting")
    else
        failed_plugins+=("fast-syntax-highlighting")
    fi

    if [[ ${#configured_plugins[@]} -gt 0 ]]; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-integration] Successfully configured plugins: ${configured_plugins[*]}" >&2
    fi

    if [[ ${#partially_loaded_plugins[@]} -gt 0 ]]; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-integration] Partially loaded plugins: ${partially_loaded_plugins[*]}" >&2
    fi

    # Only show warnings for actually failed plugins
    if [[ ${#failed_plugins[@]} -gt 0 ]]; then
        echo "⚠️  Plugin configuration issues detected: ${failed_plugins[*]}" >&2
        echo "💡 This may be normal if plugins are lazy-loaded or optional" >&2
    fi
}

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-integration] Plugin integration and configuration complete" >&2
