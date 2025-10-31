# Plugin Loading Process Diagram

**Zgenom Plugin Management Detail** | **WCAG AA Compliant**

---

## 🔌 Detailed Plugin Loading Sequence

```mermaid
sequenceDiagram
    participant USER as 👤 .zshrc
    participant DECL as 📁 Declaration Files
    participant SETUP as ⚙️ .zgen-setup
    participant ZGENOM as 🔧 zgenom
    participant CACHE as 💾 Cache System
    participant GITHUB as 🌐 GitHub
    participant PLUGINS as ✨ Plugin Code

    USER->>DECL: Source .zshrc.add-plugins.d.00/*

    Note over DECL: Load 12 declaration files

    loop Each Declaration File
        DECL->>DECL: Execute file
        DECL->>DECL: zgenom load commands
    end

    Note over DECL: Commands queued (not executed)

    USER->>SETUP: Source .zgen-setup
    SETUP->>ZGENOM: Initialize zgenom

    alt Zgenom Not Installed
        ZGENOM->>GITHUB: Clone zgenom repository
        GITHUB-->>ZGENOM: zgenom code
    end

    ZGENOM->>CACHE: Check cache status

    alt Cache Invalid/Missing
        Note over CACHE: Need to rebuild

        loop Each Queued Plugin
            ZGENOM->>CACHE: Check if plugin exists

            alt Plugin Not Found
                ZGENOM->>GITHUB: Clone plugin repo
                GITHUB-->>ZGENOM: Plugin code
                ZGENOM->>CACHE: Store plugin
            end
        end

        ZGENOM->>ZGENOM: Generate init.zsh
        Note over ZGENOM: Build static load script

        ZGENOM->>CACHE: Write init.zsh
        Note over CACHE: ~500ms for cold start

    else Cache Valid
        Note over CACHE: Use existing init.zsh
        Note over CACHE: ~300ms for warm start
    end

    ZGENOM->>CACHE: Load init.zsh
    CACHE->>PLUGINS: Source plugin code

    Note over PLUGINS: ~40+ plugins initialize

    loop Each Plugin
        PLUGINS->>PLUGINS: Load plugin functions
        PLUGINS->>PLUGINS: Set plugin variables
        PLUGINS->>PLUGINS: Run plugin init code
    end

    PLUGINS-->>USER: All plugins active

    Note over USER: Phase 5 can now start<br/>Plugin functions available

```

---

## 🎯 Cache Strategy

```mermaid
stateDiagram-v2
    [*] --> CheckCache

    state CheckCache {
        [*] --> FileExists
        FileExists --> CheckTimestamp
        CheckTimestamp --> CheckPlugins
        CheckPlugins --> [*]
    }

    CheckCache --> Decision

    state Decision <<choice>>
    Decision --> Valid: Cache Valid
    Decision --> Invalid: Cache Invalid

    state Valid {
        [*] --> LoadInitZsh
        LoadInitZsh --> [*]
    }

    state Invalid {
        [*] --> CloneNew
        CloneNew --> UpdateExisting
        UpdateExisting --> GenerateInit
        GenerateInit --> [*]
    }

    Valid --> SourcePlugins
    Invalid --> SourcePlugins

    state SourcePlugins {
        [*] --> Plugin1
        Plugin1 --> Plugin2
        Plugin2 --> PluginN
        PluginN --> [*]
    }

    SourcePlugins --> [*]

```

---

## 📊 Plugin Load Order

```mermaid
graph TD
    START[🔧 zgenom Initialized] --> CAT1[Category: Performance]

    CAT1 --> P1[✅ mroth/evalcache]
    CAT1 --> P2[✅ mafredri/zsh-async]
    CAT1 --> P3[✅ romkatv/zsh-defer]

    P1 & P2 & P3 --> CAT2[Category: Development]

    CAT2 --> D1[✅ laravel/herd]
    CAT2 --> D2[✅ lukechilds/zsh-nvm]
    CAT2 --> D3[✅ git-extra-commands]
    CAT2 --> D4[✅ GitHub CLI]

    D1 & D2 & D3 & D4 --> CAT3[Category: Productivity]

    CAT3 --> PR1[✅ junegunn/fzf]
    CAT3 --> PR2[✅ Aloxaf/fzf-tab]
    CAT3 --> PR3[✅ agkozak/zsh-z]

    PR1 & PR2 & PR3 --> CAT4[Category: Optional]

    CAT4 --> O1[✅ hlissner/zsh-autopair]
    CAT4 --> O2[✅ olets/zsh-abbr]

    O1 & O2 --> COMPLETE[🎉 All Plugins Loaded]

    style START fill:#0080ff,stroke:#fff,stroke-width:3px,color:#fff

    style CAT1 fill:#cc7a00,stroke:#000,stroke-width:2px,color:#fff
    style P1 fill:#cc7a00,stroke:#000,stroke-width:2px,color:#fff
    style P2 fill:#cc7a00,stroke:#000,stroke-width:2px,color:#fff
    style P3 fill:#cc7a00,stroke:#000,stroke-width:2px,color:#fff

    style CAT2 fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff
    style D1 fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff
    style D2 fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff
    style D3 fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff
    style D4 fill:#0099cc,stroke:#fff,stroke-width:2px,color:#fff

    style CAT3 fill:#008066,stroke:#fff,stroke-width:2px,color:#fff
    style PR1 fill:#008066,stroke:#fff,stroke-width:2px,color:#fff
    style PR2 fill:#008066,stroke:#fff,stroke-width:2px,color:#fff
    style PR3 fill:#008066,stroke:#fff,stroke-width:2px,color:#fff

    style CAT4 fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff
    style O1 fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff
    style O2 fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff

    style COMPLETE fill:#008066,stroke:#fff,stroke-width:3px,color:#fff

```

---

**Navigation:** [← Phase Diagram](040-phase-diagram.md) | [Top ↑](#plugin-loading) | [Diagrams Index](000-index.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-30)*
