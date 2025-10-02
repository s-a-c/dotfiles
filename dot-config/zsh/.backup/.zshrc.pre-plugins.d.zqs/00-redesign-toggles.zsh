#!/usr/bin/env zsh
# 00-redesign-toggles.zsh - Redesign system integration for ZQS
# Part of the migration to symlinked ZQS .zshrc

# =================================================================================
# === Redesign Toggle Defaults (Set early for test harness compatibility) ===
# =================================================================================

# Redesign toggles are now set in .zshenv - no longer defined here to avoid conflicts

# Early minimal harness short-circuit:
# When ZSH_SKIP_FULL_INIT=1 (set by perf minimal harness) skip remainder of .zshrc
# NOTE: This needs to be implemented in ZQS .zshrc itself, not here
# The logic below is preserved for reference but may not work as expected
# in the extension system since ZQS .zshrc will continue loading after this

if [[ "${ZSH_SKIP_FULL_INIT:-0}" == "1" ]]; then
  zf::debug "# [.zshrc.pre-plugins.d] Redesign integration active, but ZQS will continue loading"
  zf::debug "# [.zshrc.pre-plugins.d] Redesign toggles: PREPLUGIN=${ZSH_ENABLE_PREPLUGIN_REDESIGN}, POSTPLUGIN=${ZSH_ENABLE_POSTPLUGIN_REDESIGN}"
  # NOTE: return 0 won't work here since we're in a sourced file, not the main .zshrc
  # This logic may need to be moved to a ZQS fork or handled differently
fi

zf::debug "# [pre-plugin-ext] Redesign toggles loaded: PREPLUGIN=${ZSH_ENABLE_PREPLUGIN_REDESIGN}, POSTPLUGIN=${ZSH_ENABLE_POSTPLUGIN_REDESIGN}"
