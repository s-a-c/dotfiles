#!/usr/bin/env bash
#
# Script to install git hooks for the zsh dotfiles directory
# This installs a pre-commit hook that prevents modifications to vendored files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="${SCRIPT_DIR}/../.git/hooks"
PRE_COMMIT_SOURCE="${SCRIPT_DIR}/pre-commit-hook"
PRE_COMMIT_TARGET="${HOOKS_DIR}/pre-commit"

echo -e "${BLUE}=== Installing Git Hooks for ZSH Configuration ===${NC}"

# Check if we're in the right repository structure
if [ ! -f "${PRE_COMMIT_SOURCE}" ]; then
  echo -e "${RED}ERROR: Could not find pre-commit-hook at ${PRE_COMMIT_SOURCE}${NC}"
  echo -e "${RED}Make sure you're running this script from the tools directory${NC}"
  exit 1
fi

# Ensure hooks directory exists
if [ ! -d "${HOOKS_DIR}" ]; then
  echo -e "${YELLOW}Creating hooks directory at ${HOOKS_DIR}${NC}"
  mkdir -p "${HOOKS_DIR}"
fi

# Install pre-commit hook
echo -e "${YELLOW}Installing pre-commit hook...${NC}"
cp "${PRE_COMMIT_SOURCE}" "${PRE_COMMIT_TARGET}"
chmod +x "${PRE_COMMIT_TARGET}"

# Verify installation
if [ -x "${PRE_COMMIT_TARGET}" ]; then
  echo -e "${GREEN}Pre-commit hook successfully installed!${NC}"
  echo -e "${BLUE}This hook will prevent committing changes to vendored files like:${NC}"
  echo -e "${YELLOW}- The zsh-quickstart-kit directory${NC}"
  echo -e "${YELLOW}- The .zshrc symlink${NC}"
  echo -e ""
  echo -e "${BLUE}Remember:${NC}"
  echo -e "1. Always keep .zshrc as a symlink to zsh-quickstart-kit/zsh/.zshrc"
  echo -e "2. Add customizations to .zshrc.d/ or .zshrc.pre-plugins.d/"
  echo -e "3. See VENDORED.md for complete policy details"
else
  echo -e "${RED}Failed to install pre-commit hook!${NC}"
  exit 1
fi

echo -e "${GREEN}=== Hook Installation Complete ===${NC}"
