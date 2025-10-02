#!/usr/bin/env bash
set -euo pipefail

# Automated, interactive bisect of zsh startup hang/loop
# - Runs four staged interactive shells with different plugin toggles
# - Regenerates zgenom cache between stages
# - You manually exercise the prompt/widgets, then exit to continue
#
# Steps
# 1) OMZ core only (no OMZ plugins, no extra plugins)
# 2) OMZ minimal plugins (no extra), using --regen-only
# 3) OMZ minimal + extra plugins
# 4) Full OMZ + extra plugins

# Resolve ZDOTDIR to this repo's zsh config directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZDOTDIR="${SCRIPT_DIR%/bin}"
export ZDOTDIR
cd "$ZDOTDIR"

say() { printf "\n[%s] %s\n" "bisect" "$*"; }
pause() { read -r -p "Press Enter to continue..." _; }

regen_cache() {
  rm -f "$ZDOTDIR/.zqs-zgenom/init.zsh"
}

run_interactive() {
  # Run a real interactive zsh, return when user exits
  env "$@" zsh -i || true
}

checklist() {
  cat <<'EOF'
What to check in this session:
- Prompt responsiveness (no loop/hang)
- Try: up/down history substring search
- Try: edit-command-line, sudo-command-line (if present)
- Try: fzf widgets (Ctrl-T, Alt-C), file/history widgets
- Observe: any "unhandled ZLE widget" messages (should not persist after regen)
When done, exit this shell to continue.
EOF
}

say "ZDOTDIR=$ZDOTDIR"

# 1) OMZ core only (no OMZ plugins, no extra)
say "Step 1: OMZ core only (no OMZ plugins, no extra plugins)"
regen_cache
say "Launching interactive shell..."
checklist
run_interactive ZSH_DISABLE_EXTRA_PLUGINS=1 ZSH_DISABLE_OMZ_PLUGINS=1

# 2) OMZ minimal plugins (no extra), using --regen-only
say "Step 2: OMZ minimal only (no extra), using --regen-only"
regen_cache
# Regenerate with minimal flags via --regen-only
zsh -c 'source ~/.zgen-setup --regen-only; load-starter-plugin-list' || true
say "Launching interactive shell..."
checklist
run_interactive

# 3) OMZ minimal + extra plugins
say "Step 3: OMZ minimal + extra plugins"
regen_cache
say "Launching interactive shell..."
checklist
run_interactive ZSH_OMZ_MINIMAL=1

# 4) Full OMZ + extra plugins
say "Step 4: Full OMZ + extra plugins"
regen_cache
say "Launching interactive shell..."
checklist
run_interactive

say "All steps completed. If a hang/loop occurred, note the first step where it appeared."

