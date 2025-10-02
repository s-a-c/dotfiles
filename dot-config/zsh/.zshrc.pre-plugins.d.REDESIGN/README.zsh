# README (Pre-Plugins REDESIGN Layer)
# ==================================
#
# This file documents the REDESIGN pre-plugin startup layer. It is *safe to source*
# because every line is commented. Treat it both as human-readable markdown and
# machine-ignorable commentary.
#
# 1. PURPOSE
# ----------
# Establish a deterministic, nounset-safe, alias-resistant, and performance-aware
# foundation *before* any plugin manager (zgenom) or user plugins execute.
#
# Goals:
# - Normalize PATH & environment (idempotent + corruption repair)
# - Enforce early shell safety (nounset handling, debug policy, grep neutrality)
# - Seed critical prompt/starship state to prevent intermittent parameter errors
# - Initialize keymaps/ZLE primitives before widget-mutating plugins load
# - Stage optional diagnostic hooks (grep tracer, performance counters) behind
#   explicit env toggles (e.g., ZSH_DEBUG=1)
# - Defer higher-level integrations to the post-plugin stage to keep early path fast
#
# 2. ORDERING RULES (000,010,020,... MULTIPLES OF 10)
# --------------------------------------------------
# Files use a three-digit multiple-of-10 numeric prefix. Rationale:
# - Predictable gaps: new concerns can be inserted without renumbering existing files.
# - Visual scan groups related concerns (environment first → prompt seeding → UI → tooling).
# - Encourages cohesive, minimal modules (avoid monolith reload risk).
#
# Suggested canonical order (planned / in-progress):
#   000-path-safety.zsh              # PATH baseline + corruption mitigation
#   010-shell-safety-nounset.zsh     # Core setopt/unsetopt, debug policy hooks
#   020-grep-core-prelude.zsh        # Hard neutralize any pre-existing grep alias
#   030-grep-safe-shim.zsh           # Safe grep wrapper (zf::safe_grep, bracket guard)
#   040-grep-debug-tracer.zsh        # (Conditional) pattern tracer when ZSH_DEBUG=1
#   050-zgen-reset.zsh               # Clear stale zgen/zgenom init artifacts
#   060-ensure-zgenom-symlink.zsh    # Guarantee expected zgenom symlink structure
#   070-environment-base.zsh         # Baseline vars, locale, minimal exports
#   080-starship-universal-seed.zsh  # Unified STARSHIP_* variable seeding (all scalars/arrays)
#   090-keymap-early-vars.zsh        # Keymap mode, widget arrays, safe options for ZLE
#   100-zle-initialization.zsh       # ZLE early boot (no compinit yet) & widget readiness
#   110-fzf-initialization.zsh       # fzf path & env (kept lean, defers heavy config)
#   120-fsh-sanitize.zsh             # Fast-syntax-highlighting pre-sanitization guards
#   130-simple-autopair.zsh          # Lightweight autopair (early; no plugin deps)
#   140-lazy-framework-loader.zsh    # Flags and sentinels for deferred frameworks
#   150-node-runtime-env.zsh         # Node version / NVM env scaffolding (non-lazy bits)
#   160-node-runtime.zsh             # Deferred or conditional heavier node activation
#   170-macos-defaults-deferred.zsh  # MacOS tweaks prepared (execution gated)
#   180-macos-integration.zsh        # MacOS platform detection & env adaptors
#   190-development-integrations.zsh # Core dev tools (git extras, etc.)
#   200-lazy-integrations.zsh        # Secondary opt-in integrations (loaded by sentinel)
#   210-ssh-agent.zsh                # SSH agent bootstrap (safe restore > start new)
#   220-ssh-and-security.zsh         # Audit & security hardening helpers
#   230-performance-and-controls.zsh # Perf counters, toggles, instrumentation
#   240-warp-compat.zsh              # Warp / terminal compatibility adjustments
#   250-reserved-slot.zsh            # Always-empty placeholder for hotfix insertion
#
# 3. NAMING CONVENTIONS
# ---------------------
# - Prefix: three digits + dash.
# - Action-oriented nouns (e.g., *-seed*, *-initialization*, *-sanitize*).
# - Multi-word components joined by hyphen (avoid underscores for filenames).
# - One cohesive concern per file—if adding second major concern, create a new numbered file.
# - Guards follow pattern: _LOADED_<UPPER_IDENTIFIER>=1 (or exported if needed downstream).
#
# 4. STARSHIP VARIABLE SEEDING (UNIFIED STRATEGY)
# ----------------------------------------------
# The prompt seeding file ensures *every* STARSHIP_* var possibly referenced by
# starship, wrappers, or diagnostics exists under set -u. Strategy:
# - All numeric state → typeset -gi <VAR>=0 when undefined.
# - Text context (ERRMSG, ERRCTX, ERRFUNC, ERRFILE) → typeset -g <VAR>="".
# - Arrays (STARSHIP_PIPE_STATUS, STARSHIP_CMD_PIPESTATUS) → typeset -ga & empty.
# - Idempotent, pure (no conditional logic dependent on runtime commands).
# - Debug log line only when ZSH_DEBUG=1 & path present.
# This prevents transient 'parameter not set' errors in precmd/preexec cycles.
#
# 5. GREP NEUTRALIZATION LAYERS
# -----------------------------
# Multi-stage approach due to plugin alias churn:
#   020-grep-core-prelude.zsh  -> unalias early & define zf::core_grep
#   030-grep-safe-shim.zsh     -> safe pattern interpretation; bracket fallback (-F)
#   040-grep-debug-tracer.zsh  -> (opt) logs unbalanced patterns when ZSH_DEBUG=1
#   Late post-plugin sanitizer (in .zshrc.d) reinforces command grep if plugins alias again.
# Rationale: avoid 'grep: brackets ([ ]) not balanced' noise when user or plugin maps grep → rg.
#
# 6. INTEGRATION WITH MAIN .zshrc LOADER
# --------------------------------------
# The user-level `.zshrc` calls `load-shell-fragments` over this directory. The
# numeric prefix ordering is thus the only sequencing guarantee—avoid any
# inter-file implicit waits or sleeps. If dynamic readiness is required (e.g.,
# waiting for a function definition), implement polling + timeout locally *or*
# shift logic to post-plugin stage.
#
# 7. PERFORMANCE GUIDELINES
# -------------------------
# - Only run external commands where outcome materially improves safety.
# - Prefer builtins (typeset, setopt, whence, command) over spawning subshells.
# - Gate optional logging behind ZSH_DEBUG.
# - Do not source large plugin libraries here—use sentinels for deferred loads.
#
# 8. ADDING A NEW FILE
# --------------------
# 1. Pick next free multiple-of-10 slot (keep ≥260 for future core expansion).
# 2. Add guard sentinel; ensure idempotency on re-source.
# 3. Keep external command usage minimal; add debug line (optional) behind ZSH_DEBUG.
# 4. Update (or regenerate) this README if the new concern introduces a *new phase*.
# 5. If cross-file dependency unavoidable, document explicitly at top of both files.
#
# 9. DEPRECATION / CLEANUP
# ------------------------
# - When merging two files, keep the old number as a stub that exports a warning & exits
#   for at least one iteration to aid users with local overrides.
# - Remove duplicate starship seeders (retain the richer superset variant) — already done.
#
# 10. FUTURE IMPROVEMENTS
# ------------------------
# - Auto-generate this README from small per-file metadata blocks.
# - Introduce a lightweight validator script that checks ordering + guard presence.
# - Optional hash (checksum) banner injection aligning with AI policy compliance.
#
# End of README
