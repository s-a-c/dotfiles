# 070 - Maintenance Guide

## Top

Status: Draft

Last updated: 2025-10-07

This document describes ongoing maintenance and operational procedures for the ZSH REDESIGN project.

## Routine maintenance tasks

- Backup important dotfiles before large operations
- Validate symlink pointers and ensure active configuration is correct
- Refresh plugin caches (e.g., zgenom or similar) on a schedule

## Scheduled checks

- Weekly: run smoke tests and verify widget baseline remains steady
- Monthly: review optional plugin performance deltas

## Telemetry & diagnostics

- Collect lightweight startup timing locally and in CI to detect regressions (do not collect personal data or commands)
- Produce a short `startup-timings.csv` when running smoke tests for comparison

## Troubleshooting quick steps

- If the active configuration does not load, check symlink validity:

```bash
# Verify active symlink pointers
readlink .zshrc.d.active || echo "active pointer missing"
```

- If startup errors reference widget counts, run the widget baseline checker script in `debug-load-fragments-wrapper`

## Acceptance criteria

- Maintenance tasks documented with frequency and short command examples
- Emergency rollback and quick diagnostic steps present

## Related

- Return to [000-index](000-index.md) or [Redesign Index](../000-index.md)
