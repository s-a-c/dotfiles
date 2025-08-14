#!/bin/bash
# MCP Environment Setup Script
# Source this script to set up the correct environment for MCP servers

# Add Herd's Node.js to PATH
export PATH="/Users/s-a-c/Library/Application Support/Herd/config/nvm/versions/node/v22.17.0/bin:$PATH"

# Add Herd's bin directory to PATH
export PATH="/Users/s-a-c/Library/Application Support/Herd/bin:$PATH"

# Add uvx to PATH (fix the typo in the original path)
export PATH="/Users/s-a-c/.local/bin:$PATH"

# Add other common paths
export PATH="$PATH:/opt/homebrew/bin"
export PATH="$PATH:/usr/local/bin"

# Prevent duplicate entries in PATH and FPATH
typeset -U PATH path FPATH fpath
export PATH path FPATH fpath

