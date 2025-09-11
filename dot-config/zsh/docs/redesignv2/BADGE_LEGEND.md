# Badge Legend — GOAL and Summary (redesignv2)
Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md vb7f03a299a01b1b6d7c8be5a74646f0b5127cbc5b5d614c8b4c20fc99bc21620

This document explains the structure, color mapping, and dynamic suffix composition for the GOAL badges published by the ZSH Redesign v2 pipeline.

- Source scripts:
  - dotfiles/dot-config/zsh/tools/generate-goal-state-badge.zsh
  - dotfiles/dot-config/zsh/tools/generate-summary-goal-badge.zsh
- Published artifacts (preferred root):
  - dotfiles/dot-config/zsh/docs/redesignv2/artifacts/badges/goal-state.json
  - dotfiles/dot-config/zsh/docs/redesignv2/artifacts/badges/summary-goal.json

Handy shields endpoints (README placeholders are auto-resolved by CI after the first gh-pages publish):
- Goal-state (flat)
  - https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/<org>/<repo>/gh-pages/badges/goal-state.json
- Summary-goal (compact)
  - https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/<org>/<repo>/gh-pages/badges/summary-goal.json

Note: The publisher workflow also maintains legacy paths under docs/redesign/badges for a transitional period.


## 1) Goal-State Badge

File: docs/redesignv2/artifacts/badges/goal-state.json

Purpose: A tiny, declarative snapshot of the current GOAL profile states.

Default mapping if no inputs are present:
- governance: clean
- ci: strict
- streak: building
- explore: sandbox

Dynamic mapping when perf-current.json exists:
- governance
  - clean when overall_status=OK and no partial and no synthetic_used
  - warning when overall_status=WARN
  - failing when overall_status=FAIL
- ci
  - strict when GOAL=ci and mode=enforce
  - lenient otherwise
- streak
  - building when partial tolerated
  - stable otherwise
- explore
  - sandbox

Example:
```json
{
  "governance": "clean",
  "ci": "strict",
  "streak": "building",
  "explore": "sandbox",
  "generated_at": "2025-09-11T13:53:17+01:00",
  "source": "tools/generate-goal-state-badge.zsh"
}
```


## 2) Summary-Goal Badge

File: docs/redesignv2/artifacts/badges/summary-goal.json

Purpose: A compact, single endpoint that blends GOAL states with performance drift and structure health signals. It chooses the worst severity across all inputs, sets a single color, and appends compact suffixes when available.

Message format:
- gov:<state> | ci:<state> | streak:<state> | explore:<state> [ | drift:<msg> | struct:<msg> ]

Where suffixes come from:
- drift: taken from docs/redesignv2/artifacts/badges/perf-drift.json "message" (e.g., 2 warn (+7.1% max))
- struct: taken from docs/redesignv2/artifacts/badges/structure.json "message" (e.g., 2 violations)

Severity collapse to color:
- Inputs considered
  - Base GOAL state collapse (governance, ci, streak, explore)
  - perf drift badge (if present)
  - structure badge (if present)
- Severity rules (worst severity wins)
  - 0 (OK) → brightgreen
  - 1 (info/minor) → blue
  - 2 (warning) → yellow
  - 3 (failing) → red (isError=true)

Perf drift severity rules:
- color=red or message indicates fail → 3
- color=yellow or message indicates warn → 2
- non-empty, non-zero message → 1
- otherwise → 0

Structure severity rules:
- color=red → 3
- color=yellow → 2
- color=green → 0
- any other/unknown color → 1

Resilience:
- If perf-drift.json and/or structure.json are missing or empty:
  - No suffix is added
  - Overall severity is not raised due to the absence

Example (with suffixes):
```json
{
  "schemaVersion": 1,
  "label": "goal",
  "message": "gov:clean | ci:strict | streak:building | explore:sandbox | drift:2 warn (+7.1% max) | struct:2 violations",
  "color": "yellow",
  "namedLogo": "zsh",
  "cacheSeconds": 300,
  "isError": false,
  "_source": "tools/generate-summary-goal-badge.zsh"
}
```


## 3) Color and State Mapping Details

Base GOAL severity contributors:
- governance
  - failing → severity 3
  - warning → severity 2
  - clean → severity 0
  - other/unknown → severity 1
- ci
  - strict → severity 0
  - lenient or unknown → severity 1
- streak
  - stable → severity 0
  - building or unknown → severity 1
- explore
  - sandbox → severity 0
  - other/unknown → severity 1

Collapsed color:
- 3 → red
- 2 → yellow
- 1 → blue
- 0 → brightgreen

isError:
- true when final collapsed severity is 3 (red)
- false otherwise


## 4) Inputs the Summary Badge Reads

- Goal-state source:
  - docs/redesignv2/artifacts/badges/goal-state.json
- Optional suffix sources:
  - docs/redesignv2/artifacts/badges/perf-drift.json (drift)
  - docs/redesignv2/artifacts/badges/structure.json (struct)
- The generator gracefully handles missing files by omitting suffixes and not raising severity.


## 5) CI Integration

Workflows:
- dotfiles/.github/workflows/perf-classifier-ci.yml (macos-latest)
  - GOAL=ci enforce
  - Emits docs/redesignv2/artifacts/metrics/perf-current.json
  - Generates goal-state.json
- dotfiles/.github/workflows/zsh-badges-and-metrics.yml (ubuntu-latest)
  - On push/PR and nightly (03:00 UTC)
  - Runs classifier (GOAL=ci enforce)
  - Generates:
    - badges/goal-state.json
    - badges/summary-goal.json
  - Ensures perf-drift.json and structure.json exist (re-generates if missing)
  - Publishes badges/metrics to gh-pages with HTML index
  - Post-publish: resolves README badge endpoint placeholders to actual <org>/<repo>
  - Assertion: fails the run if summary-goal.json color resolves to red (governance/drift/structure failing)

Note: gawk is ensured in macos-latest; ubuntu-latest typically includes GNU awk. The system skips dependency-heavy tests when unavailable.


## 6) Local Usage

Generate goal-state:
```sh
dotfiles/dot-config/zsh/tools/generate-goal-state-badge.zsh \
  --output dotfiles/dot-config/zsh/docs/redesignv2/artifacts/badges/goal-state.json
```

Generate summary-goal (reads goal-state and optional suffix sources):
```sh
dotfiles/dot-config/zsh/tools/generate-summary-goal-badge.zsh \
  --output dotfiles/dot-config/zsh/docs/redesignv2/artifacts/badges/summary-goal.json \
  --label goal --logo zsh --cache-seconds 300
```

Environment overrides:
- SUMMARY_GOAL_INPUT, SUMMARY_GOAL_OUTPUT, SUMMARY_GOAL_LABEL, SUMMARY_GOAL_LOGO, SUMMARY_GOAL_CACHE_SECONDS


## 7) Tests

- GOAL classifier tests:
  - dotfiles/dot-config/zsh/tests/performance/classifier/test-goal-*.zsh
- Summary-goal suffix composition:
  - dotfiles/dot-config/zsh/tests/performance/badges/test-summary-goal-suffix.zsh

These validate:
- JSON emission parity (single- and multi-metric)
- Clean logs (stderr noise suppressed by the runner)
- Summary suffix and severity blending correctness


## 8) Future Mapping Refinements (optional)

- Governance
  - Optionally treat BASELINE_CREATED as informational (severity 1) rather than clean (severity 0)
- CI
  - Consider alternative message detail levels for strict vs lenient states
- Streak
  - Consider differentiating building states based on number/nature of missing metrics


## 9) Troubleshooting

- summary-goal.json color is red:
  - Indicates a failing governance state or a red perf/structure badge
  - CI may fail by assertion in zsh-badges-and-metrics workflow
- Missing suffixes:
  - Ensure perf-drift.json and structure.json are present and non-empty
  - The generator intentionally does not raise severity due to missing suffix inputs
- Endpoint URLs in README show placeholders:
  - CI post-publish step rewrites placeholders to the real <org>/<repo> once gh-pages is populated


--- 

Last updated: 2025-09-11