# Phase 5 (post-plugin) NVM augmentation module
# Policy: Option B (retain oh-my-zsh nvm plugin, adjust layering late)
# Compliance: functions use zf:: namespace helpers; nounset-safe fallbacks
# Ordering rationale: placed after other tooling (fzf etc) so baseline node/npm
# (e.g., Herd or system install) is visible before any lazy nvm activation.

zf::debug "# [450-nvm-post-augmentation] begin"

# Ensure per-version npm config not overridden globally.
unset NPM_CONFIG_HOME 2>/dev/null || true

# Apply desired OMZ nvm plugin behaviors only if not already set earlier.
if ! zstyle -t ':omz:plugins:nvm' lazy; then
  zstyle ':omz:plugins:nvm' lazy yes
fi
if ! zstyle -t ':omz:plugins:nvm' autoload; then
  zstyle ':omz:plugins:nvm' autoload yes
fi
if ! zstyle -t ':omz:plugins:nvm' silent-autoload; then
  zstyle ':omz:plugins:nvm' silent-autoload yes
fi

# Prefer Herd managed nvm directory if present and either unset or different.
# (Do not force override if user explicitly exported earlier.)
_herd_nvm_dir="${HOME}/Library/Application Support/Herd/config/nvm"
if [[ -d "${_herd_nvm_dir}" ]]; then
  if [[ -z "${NVM_DIR:-}" || "${NVM_DIR}" != "${_herd_nvm_dir}" ]]; then
    export NVM_DIR="${_herd_nvm_dir}"
    zf::debug "# [450-nvm-post-augmentation] using Herd NVM_DIR: ${NVM_DIR}"
  fi
fi

# Report current nvm load state (do not force load here to preserve lazy behavior)
if typeset -f nvm >/dev/null 2>&1; then
  zf::debug "# [450-nvm-post-augmentation] nvm already loaded (function present)"
else
  zf::debug "# [450-nvm-post-augmentation] nvm not yet loaded (lazy expected)"
fi

zf::debug "# [450-nvm-post-augmentation] complete"

# Fallback: if nvm function still missing but NVM_DIR is set and nvm.sh exists, create a minimal lazy loader.
if ! typeset -f nvm >/dev/null 2>&1; then
  if [[ -n ${NVM_DIR:-} && -s "${NVM_DIR}/nvm.sh" ]]; then
    zf::debug "# [450-nvm-post-augmentation] injecting fallback lazy nvm stub"
    nvm() {
      # Load real nvm only once
      unset -f nvm 2>/dev/null || true
      # shellcheck disable=SC1090
      builtin source "${NVM_DIR}/nvm.sh" 2>/dev/null || { echo "# fallback nvm load failed" >&2; return 1; }
      # Load completion if available
      [[ -s "${NVM_DIR}/bash_completion" ]] && builtin source "${NVM_DIR}/bash_completion" 2>/dev/null || true
      command nvm "$@"
    }
  else
    zf::debug "# [450-nvm-post-augmentation] no fallback stub injected (NVM_DIR/nvm.sh not found)"
  fi
fi

# Manual validation (commented):
#   type -t nvm                # should be 'function' only after first use or plugin eager load
#   echo "NVM_DIR=$NVM_DIR"    # should reflect Herd path if available
#   node -v                    # baseline version (Herd/system) prior to lazy load
#   (cd project-with-nvmrc && node -v)  # should switch after lazy activation
