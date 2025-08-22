1. 1. Confirm scope, environment, and constraints
- Target: Interactive Zsh startup across macOS and Linux, Zsh 5.4+ (tested 5.8/5.9).
- Must not affect non-interactive shells (e.g., zsh -c, scripts).
- Must capture all startup stdout/stderr to a per-session file when quiet mode is active.
- Show only:
  1) a concise welcome line
  2) a brief suppressed-issues summary
- Toggling:
  - CLI flag (preferred: -Q/--quiet-startup via wrapper)
  - $ZDOTDIR sentinel file: $ZDOTDIR/.quiet-startup (on), $ZDOTDIR/.quiet-startup.off (off)
  - Optional env flag: ZSH_QUIET_STARTUP=1 for ad-hoc sessions
- Integrate with zsh-abbr to suppress its startup chatter.
- Preserve the final startup exit code ($?) the user sees after initialization finishes.
- Follow single-session terminal usage; avoid launching extra terminals in validation steps.
2. 2. Define quiet-mode UX, toggles, and precedence
- UX when quiet:
  - Only print two blocks after startup completes: welcome and a short issues summary (top N lines).
  - Tell the user where the full log is and how to inspect it.
- Precedence (highest to lowest):
  1) CLI flag (wrapper parsing -Q/--quiet-startup) → enables quiet for that session
  2) Env var ZSH_QUIET_STARTUP=1|true|yes|on → enables quiet
  3) Sentinel files in $ZDOTDIR:
     - .quiet-startup → enable
     - .quiet-startup.off → disable (overrides .quiet-startup)
- Default: quiet disabled if no toggles present.
- Non-interactive shells: quiet mode does not activate, and no redirection is applied.
3. 3. Implement CLI wrapper for -Q/--quiet-startup support
- Provide a portable wrapper that accepts -Q/--quiet-startup, sets ZSH_QUIET_STARTUP=1, and execs the real zsh.
- Install to a user path earlier than system zsh (e.g., ~/.local/bin). Do not replace system zsh binary.
- Name options:
  - Safer default: zshq (recommended)
  - Optional advanced: a wrapper named zsh that passes through all other flags and resolves the real zsh to avoid recursion.
- Example zshq (recommended) script (bash):
```bash
#!/usr/bin/env bash
set -euo pipefail
exec env ZSH_QUIET_STARTUP=1 zsh "$@"
```
- Optional advanced wrapper named zsh (ensure it finds the real zsh, not itself):
```bash
#!/usr/bin/env bash
set -euo pipefail

QUIET=0
args=()
for a in "$@"; do
  case "$a" in
    -Q|--quiet-startup) QUIET=1 ;;
    *) args+=("$a") ;;
  esac
done

self="$(command -v "$0" || true)"
# Find an actual zsh that's not this wrapper
REAL_ZSH=""
while IFS= read -r cand; do
  [[ -n "$self" && "$cand" == "$self" ]] && continue
  REAL_ZSH="$cand"
  break
done &lt; &lt;(command -v -a zsh || true)

# Fallbacks
[[ -z "$REAL_ZSH" && -x /opt/homebrew/bin/zsh ]] &amp;&amp; REAL_ZSH=/opt/homebrew/bin/zsh
[[ -z "$REAL_ZSH" && -x /usr/local/bin/zsh ]] &amp;&amp; REAL_ZSH=/usr/local/bin/zsh
[[ -z "$REAL_ZSH" && -x /bin/zsh ]] &amp;&amp; REAL_ZSH=/bin/zsh
[[ -z "$REAL_ZSH" && -x /usr/bin/zsh ]] &amp;&amp; REAL_ZSH=/usr/bin/zsh

if [[ -z "$REAL_ZSH" ]]; then
  echo "Could not locate real zsh" >&amp;2
  exit 127
fi

if [[ $QUIET -eq 1 ]]; then
  exec env ZSH_QUIET_STARTUP=1 "$REAL_ZSH" "${args[@]}"
else
  exec "$REAL_ZSH" "${args[@]}"
fi
```
- Users can start quiet sessions with:
  - zshq
  - zsh -Q (if wrapper replaces zsh safely)
4. 4. Create core quiet-mode library file ($ZDOTDIR/lib/quiet-mode.zsh)
- Centralizes detection, logging, redirection, and summary.
- Must be sourced very early in interactive startup (before plugins).
- Core responsibilities:
  - Decide activation (CLI/env/sentinel)
  - Open session log and redirect stdout/stderr to it
  - Hook precmd to restore FDs and print the welcome and summary exactly once
  - Preserve exit status by capturing $?
- Draft implementation:
```zsh
# $ZDOTDIR/lib/quiet-mode.zsh

typeset -gi ZSH_QUIET_ACTIVE=0
typeset -g ZSH_STARTUP_LOG=""
typeset -g ZSH_LAST_STARTUP_LOG=""
typeset -g ZSH_STARTUP_LOG_DIR=""
typeset -g ZSH_SESSION_ID=""
typeset -gi __QUIET_STDOUT_SAVE_FD=-1 __QUIET_STDERR_SAVE_FD=-1 __QUIET_LOG_FD=-1

__quiet_bool() {
  local v="${1:-}"
  [[ "$v" == "1" || "$v" == "true" || "$v" == "yes" || "$v" == "on" ]]
}

__quiet_should_activate() {
  [[ -o interactive ]] || return 1
  if __quiet_bool "${ZSH_QUIET_STARTUP:-}"; then return 0; fi
  local zd="${ZDOTDIR:-$HOME}"
  [[ -f "$zd/.quiet-startup.off" ]] && return 1
  [[ -f "$zd/.quiet-startup" ]] && return 0
  return 1
}

__quiet_mklog() {
  local state_root="${ZSH_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}}/zsh"
  ZSH_STARTUP_LOG_DIR="$state_root/startup"
  mkdir -p -- "$ZSH_STARTUP_LOG_DIR" 2>/dev/null || true
  local ts="$(command date +%Y%m%dT%H%M%S 2>/dev/null || date +%Y%m%dT%H%M%S)"
  local host="${HOST:-$(command hostname -s 2>/dev/null || echo unknown)}"
  local tty="$(command tty 2>/dev/null || echo "no-tty")"; tty="${tty##*/}"
  ZSH_SESSION_ID="${ts}-${host}-${PPID}-${tty}"
  ZSH_STARTUP_LOG="${ZSH_STARTUP_LOG_DIR}/${ZSH_SESSION_ID}.log"
  ZSH_LAST_STARTUP_LOG="${ZSH_STARTUP_LOG_DIR}/last.log"
}

__quiet_summarize() {
  local log="$1"
  local -a matches
  local -i total=0
  if [[ -r "$log" ]]; then
    total=$(command wc -l < "$log" 2>/dev/null | tr -d ' ' || echo 0)
    matches=("${(@f)$(command grep -iE '(^|[[:space:]])(zsh:|warn(ing)?|error|fatal|fail|permission denied|command not found|not found|traceback|exception|insecure|cannot|unable)' "$log" 2>/dev/null | head -n 10)}")
  fi
  print -r -- "Startup log: $log"
  print -r -- "Suppressed lines: $total"
  if (( ${#matches} )); then
    print -r -- "Top issues:"
    for l in "${matches[@]}"; do
      print -r -- "  - $l"
    done
  else
    print -r -- "No obvious issues detected."
  fi
}

__quiet_finalize() {
  local last_status=$?
  # Restore stdout/stderr if redirected
  if (( __QUIET_STDOUT_SAVE_FD >= 0 )); then exec 1>&${__QUIET_STDOUT_SAVE_FD}; fi
  if (( __QUIET_STDERR_SAVE_FD >= 0 )); then exec 2>&${__QUIET_STDERR_SAVE_FD}; fi
  (( __QUIET_STDOUT_SAVE_FD >= 0 )) && exec {__QUIET_STDOUT_SAVE_FD}>&-
  (( __QUIET_STDERR_SAVE_FD >= 0 )) && exec {__QUIET_STDERR_SAVE_FD}>&-
  (( __QUIET_LOG_FD >= 0 )) && exec {__QUIET_LOG_FD}>&-

  command ln -sf "$ZSH_STARTUP_LOG" "$ZSH_LAST_STARTUP_LOG" 2>/dev/null || true

  print -r -- "Welcome — quiet startup is active. Full startup output saved to:"
  print -r -- "  $ZSH_STARTUP_LOG"
  __quiet_summarize "$ZSH_STARTUP_LOG"

  # Run only once
  if typeset -f add-zsh-hook >/dev/null 2>&1; then
    add-zsh-hook -d precmd __quiet_finalize 2>/dev/null || true
  else
    # remove manual hookup below if present
    precmd_functions=(${precmd_functions:#__quiet_finalize})
  fi

  return $last_status
}

__quiet_enable() {
  (( ZSH_QUIET_ACTIVE )) && return 0
  __quiet_mklog

  # Open log FD and redirect
  exec {__QUIET_LOG_FD}>>"$ZSH_STARTUP_LOG"
  exec {__QUIET_STDOUT_SAVE_FD}>&1 {__QUIET_STDERR_SAVE_FD}>&2
  exec 1>&${__QUIET_LOG_FD} 2>&1

  # Integrate with zsh-abbr (quiet its startup chatter)
  export ABBR_QUIET=1
  zstyle ':abbr' quiet yes 2>/dev/null

  (( ZSH_QUIET_ACTIVE=1 ))

  # Hook finalize just before first prompt
  if autoload -Uz add-zsh-hook 2>/dev/null; then
    add-zsh-hook -Uz precmd __quiet_finalize
  else
    # Fallback: use legacy precmd_functions array
    typeset -ga precmd_functions
    precmd_functions+=__quiet_finalize
  fi
}

# Activate if required
if __quiet_should_activate; then
  __quiet_enable
fi

# User-facing helpers
quiet-startup-status() {
  if (( ZSH_QUIET_ACTIVE )); then
    print -r -- "Quiet startup: ACTIVE (this session)"
  else
    if __quiet_should_activate; then
      print -r -- "Quiet startup: would be active for a new interactive session"
    else
      print -r -- "Quiet startup: INACTIVE"
    fi
  fi
}

toggle-quiet-startup() {
  local zd="${ZDOTDIR:-$HOME}"
  case "${1:-status}" in
    on)
      : > "$zd/.quiet-startup"
      command rm -f "$zd/.quiet-startup.off" 2>/dev/null || true
      print -r -- "Quiet startup: ON (persistently for new sessions)"
      ;;
    off)
      : > "$zd/.quiet-startup.off"
      command rm -f "$zd/.quiet-startup" 2>/dev/null || true
      print -r -- "Quiet startup: OFF (persistently for new sessions)"
      ;;
    status)
      if __quiet_should_activate; then
        print -r -- "Quiet startup would be active for a new interactive session"
      else
        print -r -- "Quiet startup would be inactive for a new interactive session"
      fi
      ;;
    *)
      print -r -- "Usage: toggle-quiet-startup [on|off|status]"
      return 2
      ;;
  esac
}

view-startup-log() {
  local log="${1:-$ZSH_LAST_STARTUP_LOG}"
  if [[ -r "$log" ]]; then
    command ${PAGER:-less} -R -- "$log"
  else
    print -r -- "No readable startup log found at: $log"
    return 1
  fi
}

quiet-startup-summary() {
  local log="${1:-$ZSH_LAST_STARTUP_LOG}"
  __quiet_summarize "$log"
}
```
5. 5. Source the library as early as possible in interactive startup
- Ensure the code runs before any plugin manager or framework output (oh-my-zsh, zinit, antidote, zplug, etc.).
- Recommended placement at the top of $ZDOTDIR/.zshrc:
```zsh
# Early quiet mode integration (must be first for maximum capture)
if [[ -r "${ZDOTDIR:-$HOME}/lib/quiet-mode.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/lib/quiet-mode.zsh"
fi
```
- Alternative (if you have a layered setup): in a very-early file sourced by your framework, but must precede any component that could print.
6. 6. Implement robust logging (session file naming, directories, symlink to last)
- Log directory:
  - ${ZSH_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}}/zsh/startup
- File name includes timestamp, host, parent PID, and TTY. Example:
  - 20250101T120102-mbp-12345-ttys001.log
- Maintain a symlink last.log → last session file.
- Keep redirects only during startup; restore before first prompt to avoid capturing interactive commands.
7. 7. Summarize suppressed issues (pattern-based extraction)
- Simple heuristic using grep -iE against common error/warn tokens:
  - zsh:, warn, warning, error, fatal, fail, permission denied,
    command not found, not found, traceback, exception, insecure,
    cannot, unable
- Count total suppressed lines (wc -l) and show top 10 matches.
- Provide quiet-startup-summary [path] to reprint later.
- Users can open the full log via view-startup-log.
8. 8. Integrate with zsh-abbr quiet settings
- When quiet is active, set both:
  - export ABBR_QUIET=1
  - zstyle ':abbr' quiet yes
- Both calls are idempotent and safe if zsh-abbr is not installed (zstyle is built-in; it will just set a style).
- If your environment uses a different zsh-abbr quiet key, add a mapping function to set that key when detected.
9. 9. Provide user commands for convenience
- toggle-quiet-startup [on|off|status]
  - Writes/removes $ZDOTDIR/.quiet-startup(.off) sentinel files.
  - Affects new sessions; does not retroactively change current session redirection.
- quiet-startup-status
  - Reports current session state and new-session prediction.
- view-startup-log [path]
  - Opens a specific startup log or last.log with ${PAGER:-less}.
- quiet-startup-summary [path]
  - Reprints the summary for last.log or a given file.
10. 10. Preserve exit codes across startup
- Strategy:
  - Do redirection immediately when quiet is active.
  - Defer all output until precmd via __quiet_finalize and capture local last_status=$? at function entry.
  - Restore FDs, print welcome/summary, and return $last_status.
- This ensures the final visible $? after startup equals the last command’s status from initialization (e.g., a plugin load failure remains detectable).
11. 11. Handle edge cases and safety
- Non-interactive shells: __quiet_should_activate returns false; no redirection applied.
- Nested shells: quiet logic will re-run per interactive shell; acceptable, but you can add guard logic if undesired for subshells.
- Missing TTY: fallback to "no-tty" in session ID.
- Broken pager: view-startup-log uses ${PAGER:-less} and reports if log is unreadable.
- If a plugin calls exec or manipulates FDs: the early redirection ensures most output is captured; restoration happens just before prompt.
12. 12. Testing and verification
- Matrix:
  - macOS (Apple zsh and Homebrew zsh), Ubuntu/Debian/Fedora
  - Launch via: default terminal (no flags), zshq, zsh -Q (wrapper), env ZSH_QUIET_STARTUP=1 zsh
- Scenarios:
  - With and without plugin managers (oh-my-zsh, zinit, antidote, zplug)
  - With compinit insecure directories (ensure it’s summarized)
  - With deliberately failing plugin sourcing (ensure non-zero $? is preserved)
  - Non-interactive: zsh -c 'echo hi' (no quiet behavior)
- Validate:
  - Only welcome + summary appear on screen when quiet
  - Startup log file exists and contains captured output
  - last.log symlink points to the newest session
  - quiet-startup-status, toggle-quiet-startup, view-startup-log work as expected
13. 13. Documentation and onboarding
- Add a README section with numbered headings (1, 1.1, …), and code blocks specifying languages.
- Include:
  - What quiet mode does and does not do
  - How to enable via CLI: zshq or zsh -Q (if wrapper)
  - How to enable persistently via toggle-quiet-startup on
  - Where logs live and how to view/summary them
  - How to integrate in .zshrc (source early)
  - zsh-abbr integration specifics
- Include troubleshooting tips for common issues (e.g., no log created → check interactivity).
14. 14. Version control and commits
- Group related changes logically:
  - Add wrapper(s)
  - Add lib/quiet-mode.zsh
  - Modify .zshrc to source early
  - Docs and tests
- Follow commit message rules (imperative summary ≤ 50 chars, wrapped body, bullets, references).
- Example:
```text
Feat: Add global Zsh quiet startup mode

- Capture startup output to per-session log
- Show welcome and suppressed-issues summary only
- Add -Q/--quiet-startup wrapper and ZDOTDIR sentinels
- Preserve exit code via precmd finalize hook
- Integrate with zsh-abbr quiet settings
- Provide user helpers and documentation

Recommended tag: v0.1.0
```
15. 15. Rollout and fallback
- Stage rollout:
  - Start with zshq wrapper; verify behavior
  - Enable sentinel to default quiet where desired
  - Optionally deploy zsh wrapper (advanced users only)
- Fallback:
  - Remove sentinel files and wrappers to fully disable
  - Comment out the early source line in .zshrc to revert
