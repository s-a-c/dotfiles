#!/usr/bin/env zsh
# ==============================================================================
# User Option Overrides - Personal Customization Template
# ==============================================================================
#
# This file is for YOUR personal ZSH option customizations. It loads after
# 400-options.zsh, so any settings here will override the baseline configuration.
#
# As of 2025-10-13, all 50 default options have been consolidated into
# 400-options.zsh. This file is now intentionally minimal to serve as a
# clean slate for user-specific preferences.
#
# --- Quick Start ---
#
# 1. Uncomment any of the examples below, or add your own `setopt`/`unsetopt` commands
# 2. Save this file
# 3. Restart your shell or run: `source ~/.zshrc`
# 4. Verify with: `[[ -o OPTION_NAME ]] && echo "Set" || echo "Unset"`
#
# --- Common Customizations ---
#
# Below are some popular options you might want to enable or disable based on
# your personal workflow preferences.
#
# ==============================================================================

# ==============================================================================
# EXAMPLE 1: Disable Command Spelling Correction
# ==============================================================================
# If you find ZSH's spelling correction intrusive, uncomment this:
#
# unsetopt CORRECT

# ==============================================================================
# EXAMPLE 2: Enable History Expansion with !
# ==============================================================================
# By default, ! is safe (no history expansion). If you want traditional behavior:
#
# setopt BANG_HIST

# ==============================================================================
# EXAMPLE 3: Disable Case-Insensitive Globbing
# ==============================================================================
# If you prefer strict case-sensitive file matching:
#
# unsetopt NO_CASE_GLOB

# ==============================================================================
# EXAMPLE 4: Disable Globbing of Dotfiles
# ==============================================================================
# If you don't want `*` to match hidden files:
#
# unsetopt GLOB_DOTS

# ==============================================================================
# EXAMPLE 5: Enable More Aggressive Correction
# ==============================================================================
# Correct ALL arguments, not just commands (use with caution):
#
# setopt CORRECT_ALL

# ==============================================================================
# EXAMPLE 6: Allow File Overwriting with >
# ==============================================================================
# Disable NO_CLOBBER safety if you want to overwrite files freely:
#
# setopt CLOBBER

# ==============================================================================
# EXAMPLE 7: Disable Exit Confirmation
# ==============================================================================
# If you want Ctrl+D to immediately exit (default shell behavior):
#
# unsetopt IGNORE_EOF

# ==============================================================================
# EXAMPLE 8: Traditional Word Splitting
# ==============================================================================
# Enable Bourne shell word splitting (advanced users only):
#
# setopt SH_WORD_SPLIT

# ==============================================================================
# EXAMPLE 9: Verbose Job Notifications
# ==============================================================================
# If you want even more detail about background jobs:
#
# setopt LONG_LIST_JOBS
# setopt NOTIFY

# ==============================================================================
# EXAMPLE 10: Custom Safety Option
# ==============================================================================
# Require confirmation before executing `rm *` or `rm path/*`:
#
# setopt RM_STAR_WAIT

# ==============================================================================
# ADD YOUR CUSTOM OPTIONS BELOW
# ==============================================================================
#
# This space is reserved for your personal ZSH option preferences.
# Use the format:
#   setopt OPTION_NAME    # Enable an option
#   unsetopt OPTION_NAME  # Disable an option
#
# For a complete list of available options, see:
#   - man zshoptions
#   - http://zsh.sourceforge.net/Doc/Release/Options.html
#   - docs/160-option-files-comparison.md (in this project)
#   - 400-options.zsh (baseline configuration)
#
# ==============================================================================

# Your custom options go here:

# ==============================================================================
# END OF USER OPTIONS
# ==============================================================================
