# Phase 5 (post-plugin) NVM augmentation module with Herd awareness
# Policy: Option B (retain oh-my-zsh nvm plugin, adjust layering late)
# Compliance: functions use zf:: namespace helpers; nounset-safe fallbacks
# Ordering rationale: placed after other tooling so baseline node/npm
# (e.g., Herd or system install) is visible before any lazy nvm activation.

zf::debug "# [530-nvm-post-augmentation] begin"

# Ensure per-version npm config not overridden globally.
unset NPM_CONFIG_HOME 2>/dev/null || true

# Check if NVM was pre-configured by early-node-runtimes.zsh
if [[ -n "${_ZF_NVM_PRESETUP:-}" ]]; then
  zf::debug "# [530-nvm-post-augmentation] NVM pre-setup detected: ${NVM_DIR:-not set}"

  # Validate pre-configured NVM directory
  if [[ -n "${NVM_DIR:-}" && -d "${NVM_DIR}" ]]; then
    if [[ -n "${_ZF_HERD_NVM:-}" ]]; then
      zf::debug "# [530-nvm-post-augmentation] Herd NVM confirmed at: $NVM_DIR"
      # Herd-specific optimizations
      export NVM_NO_ADDITIONAL_PATHS=1
      export NVM_HERD_MODE=1
    else
      zf::debug "# [530-nvm-post-augmentation] Standard NVM confirmed at: $NVM_DIR"
    fi
  else
    zf::debug "# [530-nvm-post-augmentation] Pre-configured NVM_DIR invalid, attempting fallback"
    unset NVM_DIR
  fi
fi

# Fallback NVM detection if pre-setup failed or missing
if [[ -z "${NVM_DIR:-}" ]]; then
  # Prefer Herd managed nvm directory if present
  _herd_nvm_dir="${HOME}/Library/Application Support/Herd/config/nvm"
  if [[ -d "${_herd_nvm_dir}" ]]; then
    export NVM_DIR="${_herd_nvm_dir}"
    export _ZF_HERD_NVM=1
    export NVM_HERD_MODE=1
    zf::debug "# [530-nvm-post-augmentation] Fallback: Using Herd NVM_DIR: ${NVM_DIR}"
  elif [[ -d "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm" ]]; then
    export NVM_DIR="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm"
    export _ZF_HERD_NVM=0
    zf::debug "# [530-nvm-post-augmentation] Fallback: Using Homebrew NVM_DIR: ${NVM_DIR}"
  elif [[ -d "${HOME}/.nvm" ]]; then
    export NVM_DIR="${HOME}/.nvm"
    export _ZF_HERD_NVM=0
    zf::debug "# [530-nvm-post-augmentation] Fallback: Using standard NVM_DIR: ${NVM_DIR}"
  fi
fi

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

# Report current nvm load state (do not force load here to preserve lazy behavior)
if typeset -f nvm >/dev/null 2>&1; then
  zf::debug "# [530-nvm-post-augmentation] nvm already loaded (function present)"
else
  zf::debug "# [530-nvm-post-augmentation] nvm not yet loaded (lazy expected)"
fi

# Fallback: if nvm function still missing but NVM_DIR is set and nvm.sh exists, create an enhanced lazy loader.
if ! typeset -f nvm >/dev/null 2>&1; then
  if [[ -n ${NVM_DIR:-} && -s "${NVM_DIR}/nvm.sh" ]]; then
    zf::debug "# [530-nvm-post-augmentation] injecting enhanced fallback lazy nvm stub"
    nvm() {
      # Remove the lazy loader function
      unset -f nvm 2>/dev/null || true

      # Critical: Unset NPM_CONFIG_PREFIX for NVM compatibility
      unset NPM_CONFIG_PREFIX

      # Source NVM scripts with error handling
      if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        builtin source "$NVM_DIR/nvm.sh" || {
          echo "⚠️  Failed to source NVM from $NVM_DIR" >&2
          return 1
        }
      else
        echo "⚠️  NVM script not found at $NVM_DIR/nvm.sh" >&2
        return 1
      fi

      # Load completion if available
      [[ -s "$NVM_DIR/bash_completion" ]] && builtin source "$NVM_DIR/bash_completion" 2>/dev/null || true

      # Call nvm with original arguments
      command nvm "$@"
    }

    # Set up minimal path for immediate Node.js access (Herd-optimized)
    if [[ -d "$NVM_DIR/versions/node" ]]; then
      local node_dir
      if [[ -n "${_ZF_HERD_NVM:-}" ]]; then
        # Herd: prioritize latest stable version
        node_dir="$(ls -1d "$NVM_DIR"/versions/node/v* 2>/dev/null | sort -V | tail -1)"
      else
        # Standard NVM: use current or latest
        node_dir="$(ls -1d "$NVM_DIR"/versions/node/v* 2>/dev/null | tail -1)"
      fi

      if [[ -d "$node_dir/bin" ]]; then
        export PATH="$node_dir/bin:$PATH"
        zf::debug "# [530-nvm-post-augmentation] Added immediate Node.js access: $node_dir/bin"
      fi
    fi
  else
    zf::debug "# [530-nvm-post-augmentation] no fallback stub injected (NVM_DIR/nvm.sh not found)"
  fi
fi

# Export final status markers
export _ZF_NVM_POST_AUGMENTATION_COMPLETE=1
[[ -n "${_ZF_HERD_NVM:-}" ]] && export _ZF_HERD_FINAL=1

zf::debug "# [530-nvm-post-augmentation] complete - NVM: ${NVM_DIR:-not detected}, Herd: ${_ZF_HERD_NVM:-0}"

# Manual validation (commented):
#   type -t nvm                # should be 'function' only after first use or plugin eager load
#   echo "NVM_DIR=$NVM_DIR"    # should reflect Herd path if available
#   node -v                    # baseline version (Herd/system) prior to lazy load
#   (cd project-with-nvmrc && node -v)  # should switch after lazy activation
