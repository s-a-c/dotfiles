# EMERG-ZLE-INIT-01 — Robust Emergency ZLE Initialization & Widget Floor Restoration

Status: OPEN  
Priority: High (Green Light waiver removal)  
Owner: (unassigned)  
Created: 2025-10-02  
Related Waiver: “Emergency Fallback Waiver – 2025-10-02” (plan-of-attack.md)  

## 1. Summary

The emergency configuration (`.zshrc.emergency`) currently loads a minimal prompt and safety environment but does not succeed in fully initializing ZLE in automated PTY validation. The PTY helper (`tools/emergency-widget-count.sh`) reports `widgets=1`, well below the documented historical rollback floor (387). A waiver was issued for the latest validation snapshot. This task restores compliance by enabling a reliable, non-interactive enumeration of a sufficiently large, stable widget set in emergency mode without risking reintroduction of the earlier ZLE corruption issues.

## 2. Problem Statement

- Green Light acceptance criteria retain a rollback floor (≥387 widgets) to justify emergency fallback viability.
- Current emergency session produces **1** enumerated widget (only the synthetic `_emergency_nop`), failing the historical guarantee.
- Automated snapshots must either (a) record a compliant number or (b) continue depending on a waiver, which weakens audit confidence.

## 3. Constraints & Non‑Goals

| Aspect | In Scope | Out of Scope |
|--------|----------|--------------|
| Reliable enumeration | ✅ | |
| Maintaining minimal side effects | ✅ | |
| Ensuring non-corruption of main redesign layers | ✅ | |
| Advanced prompt / plugins in emergency | | ❌ |
| Segment capture in emergency | | ❌ |
| Performance instrumentation | | ❌ |

## 4. Root Causes (Hypothesis)

1. Emergency shell exits before a full interactive ZLE editing loop occurs; built‑in widgets aren’t forced to load.
2. `zle -la` relies on internal initialization finalization not fully triggered under `script` / non-blocking PTY usage.
3. Prior corruption issues led to conservative emergency config; over-minimalization removed triggers that populate standard widgets.

## 5. Proposed Remediation Strategy

Phase-based, minimal risk:

### Phase A — Stimulate ZLE Initialization
- Add `zmodload zsh/zle; zmodload zsh/complist`.
- Define a protected `precmd` and `zle-line-init` no-op to force normal event hook path.
- Invoke a controlled `zle -K viins` (or fallback `bindkey -e`) only if safe.

### Phase B — Force Editor Cycle (Non-blocking)
- Use a subshell PTY probe to:
  1. Register a temporary widget.
  2. Invoke `zle _emergency_widget_probe` via `zle -f` or simulate input using `printf` piped into the PTY.
- Immediately enumerate widgets after hooks finalize.

### Phase C — Sanity & Guarding
- Guard all new code behind env flag `ZF_EMERGENCY_EXTEND=1` (default ON once validated; easy rollback by exporting 0).
- Add hard timeout (e.g. `EMERG_ZLE_INIT_TIMEOUT_MS=250`) to prevent hangs if upstream modules misbehave.

### Phase D — Snapshot Integration
- Update `emergency-widget-count.sh` to:
  - Prefer `script` method, fallback `python-pty`.
  - Report `method`, `widgets`, `init_strategy` fields.
- Append a new snapshot once ≥ rollback floor achieved; remove waiver block from plan-of-attack.md.

## 6. Acceptance Criteria

| ID | Criterion | Details |
|----|-----------|---------|
| AC1 | Emergency widget count ≥ 387 | Measured by `tools/emergency-widget-count.sh --json` |
| AC2 | No hangs / timeouts | Execution < 600ms typical on reference machine |
| AC3 | No pollution of main interactive session | Sourcing `.zshrc.emergency` does not set extraneous global vars beyond documented set |
| AC4 | Waiver removal | “Emergency Fallback Waiver” note removed + replacement note citing restoration |
| AC5 | Rollback toggle | Setting `ZF_EMERGENCY_EXTEND=0` reverts to current minimal behavior (documented) |
| AC6 | CI Integration | Layer health workflow includes emergency widget capture & asserts ≥387 (warn-only until first pass, then enforced) |

## 7. Technical Plan (Detailed)

1. **Instrumentation Hooks:**
   - Add `zle-line-init` no-op: ensures widget tables fill.
   - Optionally call `autoload -U colors && colors` (safe) if prompt fallback needs coloring; wrap in guard.

2. **Editor Trigger:**
   - Simulate a keystroke by binding a temporary widget and invoking it with `zle` command (non-blocking).
   - Example stub:
     ```zsh
     _emergency_probe() { :; }
     zle -N _emergency_probe 2>/dev/null || true
     { zle _emergency_probe 2>/dev/null || true; } >/dev/null 2>&1
     ```

3. **Safety Guard:**
   - If `[[ -n $ZSH_EVAL_CONTEXT ]] && [[ $ZSH_EVAL_CONTEXT == *file:* ]]` avoid recursion loops.

4. **Timeout Fallback:**
   - Wrap advanced steps in a subshell with `EMERGENCY_ZLE_EXTENDED=1` and `command time` logging if necessary (optional).

5. **Counting Approach Fix:**
   - Current helper counts lines of `zle -la | wc -l`. Keep stable.
   - If count <100 post-init, log diagnostics: `typeset -f zle-line-init`, `echo ${(k)widgets[(I)accept-line]}` (guarded).

6. **Docs & Snapshot:**
   - Remove waiver section.
   - Add new validation note citing restored compliance.

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Hidden race causing hang | CI stall | Timeout wrapper, early guard variable |
| Unexpected global side effects | Polluted state | Namespace `_emerg::*` or `EMERG_` for helper vars |
| Regression in main redesign ZLE | User disruption | Strict no sourcing of full plugin manager in emergency profile |
| Inconsistent counts across platforms | Flaky baseline | Capture macOS + Linux reference counts before enforcement |

## 9. Observability / Metrics

- Add optional `EMERG_DEBUG=1` to print:
  - Init phase timestamps.
  - Whether hooks ran.
  - Pre/post widget counts.

- Record counts in a `docs/fix-zle/results/emergency/` log:
  - `YYYYMMDD-HHMM-emergency-widgets.txt` containing raw JSON from helper.

## 10. Rollback Plan

1. Set `ZF_EMERGENCY_EXTEND=0` in environment → restores minimal behavior.
2. If extended init causes failure, revert commit touching `.zshrc.emergency` and helper script.
3. Re-apply previous waiver documentation (copy preserved text block from git history).

## 11. Definition of Done (DoD)

- Code changes merged: `.zshrc.emergency`, `tools/emergency-widget-count.sh`.
- Snapshot appended with emergency_widgets ≥387 (force flag NOT required).
- Waiver removed; replacement note added in plan-of-attack.md.
- CI workflow updated to assert new floor (initially warn, then enforce after first green run).
- Backlog item closed with link to commit(s) & snapshot line.

## 12. Implementation Checklist

- [ ] Add extended ZLE init block (guarded).
- [ ] Add environment flags (`ZF_EMERGENCY_EXTEND`, optional `EMERG_DEBUG`).
- [ ] Enhance helper script for init_strategy note.
- [ ] Verify counts locally (≥387).
- [ ] Update plan-of-attack.md (remove waiver, add compliance note).
- [ ] Run layer-health workflow; capture artifacts.
- [ ] Append new snapshot (non-force).
- [ ] Switch CI gate from warn to enforce for emergency floor.
- [ ] Close this backlog entry.

## 13. References

- Current Waiver: Validation Note (Emergency Fallback Waiver – 2025-10-02)
- Helper Script: `tools/emergency-widget-count.sh`
- Snapshot Script: `tools/append-validation-snapshot.sh`
- Plan: `docs/fix-zle/plan-of-attack.md`

---

Prepared: 2025-10-02  
Next Action: Assign implementer & begin Phase A (extended init prototype).