#!/usr/bin/env zsh
# 100-perf-core.zsh - Core Performance Plugins for ZSH REDESIGN v2
# Phase 2: Performance + Core Plugins
# Refactored from legacy 010-add-plugins.zsh (lines 22-33)
# PRE_PLUGIN_DEPS: none
# POST_PLUGIN_DEPS: none
# RESTART_REQUIRED: no

# Performance and async utilities - Load early for other plugins to use
# These plugins are self-contained and don't require pre/post setup

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
