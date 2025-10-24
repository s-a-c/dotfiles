# 070-dev-codeql.zsh — Early PATH for CodeQL CLI
# Phase: pre-plugins (.zshrc.pre-plugins.d.00)
# Purpose: Add CodeQL CLI directory to PATH if present (XDG)
# Dependencies:
#   PRE: 020-xdg-extensions.zsh (XDG vars), 050-segment-management.zsh (zf::path_prepend)
#   POST: none
# Notes:
# - Idempotent and nounset-safe (${VAR:-})
# - Avoids heavy I/O; only checks for directory existence

# CodeQL
local _zf_codeql_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/codeql"
if [[ -d "${_zf_codeql_dir}" ]]; then
  # Prefer framework helper if available; otherwise use a safe fallback
  if typeset -f zf::path_prepend >/dev/null 2>&1; then
    zf::path_prepend "${_zf_codeql_dir}"
  else
    case ":$PATH:" in
    *":${_zf_codeql_dir}:"*) ;;
    *) PATH="${_zf_codeql_dir}:${PATH}" ;;
    esac
  fi
  if typeset -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [dev-systems] CodeQL configured"
  fi
fi

unset _zf_codeql_dir
return 0
