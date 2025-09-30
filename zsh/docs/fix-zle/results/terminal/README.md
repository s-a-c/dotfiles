# Terminal Session Evidence Index (Phase 6)

Phase: 6 (Terminal Integration)  
Status: PARTIAL – awaiting interactive evidence capture artifacts.  
This directory aggregates proof that the unified terminal integration module
`100-terminal-integration.zsh` exports the expected environment markers across
supported terminals (Warp, WezTerm, Ghostty, Kitty, and minimal iTerm2).

## Purpose

Provide auditable runtime evidence that:
1. Environment detection logic activates only for the correct terminal.
2. No spurious variables are exported in non‑matching terminals.
3. Optional integration scripts (e.g. iTerm2) do not degrade startup when absent.
4. Phase 6 closure criteria (evidence artifacts + harness) are satisfied.

## Current Files

| File | Description | Present |
|------|-------------|---------|
| (pending) `warp-session-YYYYMMDD-HHMMSS.log` | Interactive capture from Warp | ❌ |
| (pending) `wezterm-session-YYYYMMDD-HHMMSS.log` | Interactive capture from WezTerm | ❌ |
| (pending) `ghostty-session-YYYYMMDD-HHMMSS.log` | Interactive capture from Ghostty | ❌ |
| (pending) `kitty-session-YYYYMMDD-HHMMSS.log` | Interactive capture from Kitty | ❌ |
| (pending) `iterm2-session-YYYYMMDD-HHMMSS.log` | Minimal iTerm2 evidence | ❌ |
| (auto) `README.md` | This index | ✅ |

Once each artifact is added, update the table (Present ✅) and append a short
“Observation” line beneath this section.

## Capture Instructions

For each terminal:

1. Start a fresh interactive login (ensure redesigned config is active).
2. Run the following command set:

   ```
   echo "TERM_PROGRAM=$TERM_PROGRAM"
   echo "TERM=$TERM"
   for v in WARP_IS_LOCAL_SHELL_SESSION \
            WEZTERM_SHELL_INTEGRATION \
            GHOSTTY_SHELL_INTEGRATION \
            KITTY_SHELL_INTEGRATION; do
     eval "echo $v=\${$v:-0}"
   done
   zsh --version
   echo "ZLE widgets:" $(zle -la 2>/dev/null | wc -l || echo 0)
   date -u "+UTC %Y-%m-%d %H:%M:%S"
   ```

3. (If available) Trigger a completion or simple command (e.g. `echo ok`).
4. Exit the shell cleanly.

5. Save the scrollback or piped transcript to:
   `warp-session-<UTCSTAMP>.log`, etc.

### Recommended Shortcut (Mac)

From inside each terminal:

```
script -q /tmp/termcap.txt bash -lc '
  zsh -i -c "
    echo CAPTURE_START
    echo TERM_PROGRAM=$TERM_PROGRAM
    echo TERM=$TERM
    for v in WARP_IS_LOCAL_SHELL_SESSION WEZTERM_SHELL_INTEGRATION GHOSTTY_SHELL_INTEGRATION KITTY_SHELL_INTEGRATION; do
      eval echo \$v=\${$v:-0}
    done
    echo ZLE widgets: \$(zle -la 2>/dev/null | wc -l || echo 0)
    echo Shell: \$(zsh --version)
    echo CAPTURE_END
  "
'
```

Then rename `/tmp/termcap.txt` appropriately and move into this directory.

## Naming Convention

`<terminal>-session-YYYYMMDD-HHMMSS.log` (UTC timestamp recommended for ordering).

Example:
```
wezterm-session-20251001-141503.log
```

## Acceptance Criteria for Phase 6 Completion

- [ ] All four primary terminals (Warp, WezTerm, Ghostty, Kitty) have a log.
- [ ] At least one minimal iTerm2 log (optional but preferred).
- [ ] Each log shows exactly one expected marker exported:
  - Warp: `WARP_IS_LOCAL_SHELL_SESSION=1`
  - WezTerm: `WEZTERM_SHELL_INTEGRATION=1`
  - Ghostty: `GHOSTTY_SHELL_INTEGRATION=1`
  - Kitty: `KITTY_SHELL_INTEGRATION=enabled`
- [ ] Non‑matching markers either absent or set to `0`/unset.
- [ ] Widget count consistent with baseline (≥ 387; currently 407).
- [ ] No error output (grep logs for “ERROR” / “command not found”).
- [ ] This README updated to reflect ✅ presence and brief observations.

## Log Review Checklist (Per Artifact)

| Check | Expectation |
|-------|-------------|
| Terminal marker | Exactly the one matching the terminal |
| Other markers | Empty / 0 |
| ZLE widgets | ≥ baseline |
| Timestamp | Present |
| Shell version | Present |
| Noise / errors | None |

## Example Expected Snippet (Ghostty)

```
TERM_PROGRAM=ghostty
TERM=xterm-256color
WARP_IS_LOCAL_SHELL_SESSION=0
WEZTERM_SHELL_INTEGRATION=0
GHOSTTY_SHELL_INTEGRATION=1
KITTY_SHELL_INTEGRATION=0
ZLE widgets: 407
Shell: zsh 5.9 (x86_64-apple-darwin)
```

(Kitty case will differ because detection uses TERM `xterm-kitty` and sets
`KITTY_SHELL_INTEGRATION=enabled`.)

## Post-Capture Update Template

Append under “Captured Artifacts” after adding each file:

```
### Captured Artifacts (Rolling Log)

- 2025-10-01: warp-session-20251001-141503.log (widgets=407; marker OK; no errors)
- 2025-10-01: wezterm-session-20251001-142012.log (widgets=407; marker OK)
...
```

## Maintenance & Future Enhancements

Potential future optional improvements (not required for Phase 6 closure):

- Automated capture harness invoking containers or simulated TTY.
- Script to diff marker sets across terminals.
- JSON summarizer (`tools/terminal-evidence-summary.zsh`) emitting machine‐readable index.

## Rollback / Replacement

If unified terminal logic changes:
1. Keep historical logs (do not delete).
2. Start a new dated subdirectory (e.g. `v2/`) if semantics of markers change.
3. Update this README with “Superseded on YYYY-MM-DD” note.

---

Prepared: 2025-09-30  
Authoring Context: fix-zle initiative (feature-driven redesign)  
Compliance: Aligns with Phase 6 evidence requirement documented in `plan-of-attack.md`.
