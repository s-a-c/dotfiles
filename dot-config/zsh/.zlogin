#!/usr/bin/env zsh

# vim: ft=zsh
# -*- mode: sh; sh-shell: zsh; -*-

# Serena MCP autostart for login shells
# To disable, set SERENA_MCP_AUTOSTART=0 in your ~/.zshenv or environment
serena_autostart_mcp() {
  # Treat this function as "namespaced" via the serena_ prefix
  # Guard variable: default enabled (1)
  local guard="${SERENA_MCP_AUTOSTART-1}"
  [[ "$guard" = 1 ]] || return 0

  # Only proceed if uvx is available
  command -v uvx >/dev/null 2>&1 || return 0

  # Prevent duplicate servers for the current user across multiple login shells
  if pgrep -u "$EUID" -f 'serena start-mcp-server' >/dev/null 2>&1; then
    return 0
  fi

  # Start in background, disown immediately, and detach from terminal
  # Output fully suppressed
  nohup uvx --from git+https://github.com/oraios/serena \
    serena start-mcp-server >/dev/null 2>&1 &!
}

# Invoke on login
serena_autostart_mcp
