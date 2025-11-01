# vim: ft=zsh
# -*- mode: sh; sh-shell: zsh; -*-
#!/usr/bin/env zsh
# --- Profile Annotations -----------------------------------------------------
# Edited: 2025-11-01 (PATH fix for path_helper corruption)
# Rationale: Prefer .zprofile for one-time login setup and PATH tweaks.
# - Runs once per login; child shells inherit PATH.
# - Includes directory existence checks and helper fallback (if zf:: helpers unavailable).
# ---------------------------------------------------------------------------

# --- PATH Fix for Login Shells (macOS path_helper corruption) ---
# CRITICAL: macOS /etc/zprofile runs path_helper which reorders PATH, pushing
# system directories (/usr/bin, /bin) behind Cursor/IDE extension directories.
# This breaks command execution during .zshrc startup. Re-establish correct PATH.
# Note: .zshenv.01 also sets PATH (for non-login shells and scripts).
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH}"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
builtin source $HOME/.orbstack/shell/init.zsh 2>/dev/null || :

# PATH tweaks (moved from .zshrc.local) with existence checks and helper fallback
if typeset -f zf::path_prepend >/dev/null 2>&1; then
    [[ -d /opt/homebrew/opt/trash-cli/bin ]] && zf::path_prepend /opt/homebrew/opt/trash-cli/bin
    [[ -d "$HOME/.lmstudio/bin" ]] && zf::path_append "$HOME/.lmstudio/bin"
else
    # Fallback: modify PATH directly if helpers are unavailable
    path_prepend_if_dir() {
        local d="$1"
        [[ -d "$d" ]] || return 0
        case ":$PATH:" in *":$d:"*) ;; *) PATH="${d}${PATH:+:$PATH}" ;; esac
    }
    path_append_if_dir() {
        local d="$1"
        [[ -d "$d" ]] || return 0
        case ":$PATH:" in *":$d:"*) ;; *) PATH="${PATH:+$PATH:}${d}" ;; esac
    }
    path_prepend_if_dir "/opt/homebrew/opt/trash-cli/bin"
    path_append_if_dir "$HOME/.lmstudio/bin"
    unset -f path_prepend_if_dir path_append_if_dir
fi

export PATH
