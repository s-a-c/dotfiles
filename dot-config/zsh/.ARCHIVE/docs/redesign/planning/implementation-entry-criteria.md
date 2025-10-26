# Implementation Entry Criteria
Date: 2025-08-30
Status: Draft (Freeze once all criteria satisfied)

## 1. Purpose
Define mandatory prerequisites before beginning ANY concrete migration or renaming for either pre-plugin or post-plugin redesign directories.

## 2. Gate Categories
| Category | Criteria | Evidence Artifact | Status |
|----------|----------|-------------------|--------|
| Baseline Performance | perf-baseline captured (≥10 valid runs, stddev ≤12%) – filtered_mean=4772ms (rel 2.62%) | `docs/redesign/metrics/perf-baseline.json` | ✅ |
| Structural Audit (Post-Plugin) | Current structure audit JSON & MD present | `structure-audit.json` + MD marker | ⬜ |
| Structural Inventory (Pre-Plugin) | Pre-plugin file list snapshotted | `docs/redesign/planning/preplugin-inventory.txt` | ⬜ |
| Prefix Spec | Prefix spec approved & frozen | `prefix-reorg-spec.md` (commit `docs(prefix): freeze`) | ⬜ |
| Compinit Plan | Compinit audit plan merged | `compinit-audit-plan.md` | ✅ |
| Pre-Plugin Spec | Pre-plugin redesign spec merged | `pre-plugin-redesign-spec.md` | ✅ |
| Baseline Metrics Plan | Plan doc merged | `baseline-metrics-plan.md` | ✅ |
| Rollback Decision Tree | Diagram committed | `rollback-decision-tree.md` | ⬜ |
| Test Scaffolds | Design tests (skeleton counts) drafted but ALLOW legacy until flag | `tests/style/*` (planned) | ⬜ |
| Promotion Guard Extension | Guard updated to parse markdown summary (done) | `tools/promotion-guard.zsh` | ✅ |
| CI Awareness | Perf & structure workflows exist (even if permissive) | `.github/workflows/*` | ✅ |
| Documentation Index | README updated with new planning docs | `docs/README.md` | ⬜ |

Baseline note: Filtered relative stddev 2.62% (below 12% threshold); discarded_count=0.

## 3. Entry Gate Rule
No migration branches (skeleton creation, file renames) may merge until ALL criteria above = Complete (✅). Exception: test scaffolds can be merged concurrently with skeleton as they enforce only additive expectations.

## 4. Verification Checklist (To Complete Immediately Before Migration Commit)
- [ ] `git status` clean; no untracked modified core config files.
- [ ] Baseline branch tagged `refactor-baseline`.
- [ ] Backup directory `.zshrc.d.backup-<timestamp>` created & perms a-w.
- [ ] Pre-plugin inventory file present & matches live directory count.
- [ ] Perf baseline mean recorded & improvement target computed (target mean ≤ baseline_mean * 0.8).
- [ ] No unclassified Critical issues in issues.md.
- [ ] All planning docs referenced in docs index.
- [ ] Rollback decision tree present and linked.

## 5. Rollback Preconditions
Before migration, confirm ability to revert via:
```bash
git tag -l | grep refactor-baseline
[ -d .zshrc.d.backup-* ] || echo 'Missing backup'
```
If either missing → BLOCK entry.

## 6. Sign-off Procedure
1. Maintainer opens PR: "Enter Implementation Phase" referencing this checklist.
2. CI attaches artifacts (baseline JSON, structure audit) to PR as evidence.
3. Reviewer fills status table (modifiable section at bottom) & merges upon all checkmarks.
4. Commit message: `chore(entry): declare implementation phase start`.

## 7. Status Table (Mutable)
| Criterion | Status | Reviewer | Date |
|-----------|--------|----------|------|
| Baseline Performance | ✅ (4772ms ±2.62%) |  | 2025-08-30 |
| Structural Audit (Post) | ⬜ |  |  |
| Pre-Plugin Inventory | ⬜ |  |  |
| Prefix Spec Frozen | ⬜ |  |  |
| Rollback Diagram | ⬜ |  |  |
| Tests Scaffolded | ⬜ |  |  |
| README Updated | ⬜ |  |  |

---
**Navigation:** [← Previous: Compinit Audit Plan](compinit-audit-plan.md) | [Next: Testing Strategy →](testing-strategy.md) | [Top](#) | [Back to Index](../README.md)

---
(End implementation entry criteria)
