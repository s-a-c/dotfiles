# 070 - Maintenance Guide

## Top

Status: Draft

Last updated: 2025-10-07

This document describes ongoing maintenance and operational procedures for the ZSH REDESIGN project. It complements the implementation guide by providing routine tasks, scheduled checks, telemetry guidance, and emergency procedures designed to keep the configuration healthy.

## Maintenance goals

- Keep active configurations healthy and verifiable
- Detect regressions (performance, widget counts) early
- Ensure safe rollback and recovery paths are available and tested


## Routine maintenance tasks

Daily (or on-demand):

- Verify active symlinks point to expected versions


```bash
readlink .zshenv.active || echo "active pointer missing"
```

- Confirm that basic smoke checks pass (e.g., `./tools/run-smoke-tests.sh --target 400-redesign`)


Weekly:

- Run smoke tests and compare startup timings to baseline
- Refresh plugin caches where applicable (e.g., `zgenom` cache rebuild)


Monthly:

- Review optional plugin performance deltas and decide whether to change defaults
- Audit `HISTFILE` and confirm privacy settings


## Backups & snapshots

- Before any mass promotion or automated switch, snapshot configuration files:


```bash
mkdir -p backups/$(date +%Y%m%d_%H%M%S)
cp -a .zshenv.* backups/$(date +%Y%m%d_%H%M%S)/ || true
```

- Keep a short retention policy for backups in `backups/` and regularly prune older snapshots


## Symlink validation

- Validate symlink targets prior to atomic switching


```bash
for link in .zshenv.active .zshrc.pre-plugins.d.active .zshrc.add-plugins.d.active .zshrc.d.active; do
  target=$(readlink -f "$link" 2>/dev/null || true)
  if [[ -z "$target" || ! -e "$target" ]]; then
    echo "Broken or missing target for $link -> $target"
  else
    echo "OK: $link -> $target"
  fi
done
```

## Cache refresh & plugin hygiene

- When promoting or switching configurations, rebuild or invalidate plugin caches safely to avoid transient failures:


```bash

# Safe zgenom cache refresh

rm -f .zgenom/init.zsh || true

# Optionally log the action

echo "zgenom init cleared at $(date)" >> logs/plugin-cache.log
```

## Telemetry & diagnostics

- Collect lightweight startup timing via `zf::segment` and write to `logs/startup-timings.csv`
- Avoid collecting command-level history or personal data in telemetry


Example diagnostic snippet (for local runs):

```bash

# produce a timing sample for this session

zf::segment::dump --outfile=logs/startup-$(date +%s).json || true
```

## Emergency procedures

When a configuration promotion or switch causes breakage:

1. Revert active pointers to the previous stable version using saved backups


```bash

# Restore previously backed up active pointers (example)

ln -sf .zshenv.01 .zshenv.active
ln -sf .zshrc.d.01 .zshrc.d.active
```

2. Rebuild plugin caches and validate config:


```bash
./bin/validate-config.sh 01 || true
rm -f .zgenom/init.zsh
```

3. If prompt/widget errors persist, use the widget baseline checker and rollback:


```bash

# Placeholder: call the widget checker tool

debug-load-fragments-wrapper --check-widget-baseline || ./tools/emergency-rollback.sh
```

## Maintenance checklist (summary)

- [ ] Backup current configs prior to promotion
- [ ] Run smoke tests after promotion
- [ ] Record startup timings for baseline comparison
- [ ] Run plugin cache refresh after significant plugin changes
- [ ] Verify symlinks and linked file integrity


## Acceptance criteria

- Documented routine tasks with commands and frequencies
- Emergency rollback steps present and tested manually during release cycles
- Telemetry guidance provided and privacy-preserving practices documented


## Related

- See: `060-risk-assessment.md` for risk details and runbooks
- Run smoke tests: `./tools/run-smoke-tests.sh --target 400-redesign`
- Return to [Redesign Index](../000-index.md) or [000-index](../000-index.md)
