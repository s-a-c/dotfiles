#!/usr/bin/env zsh
# 230-dev-systems.zsh - Systems Languages (Rust + Go) for ZSH REDESIGN v2
# Phase 3C: Rust + Go Environment
# New module for systems programming languages

zf::debug "# [dev-systems] Loading systems programming languages..."

# Rust toolchain (rustup)
: "${CARGO_HOME:=${HOME}/.cargo}"
: "${RUSTUP_HOME:=${HOME}/.rustup}"
if [[ -d "$CARGO_HOME" ]]; then
  case ":$PATH:" in
  *":${CARGO_HOME}/bin:"*) : ;;
  *) export PATH="${CARGO_HOME}/bin:$PATH" ;;
  esac
  zf::debug "# [dev-systems] Rust toolchain available (CARGO_HOME=${CARGO_HOME})"
  # Source cargo environment (adds rustup/env overrides) if present
  if [[ -f "${HOME}/.local/share/cargo/env" ]]; then
    # shellcheck disable=SC1091
    source "${HOME}/.local/share/cargo/env" 2>/dev/null || zf::debug "# [dev-systems] cargo env source failed (non-fatal)"
    zf::debug "# [dev-systems] cargo env sourced"
  fi
fi

# Go toolchain
if command -v go >/dev/null 2>&1; then
  export GOPATH="${HOME}/go"
  if [[ -d "$GOPATH/bin" ]]; then
    case ":$PATH:" in
    *":${GOPATH}/bin:"*) : ;;
    *) export PATH="${GOPATH}/bin:$PATH" ;;
    esac
    zf::debug "# [dev-systems] Go toolchain configured (GOPATH=${GOPATH})"
  fi
fi

# LM Studio CLI (AI tooling)
if [[ -d "${HOME}/.lmstudio/bin" ]]; then
  case ":$PATH:" in
  *":${HOME}/.lmstudio/bin:"*) : ;;
  *) export PATH="${HOME}/.lmstudio/bin:$PATH" ;;
  esac
  zf::debug "# [dev-systems] LM Studio CLI path added"
fi

# Console Ninja utilities
if [[ -d "${HOME}/.console-ninja/.bin" ]]; then
  case ":$PATH:" in
  *":${HOME}/.console-ninja/.bin:"*) : ;;
  *) export PATH="${HOME}/.console-ninja/.bin:$PATH" ;;
  esac
  zf::debug "# [dev-systems] Console Ninja path added"
fi

# LazyCLI utilities
if [[ -d "${HOME}/.lazycli" ]]; then
  case ":$PATH:" in
  *":${HOME}/.lazycli:"*) : ;;
  *) export PATH="${HOME}/.lazycli:$PATH" ;;
  esac
  zf::debug "# [dev-systems] LazyCLI path added"
fi

zf::debug "# [dev-systems] Systems programming languages loaded"

return 0
