# Early FZF setup to prevent widget conflicts
# This loads FZF before other plugins to ensure widgets are properly registered

[[ "$ZSH_DEBUG" == "1" ]] && printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2

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
        
        # Load FZF shell integration (completion and key bindings)
        [[ -f "${FZF_PATH}/shell/completion.zsh" ]] && source "${FZF_PATH}/shell/completion.zsh"
        [[ -f "${FZF_PATH}/shell/key-bindings.zsh" ]] && source "${FZF_PATH}/shell/key-bindings.zsh"
        
        # Set FZF_PATH to user home for config files (expected by fzf-zsh-plugin)
        export FZF_PATH="$HOME/.fzf"
        
        # Also try the local fzf.zsh if it exists
        [[ -f ~/.local/share/fzf/fzf.zsh ]] && source ~/.local/share/fzf/fzf.zsh
        
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# FZF integration loaded from $FZF_INSTALL_PATH, config path: $FZF_PATH" >&2
    else
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# FZF installation path not found" >&2
    fi
else
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# FZF command not found in PATH" >&2
fi
