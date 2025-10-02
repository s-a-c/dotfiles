#!/usr/bin/env zsh
# 180-MACOS-INTEGRATION.ZSH - Inlined (was sourcing 60-macos-integration.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}

if [[ -n ${_LOADED_MACOS_INTEGRATION_REDESIGN:-} ]]; then return 0; fi
if [[ "$(uname -s)" != Darwin ]]; then export _LOADED_MACOS_INTEGRATION_REDESIGN="skipped-non-darwin"; return 0; fi
export _LOADED_MACOS_INTEGRATION_REDESIGN=1
zf::debug "[MACOS] Loading macOS integration (v2.0.0)"

MACOS_VERSION_MAJOR="" MACOS_VERSION_MINOR=""
if command -v sw_vers >/dev/null 2>&1; then
	local macos_version; macos_version="$(sw_vers -productVersion 2>/dev/null)"
	if [[ -n $macos_version ]]; then
		MACOS_VERSION_MAJOR="${macos_version%%.*}"
		MACOS_VERSION_MINOR="${macos_version#*.}"; MACOS_VERSION_MINOR="${MACOS_VERSION_MINOR%%.*}"
		export MACOS_VERSION_MAJOR MACOS_VERSION_MINOR
		zf::debug "[MACOS] Detected macOS version: $MACOS_VERSION_MAJOR.$MACOS_VERSION_MINOR"
	fi
fi

if command -v brew >/dev/null 2>&1; then
	if [[ -z ${HOMEBREW_PREFIX:-} ]]; then export HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null)"; zf::debug "[MACOS] Set HOMEBREW_PREFIX: $HOMEBREW_PREFIX"; fi
	export HOMEBREW_NO_ANALYTICS="${HOMEBREW_NO_ANALYTICS:-1}" HOMEBREW_NO_AUTO_UPDATE="${HOMEBREW_NO_AUTO_UPDATE:-1}" HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS="${HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS:-30}"
	if [[ -z ${HOMEBREW_SHELLENV_PREFIX:-} && -x $HOMEBREW_PREFIX/bin/brew ]]; then eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"; export HOMEBREW_SHELLENV_PREFIX="$HOMEBREW_PREFIX"; zf::debug "[MACOS] Loaded Homebrew shell environment"; fi
else
	zf::debug "[MACOS] Homebrew not detected"
fi

local -a macos_paths=(/usr/local/MacGPG2/bin /Library/TeX/texbin /Applications/Postgres.app/Contents/Versions/latest/bin /opt/X11/bin)
for macos_path in "${macos_paths[@]}"; do
	if [[ -d $macos_path && :$PATH: != *:${macos_path}:* ]]; then PATH="$PATH:$macos_path"; export PATH; zf::debug "[MACOS] Added macOS path: $macos_path"; fi
done

if [[ ${MACOS_DEV_SECURITY:-1} == 1 ]]; then export OBJC_DISABLE_INITIALIZE_FORK_SAFETY="${OBJC_DISABLE_INITIALIZE_FORK_SAFETY:-YES}"; zf::debug "[MACOS] Set development security environment"; fi

if xcode-select -p >/dev/null 2>&1; then export XCODE_DEVELOPER_PATH="$(xcode-select -p 2>/dev/null)"; zf::debug "[MACOS] Xcode developer path: $XCODE_DEVELOPER_PATH"; else zf::debug "[MACOS] Xcode command line tools not installed or not configured"; fi

if command -v zf::lazy_register >/dev/null 2>&1; then zf::lazy_register macos-defaults zf::macos_defaults_load; zf::debug "[MACOS] macOS defaults registered (zf::)"; else if command -v lazy_register >/dev/null 2>&1; then _load_macos_defaults(){ zf::macos_defaults_load "$@"; }; lazy_register macos-defaults _load_macos_defaults; zf::debug "[MACOS] macOS defaults registered (legacy)"; else zf::debug "[MACOS] No lazy framework available, skipping deferred defaults"; fi; fi

if command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then export MACOS_CLIPBOARD_AVAILABLE=1; zf::debug "[MACOS] clipboard utilities available"; else zf::debug "[MACOS] clipboard utilities not available"; fi

case ${TERM_PROGRAM:-} in
	Apple_Terminal) export TERMINAL_APP=Terminal; zf::debug "[MACOS] Running in Terminal.app" ;;
	iTerm.app) export TERMINAL_APP=iTerm2; zf::debug "[MACOS] Running in iTerm2"; if [[ -e $HOME/.iterm2_shell_integration.zsh && -z ${ITERM_SHELL_INTEGRATION_INSTALLED:-} ]]; then source "$HOME/.iterm2_shell_integration.zsh"; zf::debug "[MACOS] Loaded iTerm2 shell integration"; fi ;;
	*) export TERMINAL_APP=Other; zf::debug "[MACOS] Running in terminal: ${TERM_PROGRAM:-unknown}" ;;
esac

if [[ ${MACOS_PERFORMANCE_MODE:-1} == 1 ]]; then export CRASHREPORTER_DISABLE_DIALOG="${CRASHREPORTER_DISABLE_DIALOG:-1}"; if [[ ${MACOS_REDUCE_MOTION:-0} == 1 ]]; then defaults write com.apple.universalaccess reduceMotion -bool true 2>/dev/null || true; zf::debug "[MACOS] Enabled reduce motion"; fi; fi

export MACOS_INTEGRATION_VERSION="2.0.0" MACOS_INTEGRATION_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo unknown)"
zf::debug "[MACOS] macOS integration ready"
return 0
