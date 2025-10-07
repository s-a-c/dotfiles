# 060 - Risk Assessment

## Top

Status: Draft

Last updated: 2025-10-07

This risk assessment captures known and anticipated risks for the ZSH REDESIGN project, assigns mitigations, and documents rollback and emergency procedures. The goal is to ensure the redesign deploys safely and has clear recovery paths for high-impact failures.

## Scope & objectives

- Scope: configuration switching, plugin loading, prompt and widget health, symlink operations, user-facing performance regressions, and data privacy (history storage).
- Objectives: identify top risks, define mitigations and acceptance criteria, and provide clear rollback procedures.

## Risk matrix (example)

| ID | Risk | Likelihood | Impact | Mitigation | Owner |
|---:|---|---:|---:|---|---|
| R1 | Prompt duplication or widget conflicts (duplicate widgets leads to prompt errors) | Medium | High | Add widget baseline checks during startup; fail-safe to use previous configuration; log detailed diagnostics | Maintainer |
| R2 | Symlink switch failure leaving user without a valid config | Low | High | Validate symlink targets prior to atomic switch; provide emergency rollback script and pre-swap backup | Release Engineer |
| R3 | Optional plugin causes slow startup under default settings | High | Medium | Defer heavy plugin initialization; document opt-in flags; provide per-session lazy-loading | Performance Team |
| R4 | Sensitive data leaked via history or telemetry | Low | High | Gate telemetry; implement history filters; document privacy controls for Atuin | Security Lead |
| R5 | Zgenom cache corruption causing plugin load failures | Low | Medium | Rebuild caches on promote/switch events; provide `zgenom clean` helper in tooling | Maintainer |

## Detailed mitigations & runbooks

1. Prompt duplication / widget errors (R1)

- Mitigation:
  - During startup count ZLE widgets and compare against a baseline (e.g., >= 387) and abort the last applied fragment if the delta exceeds a threshold
  - Guard prompt initialization behind an idempotent check and `zf::segment` timing to detect regressions

- Detection:
  - Monitor shell logs for `ZLE widget` errors and surface alerts in CI runs

- Emergency procedure:
  - Run `./tools/emergency-rollback.sh` which resets `.zshrc.d.active` to the previous stable configuration and restarts the shell

2. Symlink switch failure (R2)

- Mitigation:
  - Verify every resolved symlink target exists before performing atomic rename
  - Take a temporary snapshot backup of current `.zshrc.d.active` pointer and configuration files prior to modification

- Runbook:
  - If a switch fails, run:

```bash
# Recover previous symlink state
readlink .zshrc.d.active.backup 2>/dev/null | xargs -I{} ln -sf {} .zshrc.d.active
# Validate config
./bin/validate-config.sh 00 || ./bin/validate-config.sh 01
```

3. Plugin/performance regressions (R3)

- Mitigation:
  - Use deferred loading for heavy plugins and measure startup timings in CI
  - Add a perf gate: if startup time increases beyond 10% in CI smoke tests, block promotion to .00

- Monitoring:
  - Collect `startup-timings.csv` and compare deltas between baseline and candidate builds

4. Privacy and history leakage (R4)

- Mitigation:
  - Document privacy options and provide `HIST_IGNORE` patterns to skip recording sensitive commands
  - Gate Atuin sync and avoid shipping default sync tokens in configs

- Remediation:
  - Provide a guide to scrub sensitive entries from Atuin or `.zsh_history` and rotate any leaked tokens

## Risk acceptance & prioritization

- High impact (blocker) risks must have automated mitigations and a documented rollback
- Medium impact risks require monitoring and clear remediation plans
- Low impact risks should be logged and scheduled for backlog remediation

## Post-incident analysis

- For any incident triggered by a redesign promotion, create a post-mortem with the following structure:
  - Summary of event
  - Timeline
  - Root cause
  - Actions taken
  - Follow-up items and owners

## Reporting & ownership

- Each risk entry should be owned by a team or maintainer with a person assigned for escalation
- Maintain a short living risk register file (e.g., `docs/400-redesign/RISKS.md`) that is updated as risks change

## Acceptance criteria

- Risk matrix exists for top risks with assigned mitigation strategies
- Rollback runbook is present and tested manually at least once per release cycle
- CI detects regressions in startup performance and blocks promotion when thresholds are exceeded

## Related

- See `040-implementation-guide.md` for emergency scripts and `070-maintenance-guide.md` for scheduled checks and diagnostics
- Return to [Redesign Index](../000-index.md) or [000-index](../000-index.md)
