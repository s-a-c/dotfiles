# Transcript: Adding and configuring olets/zsh-abbr

Date: 2025-08-27

This file is a saved transcript of the interactive conversation about adding and configuring the `olets/zsh-abbr` plugin to the zsh configuration that uses `zgenom` and the unixorn zsh-quickstart-kit layout.

NOTE: I could not locate the project's AI guidelines file(s) in the repository roots available to me, so I was unable to compute or include the required "Compliant with ... v<checksum>" acknowledgement header for AI‑authored artifacts. If you want that header included, provide the guidelines files or grant access and I'll update this file with the computed checksum.

---

User request (summary)
- Repo uses unixorn/zsh-quickstart-kit layout and `jandamm/zgenom`.
- `ZDOTDIR` is exported as `${XDG_CONFIG_HOME}/zsh`.
- Active locations: `$ZDOTDIR/.zshenv`, `$ZDOTDIR/.zshrc`, `$ZDOTDIR/.zshrc.pre-plugins.d/*`, `$ZDOTDIR/.zgen-setup`, `$ZDOTDIR/.zshrc.add-plugins.d/*`, `$ZDOTDIR/.zshrc.d/*`.
- Request: advise, describe and explain how to add and configure plugin `olets/zsh-abbr`.
- Additional: review `.zshrc.d.disabled` for previously implemented configuration (I inspected that directory for reference).

Assistant findings (high level)
- The project loads plugins using zgenom via an init flow in `.zgen-setup`.
- You already have an additional-plugins fragment in:
```zsh/.zshrc.add-plugins.d/010-add-plugins.zsh#L1-200
# Additional Plugin Configuration - Extends ZSH Quickstart Kit defaults
# CRITICAL: Maintains proper plugin loading order per ZSH-QS and zgenom best practices

# CRITICAL FIX: Add loading guard to prevent infinite loops
if [[ -n "${_ZSH_ADD_PLUGINS_LOADED:-}" ]]; then
    [[ "$ZSH_DEBUG" == "1" ]] &&     zsh_debug_echo "# [add-plugins] Already loaded, skipping to prevent infinite loop"
    return 0
fi
typeset -g _ZSH_ADD_PLUGINS_LOADED=1
...
# Auto-pair quotes, brackets, etc. - loads early to avoid conflicts
zgenom load hlissner/zsh-autopair

# Abbreviations system - COMMENTED OUT DUE TO RECURSION ISSUES
# This plugin is causing infinite loops and job table overflow
# zgenom load olets/zsh-abbr
```

- zsh-abbr has configuration variables you can set before sourcing to influence behavior (example excerpt):
```/dev/null/zsh-abbr.zsh#L1-40
# CONFIGURATION (excerpt)
typeset -gi ABBR_AUTOLOAD=${ABBR_AUTOLOAD:-1}
typeset -gi ABBR_DEBUG=${ABBR_DEBUG:-0}
typeset -gi ABBR_DEFAULT_BINDINGS=${ABBR_DEFAULT_BINDINGS:-1}
# ABBR_USER_ABBREVIATIONS_FILE defaults to ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/abbreviations
```

Why you saw recursion / job-table overflow previously
- zsh-abbr registers zle widgets and uses a job-queue dependency. If its job-queue submodule isn't available, or keybindings (`accept-line`, `magic-space`) are rebound by other plugins at the same time, you can get recursive widget invocation or job handling problems.
- Loading order matters: abbreviations should initialize after core libraries are present but early enough that the widgets exist; conflicts arise when two plugins try to rebind the same widgets at the same time.

Recommended safe plan (concise)
1. Add the plugin to your existing add-plugins file (PHASE 1).
2. Ensure the `zsh-abbr` dependency `zsh-job-queue` is available (either via Homebrew install or `git submodule update --init --recursive` in the plugin clone).
3. Disable zsh-abbr's automatic default bindings before the plugin is sourced.
4. After all plugins are loaded, bind keys explicitly in a `.zshrc.d` fragment to avoid binding conflicts.
5. Regenerate zgenom init and restart the shell.

Concrete edits / snippets to add

- 1) Add zgenom load line (uncomment/add in `zsh/.zshrc.add-plugins.d/010-add-plugins.zsh` PHASE 1):
```zsh/.zshrc.add-plugins.d/010-add-plugins.zsh#L1-200
# Add zsh-abbr (specify branch `main` to get v6+):
zgenom load olets/zsh-abbr . main
```

- 2) Pre-plugin config to set ABBR variables and disable auto bindings (create `$ZDOTDIR/.zshrc.pre-plugins.d/05-abbr-config.zsh`):
```zsh/.zshrc.pre-plugins.d/05-abbr-config.zsh#L1-80
# Put this in $ZDOTDIR/.zshrc.pre-plugins.d/05-abbr-config.zsh

# Store persistent user abbreviations inside your dotfiles location:
ABBR_USER_ABBREVIATIONS_FILE="${ZDOTDIR}/abbreviations"

# Keep plugin temp files under ZDOTDIR cache:
ABBR_TMPDIR="${ZDOTDIR}/.cache/abbr/"

# Disable default widget bindings so we can bind later (prevents conflicts)
typeset -gi ABBR_DEFAULT_BINDINGS=0

# Optional while debugging:
# typeset -gi ABBR_DEBUG=1
```

- 3) Post-plugin binding to be loaded after all plugins (create `$ZDOTDIR/.zshrc.d/99-abbr-bindings.zsh`):
```zsh/.zshrc.d/99-abbr-bindings.zsh#L1-40
# Put this in $ZDOTDIR/.zshrc.d/99-abbr-bindings.zsh (loaded after plugins)

# Defensive: only bind if abbr initialized
if (( ${+functions[abbr-expand]} )); then
  # Bind space to expand/insert
  bindkey " " abbr-expand-and-insert

  # Ctrl-space is a normal space
  bindkey "^ " magic-space

  # incremental-search handling
  bindkey -M isearch "^ " abbr-expand-and-insert
  bindkey -M isearch " " magic-space
fi
```

- 4) If zgenom clones the plugin but dependencies are missing, initialize submodules inside the zgenom plugin folder:
(You can perform this manually or via a script; example command to run once after zgenom clones)
```/dev/null/EXAMPLE-CMDS#L1-4
# Example (run manually, not to be placed in config):
cd "${ZGEN_DIR:-$HOME/.zgenom}/olets/zsh-abbr" && git submodule update --init --recursive
```
Alternatively, install via Homebrew (handles dependencies automatically):
```/dev/null/EXAMPLE-CMDS#L1-3
brew install olets/tap/zsh-abbr
```

Step-by-step (short)
1. Edit `zsh/.zshrc.add-plugins.d/010-add-plugins.zsh` and add:
   - `zgenom load olets/zsh-abbr . main`
2. Add pre-plugin config at `zsh/.zshrc.pre-plugins.d/05-abbr-config.zsh` (set `ABBR_DEFAULT_BINDINGS=0` and storage paths).
3. Add post-plugin bindings at `zsh/.zshrc.d/99-abbr-bindings.zsh`.
4. Ensure submodules/dependencies:
   - Option A (preferred if you use package manager): `brew install olets/tap/zsh-abbr`
   - Option B: after zgenom clones plugin, run submodule init command inside plugin clone.
5. Regenerate zgenom init and restart shell:
   - `zgenom reset && zgenom save && exec zsh` (or `zgenom save` then restart) to have zgenom clone/update plugin.

Troubleshooting tips
- If you see repeated `precmd`/`preexec` messages or job queue errors:
  - Confirm the plugin's `zsh-job-queue` is present (`zsh-abbr` expects it).
  - Temporarily set `ABBR_DEBUG=1` in the pre-plugin file to increase logging while diagnosing.
  - Check for other plugins that rebind `accept-line` or perform `zle -N accept-line` definitions; those may need to be ordered differently or made to cooperate.
- If you prefer to remain on v5 until you validate changes: pin the branch in zgenom to the v5 branch/tag rather than `main`.

Notes about persistence and dotfiles management
- `ABBR_USER_ABBREVIATIONS_FILE` controls where abbreviations are saved. Put that file under version control if you want abbreviations versioned with your dotfiles.
- The plugin auto-saves persistent abbreviations as lines like `abbr foo=long-command`. You can edit the file manually if needed (the docs describe storage and manual editing).

Acknowledgement & policy note
- Per project orchestration policies I attempted to find and compute the AI guidelines checksum to include the required acknowledgement header in artifacts I author. I could not locate the guidelines files in the repository roots available to me, so I did not insert a "Compliant with ... v<checksum>" header here. Provide the guidelines files or access and I will update this artifact with the computed checksum and acknowledgement.

If you want me to apply the changes directly to the repository (create the pre-plugin and binding fragments and add the zgenom load line), tell me and I will prepare the edits. If you also want the acknowledgement header added, please provide the project's AI guidelines files or tell me their path and I will compute the checksum and include the required header.

End of transcript.