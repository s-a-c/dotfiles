#!/usr/bin/env zsh
# Filename: 200-perf-core.zsh
# Purpose:  Performance and async utilities - Load early for other plugins to use
# Phase:    Plugin activation (.zshrc.add-plugins.d/)

zf::add_segment "perf-core" "start"
zf::debug "# [perf-core] Loading performance utilities..."

# Only proceed if the zgenom *function* exists (ensures bootstrap actually happened)
if typeset -f zgenom >/dev/null 2>&1; then
  zgenom load mroth/evalcache || zf::debug "# [perf-core] evalcache load failed (non-fatal)"
  zgenom load mafredri/zsh-async || zf::debug "# [perf-core] zsh-async load failed (non-fatal)"
  zgenom load romkatv/zsh-defer || zf::debug "# [perf-core] zsh-defer load failed (non-fatal)"
else
  zf::debug "# [perf-core] zgenom function absent; skipping performance plugin loads"
fi

zf::debug "# [perf-core] Performance utilities loaded"
zf::add_segment "perf-core" "end"

return 0
