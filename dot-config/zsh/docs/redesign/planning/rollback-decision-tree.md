# Rollback Decision Tree
Date: 2025-08-30
Status: Planning Artifact

```mermaid
flowchart TD
    A[Issue Detected Post-Migration] --> B{Category}
    B -->|Perf Regression >5% and <20%| C[Investigate recent modules 70/80]
    B -->|Perf Regression ≥20%| D[Immediate Rollback to Baseline Tag]
    B -->|Functional Break (Missing Function)| E[Re-enable Legacy Dir Temporarily]
    B -->|Security Hash Failures| F[Disable 80-security-validation]
    B -->|Startup Crash| G[Restore Backup Directory]

    C --> H{Root Cause Identified?}
    H -->|Yes| I[Patch Module & Re-Benchmark]
    H -->|No| D
    E --> I
    F --> J[Run Minimal Integrity Stub Only]
    J --> I
    G --> K[Validate Baseline Behavior]
    K --> I
    I --> L{Thresholds Passed?}
    L -->|Yes| M[Continue Redesign]
    L -->|No| D

    D --> N[Tag rollback-DATE]
    N --> O[Open Incident Doc]
    O --> P[Plan Fix & Reattempt]
```

## Usage
- Follow decision path based on first failing gate (performance, security, functionality, stability).
- Always preserve artifacts (perf-current.json, structure-audit.json) before rollback actions.

## Exit Criteria After Rollback
| Criterion | Condition |
|-----------|-----------|
| Baseline Restored | All original modules sourcing w/out error |
| Metrics Revalidated | perf-current within 3% of baseline mean |
| Incident Logged | Document created & committed |

---
(End rollback decision tree)

---
**Navigation:** [← Previous: Testing Strategy](testing-strategy.md) | [Next: Back to Index →](../README.md) | [Top](#) | [Back to Index](../README.md)
