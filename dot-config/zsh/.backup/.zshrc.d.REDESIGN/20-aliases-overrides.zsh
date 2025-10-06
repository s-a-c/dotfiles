#!/usr/bin/env zsh
# 20-aliases-overrides.zsh
# Purpose: Override upstream ZQS aliases that can trip set -u due to unescaped $n
# Notes:
# - .zshrc loads ~/.zsh_aliases first, then ~/.zshrc.d/*.zsh, so definitions here win.
# - Keep overrides minimal and focused on safety fixes.

# Fix: 'ips' alias from ZQS uses Perl $1 inside a double-quoted alias string.
# With set -u in effect (transiently during rebuilds), $1 expands in zsh and errors.
# Escape the $ so Perl sees it, not zsh.
alias ips="ifconfig -a | perl -nle'/\d+\.\d+\.\d+\.\d+/ && print \$1'"

