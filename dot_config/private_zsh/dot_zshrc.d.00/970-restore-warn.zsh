# Compliant with AI-GUIDELINES.md v00de7215dd9caf053852e97ca3a7a6aa0c3fcc8a3843f84f16b06fbc5ac93828
# ------------------------------------------------------------------
# Purpose: Restore WARN_CREATE_GLOBAL after vendor/bootstrap phases.
# Context:
# - .zshenv temporarily disabled WARN_CREATE_GLOBAL to avoid noisy
#   warnings while vendored bootstrap code runs in function context.
# - This late-stage fragment re-enables WARN_CREATE_GLOBAL so that
#   your own fragments and interactive work still benefit from
#   leak detection of unintended global variables.

# Only act in interactive shells
if [[ -o interactive ]]; then
  setopt warn_create_global
fi
