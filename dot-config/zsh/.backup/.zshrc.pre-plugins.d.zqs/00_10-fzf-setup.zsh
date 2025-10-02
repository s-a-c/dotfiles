# Early FZF setup to prevent widget conflicts
# This loads FZF before other plugins to ensure widgets are properly registered

zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"

# Detect FZF installation path
if command -v fzf >/dev/null 2>&1; then
    # Try different common FZF installation paths
    FZF_PATHS=(
        "$(command -v fzf | xargs dirname | xargs dirname)"  # From binary location
        "/opt/homebrew/opt/fzf"      # Homebrew Apple Silicon
        "/usr/local/opt/fzf"         # Homebrew Intel
        "$HOME/.fzf"                 # Manual install
        "/usr/share/fzf"             # System install
    )

    for fzf_path in "${FZF_PATHS[@]}"; do
        if [[ -d "$fzf_path" ]]; then
            export FZF_PATH="$fzf_path"
            break
        fi
    done

    if [[ -n "$FZF_PATH" ]]; then
        # Add FZF to PATH if not already there
        if [[ ! "$PATH" == *${FZF_PATH}/bin* ]]; then
            export PATH="$PATH:${FZF_PATH}/bin"
        fi

        # Store the installation path separately from config path
        export FZF_INSTALL_PATH="$FZF_PATH"

        # Defer FZF shell integration until ZLE is ready to avoid missing-widget binds
        _zqs__fzf_post_init() {
            # Load FZF completion and key bindings (idempotent)
            [[ -f "${FZF_INSTALL_PATH}/shell/completion.zsh" ]] && source "${FZF_INSTALL_PATH}/shell/completion.zsh"
            [[ -f "${FZF_INSTALL_PATH}/shell/key-bindings.zsh" ]] && source "${FZF_INSTALL_PATH}/shell/key-bindings.zsh"

            # Also try the local fzf.zsh if it exists (user-installed)
            [[ -f ~/.local/share/fzf/fzf.zsh ]] && source ~/.local/share/fzf/fzf.zsh

            # Ensure the user-defined completion widget exists if fzf functions are present
            if typeset -f _fzf_completion >/dev/null 2>&1; then
                zle -C fzf-completion complete-word _fzf_completion 2>/dev/null || true
            fi

            # If Tab is bound to fzf-completion but the widget still doesn't exist, restore sane default
            if [[ "$(bindkey '^I' 2>/dev/null | awk '{print $2}')" == "fzf-completion" ]] && [[ -z "${widgets[fzf-completion]:-}" ]]; then
                bindkey '^I' expand-or-complete 2>/dev/null || true
            fi

            # Run only once
            typeset -g _ZQS_FZF_POST_INIT_DONE=1
        }

        # If interactive with ZLE available, run now; otherwise attach to first precmd
        if [[ -o interactive ]]; then
            if [[ -n "${ZLE_VERSION:-}" ]]; then
                _zqs__fzf_post_init 2>/dev/null || true
            else
                autoload -Uz add-zsh-hook 2>/dev/null || true
                if typeset -f add-zsh-hook >/dev/null 2>&1; then
                    add-zsh-hook precmd _zqs__fzf_post_init 2>/dev/null || true
                else
                    typeset -ga precmd_functions
                    precmd_functions+=(_zqs__fzf_post_init)
                fi
            fi
        fi

        # Set FZF_PATH to user home for config files (expected by some integrations)
        export FZF_PATH="$HOME/.fzf"

        zf::debug "# FZF integration loaded from $FZF_INSTALL_PATH, config path: $FZF_PATH"
    else
        zf::debug "# FZF installation path not found"
    fi
else
    zf::debug "# FZF command not found in PATH"
fi
