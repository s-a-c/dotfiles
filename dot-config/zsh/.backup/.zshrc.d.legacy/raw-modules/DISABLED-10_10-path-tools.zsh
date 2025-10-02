#!/usr/bin/env zsh
# Tool-Specific PATH Management
# This file adds tool-specific directories to PATH after core system paths are set
# Load time target: <100ms

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
}

# User-specific paths (highest priority after system)
_path_prepend \
    "$HOME/bin" \
    "$HOME/sbin" \
    "$HOME/.local/bin" \
    "$HOME/.local/sbin"

# Development tools paths
_path_prepend \
    "$HOME/.local/share/bob" \
    "$HOME/.turso" \
    "$HOME/.local/share/cargo/bin" \
    "$HOME/.cargo/bin" \
    "$HOME/.local/share/go/bin" \
    "$HOME/.local/share/gem/ruby/3.3.0/bin"

# Configuration and application paths
_path_prepend \
    "$HOME/.config/emacs/bin" \
    "$HOME/.local/share/deno/bin" \
    "$HOME/.config/composer/vendor/bin" \
    "$HOME/.local/share/bun/bin" \
    "$HOME/.pip-apps/bin" \
    "$HOME/.local/share/pnpm" \
    "$HOME/.console-ninja/.bin"

# Herd and Laravel development
if [[ -d "$HOME/Library/Application Support/Herd" ]]; then
    _path_prepend \
        "$HOME/Library/Application Support/Herd/bin" \
        "$HOME/Library/Application Support/Herd"

    # Herd resources
    [[ -d "/Applications/Herd.app/Contents/Resources" ]] && \
        _path_prepend "/Applications/Herd.app/Contents/Resources"
fi

# LM Studio
[[ -d "$HOME/.lmstudio/bin" ]] && _path_prepend "$HOME/.lmstudio/bin"

# FZF
[[ -d "$HOME/.fzf/bin" ]] && _path_prepend "$HOME/.fzf/bin"
[[ -d "$HOME/.local/share/fzf/bin" ]] && _path_prepend "$HOME/.local/share/fzf/bin"

# Carapace completions
[[ -d "$HOME/.config/carapace/bin" ]] && _path_prepend "$HOME/.config/carapace/bin"

# Clean up PATH by removing any invalid directories
path_validate

zf::debug "# [10-tools] Tool paths configured"
