#!/usr/bin/env zsh
# Plugin Integration and Configuration - POST-PLUGIN PHASE
# CRITICAL: This file MUST run AFTER plugins are loaded
# Moved from pre-plugins phase to fix 40% failed operations issue

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zsh_debug_echo "# [plugin-integration] Configuring plugins AFTER they are loaded"
}

## [plugin-configurations] - MOVED FROM PRE-PLUGINS TO POST-PLUGINS FOR PROPER TIMING
## These configurations now run AFTER plugins have been loaded and initialized

## [plugins.zsh-abbr.configuration] - Configure zsh-abbr after plugin loads
{
    zsh_debug_echo "# [plugins.zsh-abbr.configuration]"

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
        zsh_debug_echo "# [plugins.zsh-abbr] Plugin loaded and configured successfully"
    elif [[ -f "${ZDOTDIR:-$HOME}/.zgenom/olets/zsh-abbr/v6/zsh-abbr.zsh" ]]; then
        # Plugin files exist but may not be loaded yet - try loading manually
        local abbr_dir="${ZDOTDIR:-$HOME}/.zgenom/olets/zsh-abbr/v6"
        [[ -d "$abbr_dir/completions" ]] && fpath+="$abbr_dir/completions"
        source "$abbr_dir/zsh-abbr.zsh" 2>/dev/null
        zsh_debug_echo "# [plugins.zsh-abbr] Manually loaded plugin"
    else
        # Only show warning in debug mode since plugin may be loaded later
        zsh_debug_echo "⚠️  zsh-abbr plugin not found during initialization - may be loaded later"
    fi
}

## [plugins.zsh-alias-tips.configuration] - Configure alias tips after plugin loads
{
    zsh_debug_echo "# [plugins.zsh-alias-tips.configuration]"

    export ZSH_PLUGINS_ALIAS_TIPS_REVEAL=1
    #export ZSH_PLUGINS_ALIAS_TIPS_REVEAL_EXCLUDES=(_ ll vi)
    export ZSH_PLUGINS_ALIAS_TIPS_REVEAL_TEXT="Alias tip: "

    # Verify alias-tips functionality
    if [[ -n "${preexec_functions[(r)_alias_tips_preexec]}" ]]; then
        zsh_debug_echo "# [plugins.zsh-alias-tips] Plugin configured successfully"
    fi
}

## [plugins.zsh-async.configuration] - Configure async functionality after plugin loads
{
    zsh_debug_echo "# [plugins.zsh-async.configuration]"

    export ASYNC_PROMPT="async> "

    # Verify async plugin functionality
    if command -v async_init >/dev/null 2>&1; then
        zsh_debug_echo "# [plugins.zsh-async] Plugin configured successfully"
    fi
}

## [plugins.zsh-autosuggestions.configuration] - Configure autosuggestions after plugin loads
{
    zsh_debug_echo "# [plugins.zsh-autosuggestions.configuration]"

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
        # Use zsh-native pattern matching instead of grep
        local bindkey_output
        bindkey_output="$(bindkey 2>/dev/null || true)"
        if [[ "$bindkey_output" != *"autosuggest-accept"* ]]; then
            zsh_debug_echo "# [plugins.zsh-autosuggestions] Setting up key bindings"

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
        zsh_debug_echo "# [plugins.zsh-autosuggestions] Plugin configured successfully"
    else
        zsh_debug_echo "# [plugins.zsh-autosuggestions] Widget not found, attempting manual initialization"
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
    zsh_debug_echo "# [plugins.fast-syntax-highlighting.configuration]"

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
        zsh_debug_echo "# [plugins.fast-syntax-highlighting] Plugin configured successfully"
    fi
}

## [plugins.fzf-tab.configuration] - Configure fzf-tab after plugin loads
{
    zsh_debug_echo "# [plugins.fzf-tab.configuration]"

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
        zsh_debug_echo "# [plugins.fzf-tab] Plugin configured successfully"
    fi
}

## [plugins.oh-my-zsh.configuration] - Configure Oh-My-Zsh plugins after they load
{
    zsh_debug_echo "# [plugins.oh-my-zsh.configuration]"

    # Git plugin configuration
    export GIT_AUTO_FETCH_INTERVAL=1200  # Auto-fetch every 20 minutes

    # Docker plugin configuration
    export DOCKER_HOST="unix:///var/run/docker.sock"

    # Node/NPM plugin configuration
    # CRITICAL: Ensure NPM_CONFIG_PREFIX stays unset when NVM is active
    # Some plugins/tools may set NPM_CONFIG_PREFIX after our pre-plugin phase
    if [[ -n "${NVM_DIR:-}" ]] || [[ -f "$HOME/.nvm/nvm.sh" ]] || [[ -f "/usr/local/opt/nvm/nvm.sh" ]] || [[ -f "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
        # NVM is active - ensure NPM_CONFIG_PREFIX remains unset for compatibility
        if [[ -n "$NPM_CONFIG_PREFIX" ]]; then
            zsh_debug_echo "# [plugins.oh-my-zsh] Unsetting NPM_CONFIG_PREFIX (was: $NPM_CONFIG_PREFIX) for NVM compatibility"
            unset NPM_CONFIG_PREFIX
        fi
        zsh_debug_echo "# [plugins.oh-my-zsh] NPM_CONFIG_PREFIX kept unset for NVM compatibility"
    else
        # No NVM detected - safe to have NPM_CONFIG_PREFIX set
        if [[ -z "$NPM_CONFIG_PREFIX" ]]; then
            export NPM_CONFIG_PREFIX="$HOME/.local/share/npm"
            zsh_debug_echo "# [plugins.oh-my-zsh] NPM_CONFIG_PREFIX set to $NPM_CONFIG_PREFIX (no NVM)"
        fi
    fi

    # Verify Oh-My-Zsh functionality
    if [[ -n "$ZSH" ]]; then
        zsh_debug_echo "# [plugins.oh-my-zsh] Plugins configured successfully"
    fi
}

## [plugins.globalias.configuration] - Configure globalias after plugin loads
{
    zsh_debug_echo "# [plugins.globalias.configuration]"

    # Configure globalias filter values (now properly set after plugin loads)
    typeset -ga GLOBALIAS_FILTER_VALUES
    GLOBALIAS_FILTER_VALUES=("sudo" "man" "which" "where" "type" "command")

    # Verify globalias plugin
    if [[ -n "${widgets[globalias]}" ]]; then
        zsh_debug_echo "# [plugins.globalias] Plugin configured successfully"
    fi
}
## [plugin-health-check] - Verify all critical plugins are loaded and configured
{
    zsh_debug_echo "# [plugin-health-check] Verifying plugin configuration"

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
        zsh_debug_echo "# [plugin-integration] Successfully configured plugins: ${configured_plugins[*]}"
    fi

    if [[ ${#partially_loaded_plugins[@]} -gt 0 ]]; then
        zsh_debug_echo "# [plugin-integration] Partially loaded plugins: ${partially_loaded_plugins[*]}"
    fi

    # Only show warnings for actually failed plugins
    if [[ ${#failed_plugins[@]} -gt 0 ]]; then
        zsh_debug_echo "⚠️  Plugin configuration issues detected: ${failed_plugins[*]}"
        zsh_debug_echo "💡 This may be normal if plugins are lazy-loaded or optional"
    fi
}

zsh_debug_echo "# [plugin-integration] Plugin integration and configuration complete"
