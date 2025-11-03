# Catalogue of functions and variables unique to backup zsh config (zsh-my)

Scope
- Source scanned: dot-config/zsh/.backup/zsh-my
- Compared against: dot-config/zsh/.zshenv, dot-config/zsh/.zshrc, dot-config/zsh/.zgen-setup, dot-config/zsh/.zshrc.pre-plugins.d, dot-config/zsh/.zshrc.add-plugins.d, dot-config/zsh/.zshrc.d
- Goal: List functions and variables present in the backup that have no equivalent in the compared set. For each, provide source location and a recommended target location (existing or new module) with reasoning.

Notes
- Active configuration includes both redesigned helpers (zf::*) and the Quickstart Kit’s .zshrc/.zgen-setup. Items that exist by name or clear functionality in any of the compared files are considered “equivalent” and therefore omitted.
- Items marked “Omit” are migration-only, macOS-specific edge cases with low value, or conflict with the current design.


## Functions

| Name | Kind | Source location | Short description | Equivalent in active set | Recommended target location | Reasoning |
|---|---|---|---|---|---|---|
| _path_remove | function | .backup/zsh-my/dot-zshrc:310; .backup/zsh-my/dot-zshenv:66 | Remove path entries safely | None found in .zshenv/.zshrc/.zshrc.*/.zgen-setup | .zshrc.pre-plugins.d/005-compat-helpers.zsh (new) | Generic safe PATH helper, useful early for environment setup and de-dup. |
| _path_append | function | .backup/zsh-my/dot-zshrc:325; .backup/zsh-my/dot-zshenv:81 | Append to PATH with de-dup | None found in .zshenv/.zshrc/.zshrc.*/.zgen-setup | .zshrc.pre-plugins.d/005-compat-helpers.zsh (new) | Pairs with _path_remove/_path_prepend; safe, order-aware PATH management. |
| _path_prepend | function | .backup/zsh-my/dot-zshrc:334; .backup/zsh-my/dot-zshenv:92 | Prepend to PATH with de-dup | None found in .zshenv/.zshrc/.zshrc.*/.zgen-setup | .zshrc.pre-plugins.d/005-compat-helpers.zsh (new) | Pairs with the above; ensures higher-priority bins take effect without duplicates. |


## Variables

| Name | Kind | Source location | Value/role (short) | Equivalent in active set | Recommended target location | Reasoning |
|---|---|---|---|---|---|---|
| SHELL_SESSIONS_DISABLE | export | .backup/zsh-my/dot-zshenv:46 | Disable macOS Terminal shell session restore | None found | .zshenv (existing) | Harmless opt-out; improves performance and privacy in Terminal.app. |
| LESS | export | .backup/zsh-my/dot-zshenv:64 | Rich pager flags (colors, search, mouse) | None found | .zshrc.d/100-terminal-integration.zsh (existing) | Reasonable UX improvement; centralize terminal-facing env. |
| GOROOT | export | .backup/zsh-my/dot-zshrc:1062–1068 | Go toolchain root (if auto-detected) | None found | .zshrc.add-plugins.d/130-dev-systems.zsh (existing) | Only set if discovered; complements GOPATH without forcing versions. |
| DISPLAY | export | .backup/zsh-my/dot-zshenv:48 | Default X display | None found | Omit | Not generally meaningful on macOS terminals; can cause surprising GUI behavior. |
| DBUS_SESSION_BUS_ADDRESS, MY_SESSION_BUS_SOCKET | export | .backup/zsh-my/dot-zshenv:71–74 | DBus session address on macOS | None found | Omit | Rarely used on macOS; avoid unless specifically required by tooling. |


Validation details (how equivalence was checked)
- Compared against: dot-config/zsh/.zshenv, dot-config/zsh/.zshrc, dot-config/zsh/.zgen-setup, dot-config/zsh/.zshrc.pre-plugins.d, dot-config/zsh/.zshrc.add-plugins.d, dot-config/zsh/.zshrc.d.
- The following names previously flagged as unique actually exist in .zshrc and/or .zgen-setup and were therefore excluded: can_haz, zqs-debug, _zqs-*-setting helpers, load-shell-fragments, quickstart toggles (prompt, omz, zmv, ssh-askpass, diff-so-fancy), onepassword-agent-check, load-our-ssh-keys, globalias, TRAPINT, zqs/zqs-help, COMPLETION_WAITING_DOTS, LSCOLORS/LS_COLORS, HISTORY_IGNORE, TIMEFMT, DISABLE_AUTO_UPDATE, LOCATE_PATH, JAVA_HOME.

Next steps (optional)
- If adopting any of the listed helpers/vars, implement them guarded (only-if-unset / opt-in) with concise comments and toggles.
- Keep PATH helpers in a small early-loaded compat module; avoid scattering path munging across modules.
