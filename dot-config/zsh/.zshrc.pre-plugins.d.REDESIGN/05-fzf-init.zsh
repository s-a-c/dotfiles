#!/opt/homebrew/bin/zsh
# 05-fzf-init.zsh (Pre-Plugin Redesign Enhanced)
[[ -n ${_LOADED_05_FZF_INIT:-} ]] && return
_LOADED_05_FZF_INIT=1
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE: Lightweight FZF environment + key bindings (NO compinit, NO heavy plugin sourcing).
# GUARANTEE: This module MUST NOT invoke compinit, modify completion dump, or source large plugin frameworks.
# TEST HOOK: test-fzf-no-compinit.zsh asserts absence of compinit side-effects.
#
# Sentinel: block if any variable indicates compinit already ran (defensive)
if [[ -n ${_COMPINIT_DONE:-} ]]; then
    zsh_debug_echo "# [pre-plugin][fzf] WARNING: compinit sentinel detected early; investigate ordering"
fi
if typeset -f compinit >/dev/null 2>&1; then
    zsh_debug_echo "# [pre-plugin][fzf] NOTE: compinit function present but not executed here"
fi
if [[ -n ${ZSH_COMPINIT_RAN:-} ]]; then
    zsh_debug_echo "# [pre-plugin][fzf] WARNING: ZSH_COMPINIT_RAN set unexpectedly"
fi
: ${FZF_NO_COMPINIT_GUARD:=1}
export FZF_NO_COMPINIT_GUARD
#
if command -v fzf >/dev/null 2>&1; then
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
    # Basic key-binding registration (defer heavy extras until post-plugin if needed)
    if [[ -f "${HOME}/.fzf/shell/key-bindings.zsh" ]]; then
        # key-bindings.zsh from fzf does not run compinit; safe to source
        source "${HOME}/.fzf/shell/key-bindings.zsh"
    fi
fi
zsh_debug_echo "# [pre-plugin] 05-fzf-init loaded (no-compinit)"
