# Symlink Chain Diagram

**Version Management Visualization** | **WCAG AA Compliant**

---

## 🔗 Symlink Chain Architecture

### Three-Tier System

```mermaid
graph LR
    subgraph USER["👤 User/System Code"]
        REF[References:<br/>.zshrc.d/file.zsh]
    end

    subgraph TIER1["Tier 1: Base Symlink"]
        BASE[.zshrc.d<br/>symlink]
    end

    subgraph TIER2["Tier 2: Live Pointer"]
        LIVE[.zshrc.d.live<br/>symlink]
    end

    subgraph TIER3["Tier 3: Actual Files"]
        V01[.zshrc.d.01/<br/>📁 directory]
        FILES[400-options.zsh<br/>410-completions.zsh<br/>420-terminal.zsh<br/>...14 files total]
    end

    subgraph ALTERNATE["Other Versions (Inactive)"]
        V00[.zshrc.d.00/<br/>📁 previous]
        V02[.zshrc.d.02/<br/>📁 development]
    end

    REF -.->|resolves to| BASE
    BASE -->|points to| LIVE
    LIVE -->|points to| V01
    V01 --> FILES

    LIVE -.->|can point to| V00
    LIVE -.->|can point to| V02

    style REF fill:#0066cc,stroke:#fff,stroke-width:2px,color:#fff
    style BASE fill:#cc7a00,stroke:#000,stroke-width:3px,color:#fff
    style LIVE fill:#cc6600,stroke:#000,stroke-width:3px,color:#fff
    style V01 fill:#008066,stroke:#fff,stroke-width:3px,color:#fff
    style FILES fill:#006600,stroke:#fff,stroke-width:2px,color:#fff
    style V00 fill:#cc0066,stroke:#fff,stroke-width:1px,stroke-dasharray: 5 5,color:#fff
    style V02 fill:#0080ff,stroke:#fff,stroke-width:1px,stroke-dasharray: 5 5,color:#fff

```

---

## 📊 All Versioned Components

### Complete Symlink Map

```mermaid
graph TD
    subgraph ENV["Environment"]
        ENV_BASE[.zshenv] --> ENV_LIVE[.zshenv.live]
        ENV_LIVE --> ENV_V1[.zshenv.01<br/>1,415 lines]
    end

    subgraph PRE["Pre-Plugin"]
        PRE_BASE[.zshrc.pre-plugins.d] --> PRE_LIVE[.zshrc.pre-plugins.d.live]
        PRE_LIVE --> PRE_V1[.zshrc.pre-plugins.d.01/<br/>7 files]
    end

    subgraph ADD["Plugin Declarations"]
        ADD_BASE[.zshrc.add-plugins.d] --> ADD_LIVE[.zshrc.add-plugins.d.live]
        ADD_LIVE --> ADD_V0[.zshrc.add-plugins.d.00/<br/>12 files]
    end

    subgraph POST["Post-Plugin"]
        POST_BASE[.zshrc.d] --> POST_LIVE[.zshrc.d.live]
        POST_LIVE --> POST_V1[.zshrc.d.01/<br/>14 files]
    end

    style ENV_BASE fill:#cc7a00,stroke:#000,stroke-width:2px,color:#fff
    style ENV_LIVE fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff
    style ENV_V1 fill:#008066,stroke:#fff,stroke-width:2px,color:#fff

    style PRE_BASE fill:#0080ff,stroke:#fff,stroke-width:2px,color:#fff
    style PRE_LIVE fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff
    style PRE_V1 fill:#008066,stroke:#fff,stroke-width:2px,color:#fff

    style ADD_BASE fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff
    style ADD_LIVE fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff
    style ADD_V0 fill:#008066,stroke:#fff,stroke-width:2px,color:#fff

    style POST_BASE fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style POST_LIVE fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff
    style POST_V1 fill:#008066,stroke:#fff,stroke-width:2px,color:#fff

```

---

## 🔄 Version Switching Process

```mermaid
sequenceDiagram
    participant User
    participant Live as .zshrc.d.live
    participant V01 as .zshrc.d.01
    participant V02 as .zshrc.d.02

    Note over Live,V01: Current: Live → V01

    User->>V02: cp -R .zshrc.d.01 .zshrc.d.02
    Note over V02: Create new version

    User->>V02: Edit files in .02
    Note over V02: Make changes

    User->>V02: Test new version
    Note over V02: Verify works

    User->>Live: ln -snf .zshrc.d.02 .zshrc.d.live
    Note over Live,V02: Switch pointer

    Live-->>V02: Now points to V02
    Note over Live,V02: New shells use V02

    Note over V01: V01 still exists<br/>for rollback

    alt If problem found
        User->>Live: ln -snf .zshrc.d.01 .zshrc.d.live
        Live-->>V01: Rollback to V01
        Note over Live,V01: Instant recovery
    end

```

---

## 🎨 Visual Comparison

### Before Update

```text
User Code
    ↓
.zshrc.d ──→ .zshrc.d.live ──→ .zshrc.d.01/
                                    ├─ 400-options.zsh
                                    ├─ 410-completions.zsh
                                    └─ ...

.zshrc.d.00/ (previous, inactive)
.zshrc.d.02/ (doesn't exist yet)

```

### After Creating New Version

```text
User Code
    ↓
.zshrc.d ──→ .zshrc.d.live ──→ .zshrc.d.01/  ✅ Active
                                    ├─ 400-options.zsh
                                    └─ ...

.zshrc.d.00/ (previous, inactive)
.zshrc.d.02/  ⚙️ Development
    ├─ 400-options.zsh (modified)
    ├─ 540-new-feature.zsh (new!)
    └─ ...

```

### After Activating New Version

```text
User Code
    ↓
.zshrc.d ──→ .zshrc.d.live ──→ .zshrc.d.02/  ✅ Active
                                    ├─ 400-options.zsh (modified)
                                    ├─ 540-new-feature.zsh (new!)
                                    └─ ...

.zshrc.d.01/ (previous, for rollback)
.zshrc.d.00/ (old, can delete)

```

---

**Navigation:** [← Startup Flow](020-startup-flow.md) | [Top ↑](#symlink-chain) | [Phase Diagram →](040-phase-diagram.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-30)*
