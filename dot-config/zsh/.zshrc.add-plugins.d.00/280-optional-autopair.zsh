#!/usr/bin/env zsh
# 180-optional-autopair.zsh - Autopair Functionality for ZSH REDESIGN v2
# Phase 7B: Autopair Functionality (Using Standard Plugin)
# Refactored from legacy 010-add-plugins.zsh (lines 37-40) - UPDATED to use standard plugin

zf::debug "# [optional-autopair] Loading autopair functionality..."

# Use well-maintained standard plugin instead of custom ZLE widgets
# This avoids the ZLE corruption issues that custom implementations can cause
if typeset -f zgenom >/dev/null 2>&1; then
	zgenom load hlissner/zsh-autopair || zf::debug "# [optional-autopair] autopair plugin load failed"
else
	zf::debug "# [optional-autopair] zgenom absent; skipping autopair plugin"
fi

zf::debug "# [optional-autopair] Autopair functionality loaded (using hlissner/zsh-autopair)"

return 0
