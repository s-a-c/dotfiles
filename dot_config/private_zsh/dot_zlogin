#!/usr/bin/env zsh

# vim: ft=zsh
# -*- mode: sh; sh-shell: zsh; -*-

# Compliant with AI-GUIDELINES.md v09f72e258e7b5a3c2c7e81ff2e0501fee4a5ed8a9d1a9123ad6d2c6e237748d4

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


# Aggregate Homebrew-provided zsh site-functions into a single directory and add it to fpath.
# This helps because /opt/homebrew/share/zsh/site-functions does not include all formula-provided
# completion functions; many live under /opt/homebrew/opt/*/share/zsh/site-functions and some under
# /opt/homebrew/opt/*/libexec/share/zsh/site-functions.
serena_link_homebrew_site_functions() {
  # Guard: enable by default; set SERENA_HB_SITEFUNCS_ENABLE=0 to disable
  local guard="${SERENA_HB_SITEFUNCS_ENABLE-1}"
  [[ "$guard" = 1 ]] || return 0

  # Configuration: destination directory for aggregated links
  # Override with SERENA_HB_SITEFUNCS_DIR if desired
  local hb_prefix="${HOMEBREW_PREFIX-/opt/homebrew}"
  local dst="${SERENA_HB_SITEFUNCS_DIR-${ZDOTDIR-$HOME}/.zsh/site-functions.homebrew}"
  local clean="${SERENA_HB_SITEFUNCS_CLEAN-0}"

  # Prepare destination
  mkdir -p -- "$dst" 2>/dev/null || return 0

  # Optional cleanup of previously linked entries (only those within dst)
  if [[ "$clean" = 1 ]]; then
    # Remove only symlinks we created previously (safe cleanup)
    find "$dst" -type l -maxdepth 1 -print0 2>/dev/null | xargs -0r rm -f --
  else
    # Prune broken links to avoid clutter
    find -L "$dst" -type l -maxdepth 1 -print0 2>/dev/null | xargs -0r rm -f --
  fi

  # Build candidate site-functions directories in strict priority order (fast, shallow):
  # 1) Primary: prefix-level global directory (/opt/homebrew/share/zsh/site-functions)
  # 2) Secondary: per-formula share paths (/opt/homebrew/opt/*/share/zsh/site-functions)
  # 3) Tertiary: per-formula libexec share paths (/opt/homebrew/opt/*/libexec/share/zsh/site-functions)
  local -a src_dirs
  if [[ -d "$hb_prefix/share/zsh/site-functions" ]]; then
    src_dirs+=( "$hb_prefix/share/zsh/site-functions" )
  fi
  src_dirs+=( "$hb_prefix/opt"/*/share/zsh/site-functions(N/) )
  src_dirs+=( "$hb_prefix/opt"/*/libexec/share/zsh/site-functions(N/) )

  # Deduplicate src_dirs while preserving order; robust to set -u
  typeset -A _seen
  local -a uniq_dirs
  local d
  for d in "${src_dirs[@]}"; do
    [[ -d "$d" ]] || continue
    if (( ${+_seen[$d]} == 0 )); then
      _seen[$d]=1
      uniq_dirs+=("$d")
    fi
  done

  # Link unique function files by basename; first directory wins to avoid flipping providers
  typeset -A _linked
  local f name
  for d in "${uniq_dirs[@]}"; do
    for f in "$d"/_*(N); do
      [[ -e "$f" ]] || continue
      name="${f:t}"
      if (( ${+_linked[$name]} == 0 )); then
        ln -sfn -- "$f" "$dst/$name" 2>/dev/null && _linked[$name]=1
      fi
    done
  done

  # Optionally record a timestamp for troubleshooting
  printf '%s\n' "updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >| "$dst/.stamp" 2>/dev/null || true

  return 0
}

# Execute aggregation and add directory to fpath for this login session
serena_link_homebrew_site_functions

{
  local _dst="${SERENA_HB_SITEFUNCS_DIR-${ZDOTDIR-$HOME}/.zsh/site-functions.homebrew}"
  if [[ -d "$_dst" ]]; then
    # Prepend once if not already present
    if (( ${fpath[(Ie)$_dst]} == 0 )); then
      fpath=( "$_dst" $fpath )
    fi
  fi
}
