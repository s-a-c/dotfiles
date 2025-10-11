# 070-early-node-runtimes.zsh - Early Node/JS Runtime Path Shaping (Phase 5 support)
# Purpose: expose alternative JS toolchain bins (bun, deno, pnpm) BEFORE plugin layer
# so that:
#   * oh-my-zsh nvm plugin lazy-cmd detection (node/npm/pnpm) sees pnpm if installed
#   * user scripts / other early modules can call these runtimes without waiting
#   * baseline node tooling order: (Herd/system) -> early alt runtimes -> post-plugin NVM lazy
# Policy Alignment: no nvm load here; minimal env only; nounset-safe; zf:: helpers when needed.

if [[ -n "${ZF_DISABLE_EARLY_JS:-}" ]]; then
  zf::debug "# [early-node-runtimes] disabled via ZF_DISABLE_EARLY_JS"
  return 0
fi

zf::debug "# [early-node-runtimes] begin"

# Bun
if [[ -z "${BUN_INSTALL:-}" ]]; then
  export BUN_INSTALL="${XDG_DATA_HOME:-${HOME}/.local/share}/bun"
fi
if [[ -d "${BUN_INSTALL}/bin" ]]; then
  zf::path_prepend "${BUN_INSTALL}/bin"
  zf::debug "# [early-node-runtimes] bun path added"
fi

# Deno
if [[ -z "${DENO_INSTALL:-}" ]]; then
  export DENO_INSTALL="${XDG_DATA_HOME:-${HOME}/.local/share}/deno"
fi
if [[ -d "${DENO_INSTALL}/bin" ]]; then
  zf::path_prepend "${DENO_INSTALL}/bin"
  zf::debug "# [early-node-runtimes] deno path added"
fi

# PNPM
if [[ -z "${PNPM_HOME:-}" ]]; then
  export PNPM_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/pnpm"
fi
if [[ -d "${PNPM_HOME}" ]]; then
  zf::path_prepend "${PNPM_HOME}"
  zf::debug "# [early-node-runtimes] pnpm path added"
fi

# Do NOT set or modify NVM_DIR here; ordering reserved for post-plugin augmentation.
# Intentionally no node version manager manipulation at this layer.

zf::debug "# [early-node-runtimes] complete"
