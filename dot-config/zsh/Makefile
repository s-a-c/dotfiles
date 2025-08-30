# Makefile for zsh helper tasks
# Provides a target to run the zgenom compatibility symlink bootstrap script
#
# Usage examples:
#   make ensure-zgenom-symlink
#   make ensure-zgenom-symlink MODE=repo
#   make ensure-zgenom-symlink ZDOTDIR=~/.config/zsh FORCE=1
#
SHELL := /usr/bin/env bash

# Path to the bootstrap script (relative to repo root)
BIN := $(CURDIR)/bin/ensure-zgenom-symlink.sh

# Defaults (can be overridden on the make command line)
MODE ?= runtime   # runtime | repo
FORCE ?= 0
DRY_RUN ?= 0
ZDOTDIR ?=

.PHONY: help ensure-zgenom-symlink ensure-zgenom-symlink-repo ensure-zgenom-symlink-runtime install baseline

help:
	@printf "zsh Makefile helper\n\n"
	@printf "Targets:\n"
	@printf "  ensure-zgenom-symlink         Run the ensure-zgenom-symlink bootstrap script\n"
	@printf "  ensure-zgenom-symlink-repo    Shortcut: run ensure-zgenom-symlink MODE=repo\n"
	@printf "  ensure-zgenom-symlink-runtime Shortcut: run ensure-zgenom-symlink MODE=runtime\n"
	@printf "  install                       Run the default install steps (currently: ensure-zgenom-symlink)\n\n"
	@printf "Usage examples:\n"
	@printf "  make ensure-zgenom-symlink\n"
	@printf "  make ensure-zgenom-symlink MODE=repo\n"
	@printf "  make ensure-zgenom-symlink ZDOTDIR=~/.config/zsh FORCE=1\n\n"

# Primary: run the bootstrap script. Accepts overrides via MODE, ZDOTDIR, FORCE, DRY_RUN.
ensure-zgenom-symlink:
	@echo "ensure-zgenom-symlink: MODE=$(MODE) ZDOTDIR=$(ZDOTDIR) FORCE=$(FORCE) DRY_RUN=$(DRY_RUN)"
	@if [ ! -x "$(BIN)" ]; then \
		echo "Error: $(BIN) not found or not executable" >&2; \
		exit 1; \
	fi
	@ARGS="" ; \
	if [ "$(MODE)" = "repo" ]; then ARGS="$$ARGS --repo"; elif [ "$(MODE)" = "runtime" ]; then ARGS="$$ARGS --runtime"; fi ; \
	if [ -n "$(ZDOTDIR)" ]; then ARGS="$$ARGS --zdotdir '$(ZDOTDIR)'"; fi ; \
	if [ "$(FORCE)" = "1" ]; then ARGS="$$ARGS --force"; fi ; \
	if [ "$(DRY_RUN)" = "1" ]; then ARGS="$$ARGS --dry-run"; fi ; \
	set -x ; bash "$(BIN)" $$ARGS

# Convenience shortcuts
ensure-zgenom-symlink-repo:
	@$(MAKE) ensure-zgenom-symlink MODE=repo

ensure-zgenom-symlink-runtime:
	@$(MAKE) ensure-zgenom-symlink MODE=runtime

# Default install target: run the symlink creation (runtime mode by default)
install: ensure-zgenom-symlink
	@echo "install complete"

# Baseline: capture performance baseline and regenerate perf badge
baseline:
	@echo "Capturing performance baseline (16 runs, 1 warm discard)" >&2
	@tools/capture-baseline-10run.zsh --quiet --runs 16 || tools/capture-baseline-10run.zsh --runs 16
	@echo "Generating performance badge (5 runs)" >&2
	@tools/generate-perf-badge.zsh 5 || true
	@echo "Baseline + badge complete: docs/redesign/metrics/perf-baseline.json and docs/redesign/badges/perf.json" >&2
