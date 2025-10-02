#!/usr/bin/env bash
set -Eeuo pipefail
source "./.bash-harness-for-zsh-template.bash"
echo "[selftest] probe_startup"
harness::probe_startup
echo "[selftest] env var set check"
harness::check_env_var_set "ZDOTDIR"
echo "[selftest] OK"