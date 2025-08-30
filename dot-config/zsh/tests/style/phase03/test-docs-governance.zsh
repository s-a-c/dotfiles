#!/usr/bin/env zsh
# test-docs-governance.zsh
# Purpose: Enforce presence of navigation footer & required tokens across redesign docs.
# Fails if docs-governance-lint reports violations.
set -euo pipefail
SCRIPT_DIR=${0:A:h:h:h:h}/tools

if [[ ! -x $SCRIPT_DIR/docs-governance-lint.zsh ]]; then
    echo "SKIP docs-governance-lint script missing" >&2
    exit 0
fi

$SCRIPT_DIR/docs-governance-lint.zsh --check >/dev/null

echo "PASS docs governance"
