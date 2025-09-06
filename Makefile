# Makefile - Developer utilities for pre-commit hygiene, symlink cleanup, and quick checks
#
# Usage examples:
#   make help
#   make precommit-install
#   make precommit-run
#   make precommit-normalize
#   make broken-symlinks-list
#   make broken-symlinks-remove
#
# Variables you can override:
#   PRECOMMIT_CONFIG=dot-config/zsh/zsh-quickstart-kit/.pre-commit-config.yaml
#   SCOPE_DIRS="dot-config/zsh tools tests"

SHELL := /bin/bash

# ---------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------
PRECOMMIT        ?= pre-commit
GIT              ?= git
PRECOMMIT_CONFIG ?= dot-config/zsh/zsh-quickstart-kit/.pre-commit-config.yaml
SCOPE_DIRS       ?= dot-config/zsh tools tests

# Colors
C_RESET := \033[0m
C_BLUE  := \033[1;34m
C_GREEN := \033[1;32m
C_YELL  := \033[1;33m
C_RED   := \033[1;31m

# ---------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------
.PHONY: help
help:
	@echo -e "$(C_BLUE)Available targets$(C_RESET)"
	@echo "  help                       - Show this help"
	@echo "  precommit-install          - Install pre-commit hooks"
	@echo "  precommit-run              - Run scoped pre-commit checks over all files"
	@echo "  precommit-normalize        - Normalize executable bits in scope and ensure EOF newlines, then run scoped hooks"
	@echo "  broken-symlinks-list       - List all broken symlinks in the repository"
	@echo "  broken-symlinks-remove     - Remove all broken symlinks from the repository (git rm)"
	@echo "  perf-update                - Run N=5 fast-harness capture and update variance/governance/perf badges"
	@echo
	@echo -e "$(C_BLUE)Variables$(C_RESET)"
	@echo "  PRECOMMIT_CONFIG=$(PRECOMMIT_CONFIG)"
	@echo "  SCOPE_DIRS=$(SCOPE_DIRS)"

# ---------------------------------------------------------------------
# Pre-commit: install and run (scoped)
# ---------------------------------------------------------------------
.PHONY: precommit-install
precommit-install:
	@set -euo pipefail; \
	if ! command -v $(PRECOMMIT) >/dev/null 2>&1; then \
	  echo -e "$(C_RED)ERROR$(C_RESET): pre-commit is not installed. Install: pipx install pre-commit (or pip/pip3)."; \
	  exit 1; \
	fi; \
	$(PRECOMMIT) install
	@echo -e "$(C_GREEN)pre-commit installed.$(C_RESET)"

.PHONY: precommit-run
precommit-run:
	@set -euo pipefail; \
	if [ ! -f "$(PRECOMMIT_CONFIG)" ]; then \
	  echo -e "$(C_RED)ERROR$(C_RESET): pre-commit config not found at $(PRECOMMIT_CONFIG)"; \
	  exit 1; \
	fi; \
	$(PRECOMMIT) run --all-files -c "$(PRECOMMIT_CONFIG)"

# ---------------------------------------------------------------------
# Normalize executable bits to match shebangs for scoped dirs, fix EOF, then run
# ---------------------------------------------------------------------
.PHONY: precommit-normalize
precommit-normalize:
	@set -euo pipefail; \
	echo -e "$(C_BLUE)[1/3]$(C_RESET) Normalizing executable bits in scope: $(SCOPE_DIRS)"; \
	if [ ! -x "tools/maintenance/normalize-exec-bits.sh" ]; then \
	  echo -e "$(C_RED)ERROR$(C_RESET): tools/maintenance/normalize-exec-bits.sh not found or not executable."; \
	  echo "Create it or ensure it is executable, then re-run this target."; \
	  exit 1; \
	fi; \
	tools/maintenance/normalize-exec-bits.sh $(SCOPE_DIRS); \
	echo -e "$(C_BLUE)[2/3]$(C_RESET) Ensuring newline at EOF (end-of-file-fixer) with scoped config"; \
	$(PRECOMMIT) run end-of-file-fixer -a -c "$(PRECOMMIT_CONFIG)" || true; \
	echo -e "$(C_BLUE)[3/3]$(C_RESET) Running full scoped pre-commit checks"; \
	$(PRECOMMIT) run --all-files -c "$(PRECOMMIT_CONFIG)"; \
	echo -e "$(C_GREEN)Completed normalization and pre-commit run (scoped).$(C_RESET)"

# ---------------------------------------------------------------------
# Broken symlink audit and cleanup (repo-wide)
# ---------------------------------------------------------------------
# Lists broken symlinks anywhere in the repo
.PHONY: broken-symlinks-list
broken-symlinks-list:
	@set -euo pipefail; \
	echo -e "$(C_BLUE)Scanning for broken symlinks (repo-wide)...$(C_RESET)"; \
	find . -type l ! -exec test -e {} \; -print | sort | tee /tmp/broken_symlinks.txt; \
	count=$$(wc -l < /tmp/broken_symlinks.txt | tr -d '[:space:]'); \
	echo -e "$(C_YELL)Broken symlinks count: $${count}$(C_RESET)"; \
	if [ "$${count}" -eq 0 ]; then echo -e "$(C_GREEN)No broken symlinks found.$(C_RESET)"; fi

# Removes (git rm) all broken symlinks found by the list command
.PHONY: broken-symlinks-remove
broken-symlinks-remove:
	@set -euo pipefail; \
	echo -e "$(C_BLUE)Removing broken symlinks via git rm (repo-wide)...$(C_RESET)"; \
	tmpfile="$$(mktemp -t broken_symlinks.XXXXXX)"; \
	find . -type l ! -exec test -e {} \; -print0 > "$$tmpfile"; \
	count="$$(tr -cd '\0' < "$$tmpfile" | wc -c | tr -d '[:space:]')"; \
	if [ "$$count" -eq 0 ]; then \
	  echo -e "$(C_GREEN)No broken symlinks to remove.$(C_RESET)"; \
	  rm -f "$$tmpfile"; \
	  exit 0; \
	fi; \
	xargs -0 $(GIT) rm -f -- < "$$tmpfile"; \
	rm -f "$$tmpfile"; \
	echo -e "$(C_GREEN)Removed $$count broken symlink(s).$(C_RESET)"

# ---------------------------------------------------------------------
# Quality-of-life targets
# ---------------------------------------------------------------------
.PHONY: fmt
fmt:
	@$(MAKE) precommit-normalize

.PHONY: check
check:
	@$(MAKE) precommit-run

# ---------------------------------------------------------------------
# Performance & variance targets
# ---------------------------------------------------------------------
.PHONY: perf-update
perf-update:
	@echo -e "$(C_BLUE)Running N=5 fast-harness capture and updating badges...$(C_RESET)"
	@set -euo pipefail; \
	cd dot-config/zsh; \
	if [ ! -x "tools/perf-capture-multi-simple.zsh" ]; then \
	  echo -e "$(C_RED)ERROR$(C_RESET): tools/perf-capture-multi-simple.zsh not found or not executable"; \
	  exit 1; \
	fi; \
	if [ ! -x "tools/update-variance-and-badges.zsh" ]; then \
	  echo -e "$(C_RED)ERROR$(C_RESET): tools/update-variance-and-badges.zsh not found or not executable"; \
	  exit 1; \
	fi; \
	echo -e "$(C_BLUE)[1/2]$(C_RESET) Capturing N=5 samples with fast harness..."; \
	ZDOTDIR="$(pwd)" tools/perf-capture-multi-simple.zsh --samples 5 --use-fast-harness; \
	echo -e "$(C_BLUE)[2/2]$(C_RESET) Updating variance and badges..."; \
	ZDOTDIR="$(pwd)" tools/update-variance-and-badges.zsh; \
	echo -e "$(C_GREEN)Performance update complete.$(C_RESET)"
