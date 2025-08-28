# Styling Architecture (Planned Modular System)

Return: [Index](../README.md) | Related: [Improvement Plan](../030-improvements/010-comprehensive-improvement-plan.md) | Phases: [Phase 02](../030-improvements/030-phases/phase-02-styling-modularization-extraction.md)

## 1. Objectives
Provide a maintainable, testable, theme‑capable styling system replacing the monolithic zstyle block with:
- Palette core + variant overlays
- Declarative registration API (no immediate side effects)
- Domain modules (completion, matching, git, process, fzf-tab, prompt overrides)
- Finalizer ensuring idempotent style application & snapshotting

## 2. Module Layout (Target)
```
.zshrc.d/40-styles/
  00-palette-core.zsh              # Base named colors (INFO/WARN/ACCENT...)
  05-palette-variants/             # Swappable themes
    catppuccin-macchiato.zsh
    catppuccin-latte.zsh
  10-style-api.zsh                 # style_register, style_apply_domain, style_snapshot
  20-completion-styles.zsh         # Generic completion behaviors
  25-completion-matching.zsh       # matcher-list, accept-exact, menu select
  30-git-styles.zsh                # Git completion user commands & formatting
  35-process-styles.zsh            # Process list colors, users filtering
  40-fzf-tab-styles.zsh            # fzf-tab zstyles
  70-p10k-overrides.zsh            # Post prompt manager visual overrides
  90-style-finalizer.zsh           # Aggregation & application (guarded)
```

## 3. Style API (Concept)
```zsh
# 10-style-api.zsh (skeleton)
# Guard redefinition
[[ -n ${ZSH_STYLE_API_LOADED:-} ]] && return
ZSH_STYLE_API_LOADED=1

typeset -gA _STYLE_REGISTRY   # key: domain::pattern -> value

style_register() {
  local domain=$1 pattern=$2 assignment=$3
  _STYLE_REGISTRY["${domain}::${pattern}"]=$assignment
}

style_apply_domain() {
  local domain=$1 k v
  for k v in ${(kv)_STYLE_REGISTRY}; do
    [[ $k == ${domain}::* ]] || continue
    local pat=${k#${domain}::}
    # Expect assignment is already 'use-cache on' etc.
    zstyle $pat $v
  done
}

style_snapshot() {
  local out=${1:-$ZDOTDIR/saved_zstyles.zsh}
  zstyle -L >| $out
}

style_apply_all() {
  [[ -n ${ZSH_STYLES_APPLIED:-} ]] && return
  local domains=(palette completion matching git process fzf-tab prompt)
  for d in $domains; do
    style_apply_domain $d
  done
  style_snapshot
  ZSH_STYLES_APPLIED=1
}
```

## 4. Palette Strategy
| Concern | Approach | Rationale |
|---------|----------|-----------|
| 24-bit terminals | Use RGB escape sequences | Full fidelity |
| 8/16 color fallback | Map to nearest base names | Accessibility |
| Variant selection | `ZSH_STYLE_VARIANT` env | Easy runtime switch |
| Safe mode | Skip variants if fails; fallback to core | Robustness |

## 5. Migration Phases
| Phase | Task | Ref Tasks |
|-------|------|----------|
| 02 | Extract existing zstyles into grouped modules (still direct zstyle) | TASK-MAJ-02 |
| 03 | Introduce palette + replace literals with names | TASK-MAJ-11 / TASK-MIN-07 |
| 03 | Add style API + registration refactor | TASK-MAJ-12 |
| 04 | Remove legacy, add variants + fallback + snapshot diff test | TASK-MAJ-13 / TASK-MIN-11..13 |

## 6. Tests
| Test | Purpose | Phase |
|------|---------|-------|
| style snapshot diff | Ensure stable ordering & diffable changes | 04 |
| variant switch | Palette lines change only | 04 |
| low-color fallback | Terminal forcing 8color yields fallback palette | 04 |

## 7. KPIs
| KPI | Baseline | Target |
|-----|----------|--------|
| Startup parse time (styling) | ~N/A (monolithic) | -30–50ms |
| Lines changed between variants | Large | Palette-only lines |
| Style reapply occurrences | >1 sporadic | Exactly 1 |

## 8. Rollback
If finalizer fails: set `ZSH_STYLES_SAFE_MODE=1` and source legacy backup file (kept during Phase 03–04). Provide log message tagging failure cause.

## 9. Cross-References
- Improvement tasks: TASK-MAJ-11..13, TASK-MIN-07, TASK-MIN-11..13
- Consolidation plan migration steps 8–16

---
Generated: 2025-08-24
