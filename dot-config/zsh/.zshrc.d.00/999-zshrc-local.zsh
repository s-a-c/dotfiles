#!/usr/bin/env zsh
# ==============================================================================
# 999-zshrc-local.zsh — Optional final local override hook
# ==============================================================================
# Phase: 5 (post-plugin, last fragment)
# Purpose: If a .zshrc.local exists, source it for machine/user-specific late tweaks.
#          Keep this fragment minimal and idempotent.
# Ordering: 999- prefix ensures execution after other 9xx cleanup/override fragments.
# Notes:
#   - Prefer earlier fragment layers for structured changes:
#       .zshrc.pre-plugins.d.00/*    (early env/path tweaks)
#       .zshrc.add-plugins.d.00/*    (plugin declarations)
#       .zshrc.d.00/*                (post-plugin augmentations)
#   - This file should remain tiny; re-sourcing must be harmless.
#
# Behavior: Silently skips if no local file found.

# Resolve candidate local override path (honor ZDOTDIR; fall back to $HOME)
local _local_rc="${ZDOTDIR:-$HOME}/.zshrc.local"

# Source if present (use builtin to avoid alias/function shadowing)
if [[ -f $_local_rc ]]; then
    # shellcheck disable=SC1090 (dynamic path by design)
    builtin source "$_local_rc"
fi

unset _local_rc
return 0
