#!/usr/bin/env zsh
# Context-Aware Configuration: Git Repositories
# Automatically loaded when entering Git repository directories

# Set Git project environment
export PROJECT_TYPE="git"

# Get repository information
if command -v git >/dev/null 2>&1; then
  export GIT_REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || zf::debug "unknown")
  export GIT_BRANCH=$(git branch --show-current 2>/dev/null || zf::debug "unknown")
  export GIT_REMOTE_URL=$(git remote get-url origin 2>/dev/null || zf::debug "none")
fi

echo "📁 Git context loaded (repo: ${GIT_REPO_NAME:-unknown}, branch: ${GIT_BRANCH:-unknown})"
