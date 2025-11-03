# ZSH Configuration Redesign – Visual Documentation
Date: 2025-08-29
Accessibility: Palette avoids red/green; uses blue (#1f77b4), orange (#ff7f0e), gray (#7f7f7f), accent teal (#17becf). Shapes & emojis reinforce semantics.

---
## 1. Current Configuration Relationships
```mermaid
flowchart TD
    subgraph A0[Core Files]
        ZENV[.zshenv 📦 Env & early vars]:::core
        ZRC[.zshrc 🚀 Main orchestrator]:::core
        ZGENSET[.zgen-setup 🧩]:::plugin
    end
    subgraph A1[Pre-Plugin Phase]
        PP0[00_00-critical-path-fix]:::pre
        PP1[00_01-path-resolution-fix]:::pre
        PP2[00_05-path-guarantee]:::pre
        PP3[00_10-fzf-setup]:::pre
        PP4[00_30-lazy-loading-framework]:::pre
        PP5[10_30-lazy-direnv]:::pre
        PP6[10_40-lazy-git-config]:::pre
        PP7[10_50-lazy-gh-copilot]:::pre
        PP8[20_10-ssh-agent-core]:::pre
        PP9[20_11-ssh-agent-security]:::pre
    end
    subgraph A2[Active Post-Plugin]
        PI0[00_20-plugin-integrity-core 🔐]:::security
        PI1[00_21-plugin-integrity-advanced 🛡️]:::security
        OPT[00_60-options ⚙️]:::config
        ESS[20_04-essential 🧩]:::plugin
        PROMPT[30_30-prompt 🎨]:::ui
    end
    subgraph A3[Disabled Legacy]
        LENV[00_10-environment]:::legacy
        LPATH[00_02-path-system.*]:::legacy
        LFN[00_70-functions-core]:::legacy
        LSEC[00_80-security-check]:::legacy
        LDEV[10_00-development-tools]:::legacy
        LALIA[30_10-aliases]:::legacy
        LKEY[30_20-keybindings]:::legacy
        LPMON[00_30-performance-monitoring]:::legacy
        LDFR[20_12-plugin-deferred-core]:::legacy
        LSPL[99_99-splash]:::legacy
    end
    ZENV --> ZRC
    ZRC --> A1 --> ZGENSET --> A2 --> A3
    ZRC --> A2
    classDef core fill:#1f77b4,stroke:#0d3d63,color:#fff
    classDef pre fill:#90c2e7,stroke:#1f77b4,color:#003049
    classDef plugin fill:#ffaf5e,stroke:#ff7f0e,color:#4a2b00
    classDef security fill:#7f7f7f,stroke:#555,color:#fff
    classDef config fill:#b5b5b5,stroke:#555,color:#222
    classDef ui fill:#17becf,stroke:#0e6f78,color:#00363a
    classDef legacy fill:#ececec,stroke:#999,color:#555
```

---
## 2. Proposed Redesign Structure
```mermaid
flowchart LR
    subgraph NEW[.zshrc.d.REDESIGN]
        N00[00-security-integrity 🔐 ~5ms]:::security
        N05[05-interactive-options ⚙️ ~3ms]:::config
        N10[10-core-functions 🧰 ~8ms]:::core
        N20[20-essential-plugins 🧩 guard ~15ms]:::plugin
        N30[30-development-env 🛠️ ~10ms]:::plugin
        N40[40-aliases-keybindings ⌨️ ~5ms]:::config
        N50[50-completion-history 📘 ~12ms]:::config
        N60[60-ui-prompt 🎨 starship/p10k ~40ms]:::ui
        N70[70-performance-monitoring 🧪 defer ~2ms]:::perf
        N80[80-security-validation 🛡️ async ~0ms upfront]:::security
        N90[90-splash ✅ ~2ms]:::ui
    end
    ZRC[.zshrc 🚀]:::core --> N00 --> N05 --> N10 --> N20 --> N30 --> N40 --> N50 --> N60 --> N70 --> N80 --> N90
    classDef core fill:#1f77b4,stroke:#0d3d63,color:#fff
    classDef plugin fill:#ffaf5e,stroke:#ff7f0e,color:#4a2b00
    classDef security fill:#7f7f7f,stroke:#555,color:#fff
    classDef config fill:#b5b5b5,stroke:#555,color:#222
    classDef ui fill:#17becf,stroke:#0e6f78,color:#00363a
    classDef perf fill:#c9d1d9,stroke:#555,color:#222
```
Legend: Approximate synchronous cost; async work excluded.

---
## 3. Migration Flow
```mermaid
flowchart TD
    A[Start] --> B[Baseline Perf collect]
    B --> C[Backup created]
    C --> D[Create REDESIGN dir]
    D --> E[Populate Phase 1]
    E --> F[Enable Flag]
    F --> G[A/B Test]
    G --> H{20%+ gain?}
    H -->|Yes| I[Promote]
    H -->|No| J[Tune & Retry]
    I --> K[Diff & Docs]
    K --> L[Finalize]
    J --> G
    classDef default fill:#1f77b4,stroke:#0d3d63,color:#fff
    classDef decision fill:#ffaf5e,stroke:#c45e00,color:#4a2b00
    classDef done fill:#17becf,stroke:#0e6f78,color:#00363a
    class H decision
    class I,K,L done
```

---
## 4. Loading Sequence (Simplified Gantt)
```mermaid
gantt
    dateFormat  X
    title Startup Order (Abstract Slots)
    section Core
    .zshenv ~5ms          :done,    a1, 0, 5
    .zshrc bootstrap ~8ms :active,  a2, 5, 5
    section Pre-Plugin
    Pre-plugins ~20ms     :a3, 10, 8
    zgenom init ~120ms    :a4, 18, 10
    section Post-Plugin Core
    00-security ~5ms      :a5, 28, 2
    05-options ~3ms       :a6, 30, 2
    10-functions ~8ms     :a7, 32, 2
    20-essential ~15ms    :a8, 34, 3
    30-dev-env ~10ms      :a9, 37, 3
    40-aliases ~5ms       :a10,40, 2
    50-completion ~12ms   :a11,42, 3
    60-ui-prompt ~40ms    :a12,45, 4
    section Deferred
    70-perf hook ~2ms     :a13,49, 5
    80-security async     :a14,54, 6
    90-splash ~2ms        :a15,60, 1
```

---
## 5. Async & Lazy Interaction
```mermaid
sequenceDiagram
    participant U as User
    participant SH as Shell
    participant SEC as 00-sec
    participant FN as 10-fn
    participant PERF as 70-perf
    participant VAL as 80-validate
    U->>SH: Launch shell
    SH->>SEC: Init security (~5ms)
    SH->>FN: Source functions (~8ms)
    SH-->>U: First prompt (TTFP)
    par Post-Prompt Async
      SH->>PERF: Start perf capture (~2ms)
      SH->>VAL: Queue deep integrity
    end
    U->>SH: plugin_security_status
    SH->>VAL: Query status
    VAL-->>U: Progress report
```

---
## 6. Completion Workflow (Corrected)
```mermaid
flowchart LR
    A[Shell Start] --> B[Read auto flags]
    B --> C{Auto compinit?}
    C -->|No| D[Defer until fpath ready]
    C -->|Yes| E[Prepare fpath]
    D --> E
    E --> F[Run compinit once]
    F --> G[Load or build zcompdump]
    G --> H{Cache fresh?}
    H -->|Yes| I[Reuse cache]
    H -->|No| J[Regenerate dump]
    I --> K[Completion Active]
    J --> K
    K --> L[Apply zstyles]
    classDef stage fill:#1f77b4,stroke:#0d3d63,color:#fff
    classDef decision fill:#ffaf5e,stroke:#c45e00,color:#4a2b00
    class C,H decision
    class A,B,D,E,F,G,I,J,K,L stage
```

---
## 7. Consolidation Diff (Current → Redesign)
```mermaid
flowchart LR
    subgraph CUR[Current Fragments]
      A1[00_20-core integrity]
      A2[00_21-adv integrity]
      A3[00_60-options]
      A4[20_04-essential]
      A5[30_30-prompt]
      L1[10_x dev set]
      L2[30_10-aliases]
      L3[30_20-keybindings]
      L4[00_30-perf-monitor]
    end
    subgraph NEW[Redesign Modules]
      N0[00-security-integrity]
      N5[05-interactive-options]
      N1[10-core-functions]
      N2[20-essential-plugins]
      N3[30-development-env]
      N4[40-aliases-keybindings]
      N6[50-completion-history]
      N7[60-ui-prompt]
      N8[70-performance-monitoring]
      N9[80-security-validation]
    end
    A1 --> N0
    A2 --> N9
    A3 --> N5
    A4 --> N2
    A5 --> N7
    L1 --> N3
    L2 --> N4
    L3 --> N4
    L4 --> N8
    classDef default fill:#ffaf5e,stroke:#c45e00,color:#4a2b00
    classDef new fill:#1f77b4,stroke:#0d3d63,color:#fff
    class N0,N5,N1,N2,N3,N4,N6,N7,N8,N9 new
```

---
## 8. Plugin Integrity Phases
```mermaid
flowchart TB
    S0[Startup] --> P0[00-security-integrity register minimal registry ~5ms]
    P0 --> P1{Strict mode?}
    P1 -->|Yes| P2[Basic hash core plugins ~25ms]
    P1 -->|No| P3[Defer advanced hashing]
    P2 --> P4[Expose status function]
    P3 --> P4[Expose status function]
    P4 --> A0[After first prompt trigger async]
    A0 --> A1[Queue deep hash]
    A1 --> A2[Update registry diffs]
    A2 --> A3[Log violations]
    A3 --> UQ[User runs status]
    UQ --> RPT[Summarize baseline + delta]
    classDef phase fill:#1f77b4,stroke:#0d3d63,color:#fff
    classDef decision fill:#ffaf5e,stroke:#c45e00,color:#4a2b00
    classDef async fill:#7f7f7f,stroke:#555,color:#fff
    class P0,P2,P3,P4,A1,A2,A3,RPT phase
    class P1 decision
    class A0,UQ async
```

---
## 9. Minimal Test Render (Validation Snippet)
```mermaid
flowchart LR
  X[Test Render] --> Y[OK]
```

---
## 10. Color & Symbol Reference
| Emoji | Meaning |
|-------|---------|
| 🔐 / 🛡️ | Security (lightweight / advanced) |
| ⚙️ | Interactive options / configuration |
| 🧰 | Core reusable functions |
| 🧩 | Plugin management or essential set |
| 🛠️ | Development tooling environment |
| ⌨️ | Aliases & keybindings |
| 📘 | Completion & history styling |
| 🎨 | UI & prompt theming |
| 🧪 | Performance monitoring |
| ✅ | Finalization / splash |
| 📄 | Legacy/archived |

---
Generated as part of redesign planning deliverables.
