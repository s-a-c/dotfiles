# System Architecture Diagram

**Complete Visual Architecture** | **WCAG AA Compliant**

---

## 🎯 Complete System Architecture

```mermaid
graph TB
    subgraph USER["👤 User Layer"]
        TERM[Terminal Emulator<br/>iTerm2, Alacritty, Warp, etc.]
        SHELL[ZSH Shell Process]
    end

    subgraph CONFIG["⚙️ Configuration Layer 6 Phases"]
        direction TB

        P1[Phase 1: Environment<br/>.zshenv.01<br/>PATH, flags, XDG]
        P2[Phase 2: Orchestration<br/>.zshrc vendored<br/>Load controller]
        P3[Phase 3: Pre-Plugin<br/>.zshrc.pre-plugins.d.01/<br/>Safety guards, dev prep]
        P4[Phase 4: Plugin Loading<br/>.zshrc.add-plugins.d.00/<br/>40+ plugins via zgenom]
        P5[Phase 5: Post-Plugin<br/>.zshrc.d.01/<br/>Completions, UI, integration]
        P6[Phase 6: Finalization<br/>Platform + User<br/>macOS, .zshrc.local]

        P1 --> P2
        P2 --> P3
        P3 --> P4
        P4 --> P5
        P5 --> P6
    end

    subgraph FOUNDATION["🏗️ Foundation Services"]
        direction LR

        SYMLINK[Versioned Symlinks<br/>base → live → XX<br/>Atomic updates]
        SECURITY[Security System<br/>Nounset safety<br/>Path validation]
        PERF[Performance Monitor<br/>Segment tracking<br/>Timing analysis]
        PLUGIN_MGR[Plugin Manager<br/>zgenom<br/>40+ plugins]
    end

    subgraph FEATURES["✨ Feature Layer"]
        direction TB

        subgraph DEV["Development Tools"]
            PHP[PHP/Herd<br/>Version mgmt]
            NODE[Node.js/NVM<br/>Runtime mgmt]
            PYTHON[Python/UV<br/>Package mgmt]
            GIT[Git Tools<br/>Extra commands]
        end

        subgraph PROD["Productivity"]
            FZF[FZF<br/>Fuzzy finder]
            NAV[Navigation<br/>z, directory jump]
            COMP[Completions<br/>Tab completion]
            HIST[History<br/>Atuin sync]
        end

        subgraph UI["User Interface"]
            PROMPT[Starship Prompt<br/>Modern UI]
            THEME[Color Schemes<br/>Syntax highlight]
            KEYS[Keybindings<br/>Shortcuts]
        end
    end

    TERM --> SHELL
    SHELL --> P1
    P6 --> PROMPT

    P1 -.->|uses| SYMLINK
    P3 -.->|uses| SYMLINK
    P4 -.->|uses| SYMLINK
    P5 -.->|uses| SYMLINK

    P3 -.->|initializes| SECURITY
    P3 -.->|initializes| PERF
    P4 -.->|uses| PLUGIN_MGR

    PLUGIN_MGR -.->|provides| PHP
    PLUGIN_MGR -.->|provides| NODE
    PLUGIN_MGR -.->|provides| PYTHON
    PLUGIN_MGR -.->|provides| GIT
    PLUGIN_MGR -.->|provides| FZF
    PLUGIN_MGR -.->|provides| NAV
    PLUGIN_MGR -.->|provides| COMP
    PLUGIN_MGR -.->|provides| HIST

    P5 -.->|configures| COMP
    P5 -.->|configures| KEYS
    P5 -.->|configures| THEME

    style TERM fill:#0066cc,stroke:#fff,stroke-width:2px,color:#fff
    style SHELL fill:#0066cc,stroke:#fff,stroke-width:2px,color:#fff

    style P1 fill:#cc7a00,stroke:#000,stroke-width:3px,color:#fff
    style P2 fill:#006600,stroke:#fff,stroke-width:2px,color:#fff
    style P3 fill:#0080ff,stroke:#fff,stroke-width:2px,color:#fff
    style P4 fill:#cc0066,stroke:#fff,stroke-width:3px,color:#fff
    style P5 fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style P6 fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff

    style SYMLINK fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style SECURITY fill:#006600,stroke:#fff,stroke-width:2px,color:#fff
    style PERF fill:#cc7a00,stroke:#000,stroke-width:2px,color:#fff
    style PLUGIN_MGR fill:#0080ff,stroke:#fff,stroke-width:3px,color:#fff

    style PHP fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff
    style NODE fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff
    style PYTHON fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff
    style GIT fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff
    style FZF fill:#008066,stroke:#fff,stroke-width:2px,color:#fff
    style NAV fill:#008066,stroke:#fff,stroke-width:2px,color:#fff
    style COMP fill:#008066,stroke:#fff,stroke-width:2px,color:#fff
    style HIST fill:#008066,stroke:#fff,stroke-width:2px,color:#fff
    style PROMPT fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff
    style THEME fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff
    style KEYS fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff

```

---

## 📊 Layered Architecture View

```mermaid
graph TD
    subgraph L1["Layer 1: User Interaction"]
        USER[Terminal<br/>User Commands<br/>Shell Prompt]
    end

    subgraph L2["Layer 2: Shell Interface"]
        UI[Starship Prompt]
        COMP[Completions]
        KEYS[Keybindings]
        ALIAS[Aliases]
    end

    subgraph L3["Layer 3: Feature Layer"]
        FZF2[FZF Fuzzy Finder]
        NAV2[Navigation z]
        GIT2[Git Integration]
        DEV2[Dev Tools]
    end

    subgraph L4["Layer 4: Plugin System"]
        ZGENOM2[zgenom Manager]
        PLUGINS2[40+ Plugins]
        CACHE[Plugin Cache]
    end

    subgraph L5["Layer 5: Configuration"]
        POST[Post-Plugin<br/>.zshrc.d.01/]
        ADD[Plugin Decl<br/>.zshrc.add-plugins.d.00/]
        PRE[Pre-Plugin<br/>.zshrc.pre-plugins.d.01/]
        ENV2[Environment<br/>.zshenv.01]
    end

    subgraph L6["Layer 6: Foundation"]
        SYM[Versioned<br/>Symlinks]
        SEC[Security<br/>Safety]
        PERF2[Performance<br/>Monitoring]
    end

    USER --> UI
    UI --> FZF2
    COMP --> FZF2
    KEYS --> NAV2
    ALIAS --> DEV2

    FZF2 --> ZGENOM2
    NAV2 --> ZGENOM2
    GIT2 --> ZGENOM2
    DEV2 --> ZGENOM2

    ZGENOM2 --> PLUGINS2
    PLUGINS2 --> CACHE

    POST --> ADD
    ADD --> PRE
    PRE --> ENV2

    ENV2 --> SYM
    PRE --> SEC
    PRE --> PERF2

    style USER fill:#0066cc,stroke:#fff,stroke-width:3px,color:#fff
    style UI fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff
    style COMP fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff
    style KEYS fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff
    style ALIAS fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff
    style FZF2 fill:#008066,stroke:#fff,stroke-width:2px,color:#fff
    style NAV2 fill:#008066,stroke:#fff,stroke-width:2px,color:#fff
    style GIT2 fill:#008066,stroke:#fff,stroke-width:2px,color:#fff
    style DEV2 fill:#008066,stroke:#fff,stroke-width:2px,color:#fff
    style ZGENOM2 fill:#0080ff,stroke:#fff,stroke-width:3px,color:#fff
    style PLUGINS2 fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style CACHE fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff
    style POST fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style ADD fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff
    style PRE fill:#0080ff,stroke:#fff,stroke-width:2px,color:#fff
    style ENV2 fill:#cc7a00,stroke:#000,stroke-width:3px,color:#fff
    style SYM fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff
    style SEC fill:#006600,stroke:#fff,stroke-width:2px,color:#fff
    style PERF2 fill:#cc7a00,stroke:#000,stroke-width:2px,color:#fff

```

---

**Navigation:** [← Diagrams Index](000-index.md) | [Top ↑](#architecture-diagram) | [Startup Flow →](020-startup-flow.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-30)*
