# Startup Flow Diagram

**Interactive Startup Sequence** | **WCAG AA Compliant**

---

## 🔄 Complete Startup Flowchart

```mermaid
flowchart TD
    START([👤 User Opens<br/>Terminal]) --> CHECK_ENV{.zshenv<br/>exists?}

    CHECK_ENV -->|Yes| LOAD_ENV[📄 Load .zshenv.01<br/>~100ms]
    CHECK_ENV -->|No| ERR_ENV[❌ Error:<br/>Missing environment]

    LOAD_ENV --> ENV_TASKS[🔧 Environment Setup<br/>• Set PATH<br/>• Configure 70+ flags<br/>• XDG directories<br/>• Terminal detection]

    ENV_TASKS --> INTERACTIVE{Interactive<br/>shell?}

    INTERACTIVE -->|No| SCRIPT_MODE[📜 Script Mode<br/>Environment only]
    INTERACTIVE -->|Yes| LOAD_ZSH RC[📄 Load .zshrc<br/>~50ms<br/>vendored from quickstart]

    SCRIPT_MODE --> END_SCRIPT([✅ Ready for<br/>Script Execution])

    LOAD_ZSHRC --> PREPLUGIN_DIR[📁 Source pre-plugins<br/>~150ms<br/>7 files]

    PREPLUGIN_DIR --> SAFETY[🛡️ Shell Safety<br/>010-shell-safety.zsh<br/>Nounset guards]
    SAFETY --> DEV_PREP[🔧 Dev Environment<br/>030-dev-environment.zsh<br/>Prepare tools]
    DEV_PREP --> MONITOR_INIT[📊 Monitoring Init<br/>050-logging-and-monitoring.zsh<br/>Performance tracking]

    MONITOR_INIT --> PLUGIN_DECL[📁 Source add-plugins<br/>~50ms<br/>12 declaration files]

    PLUGIN_DECL --> CHECK_ZGENOM{zgenom<br/>installed?}

    CHECK_ZGENOM -->|No| INSTALL[📥 Install zgenom<br/>Clone from GitHub]
    CHECK_ZGENOM -->|Yes| CACHE_CHECK
    INSTALL --> CACHE_CHECK

    CACHE_CHECK{Plugin cache<br/>valid?}

    CACHE_CHECK -->|No| GEN_CACHE[⚙️ Generate Cache<br/>• Clone new plugins<br/>• Build init.zsh<br/>~500ms]
    CACHE_CHECK -->|Yes| LOAD_CACHE[📦 Load Cache<br/>init.zsh<br/>~300ms]

    GEN_CACHE --> SOURCE_PLUGINS[🔌 Source init.zsh<br/>40+ plugins active]
    LOAD_CACHE --> SOURCE_PLUGINS

    SOURCE_PLUGINS --> POSTPLUGIN_DIR[📁 Source post-plugins<br/>~400ms<br/>14 files]

    POSTPLUGIN_DIR --> OPTIONS[⚙️ Shell Options<br/>400-options.zsh]
    OPTIONS --> COMPLETIONS[🎯 Completions<br/>410-completions.zsh<br/>compinit]
    COMPLETIONS --> TERMINAL[💻 Terminal Setup<br/>420-terminal-integration.zsh]
    TERMINAL --> NAVIGATION[🗺️ Navigation<br/>430-navigation-tools.zsh]
    NAVIGATION --> NEOVIM[📝 Neovim<br/>440-neovim.zsh]
    NEOVIM --> NODE_ENV[📦 Node Environment<br/>450-node-environment.zsh]
    NODE_ENV --> UI_ELEMENTS[🎨 UI Elements<br/>470-user-interface.zsh]
    UI_ELEMENTS --> HISTORY[📚 History<br/>480-history.zsh]
    HISTORY --> KEYBINDINGS[⌨️ Keybindings<br/>490-keybindings.zsh]
    KEYBINDINGS --> ALIASES[🔗 Aliases<br/>500-aliases.zsh]
    ALIASES --> DEV_TOOLS[🛠️ Dev Tools<br/>510-developer-tools.zsh]

    DEV_TOOLS --> PLATFORM{Platform?}

    PLATFORM -->|macOS| DARWIN[🍎 macOS Config<br/>.zshrc.Darwin.d/]
    PLATFORM -->|Linux| SKIP_PLAT[⏭️ Skip Platform]

    DARWIN --> USER_CHECK
    SKIP_PLAT --> USER_CHECK

    USER_CHECK{.zshrc.local<br/>exists?}

    USER_CHECK -->|Yes| USERLOCAL[👤 User Overrides<br/>.zshrc.local<br/>Custom settings]
    USER_CHECK -->|No| PROMPT_INIT

    USER_LOCAL --> PROMPT_INIT

    PROMPT_INIT[✨ Initialize Prompt<br/>Starship setup<br/>~200ms]

    PROMPT_INIT --> HEALTH_CHECK{Health check<br/>enabled?}

    HEALTH_CHECK -->|Yes| RUN_HEALTH[🏥 Health Check<br/>zsh-healthcheck]
    HEALTH_CHECK -->|No| PERF_CHECK

    RUN_HEALTH --> PERF_CHECK{Performance<br/>tracking?}

    PERF_CHECK -->|Yes| PERF_SUMMARY[📊 Performance Summary<br/>Segment report]
    PERF_CHECK -->|No| READY

    PERF_SUMMARY --> READY([✅ Shell Ready<br/>~1.8s total])

    style START fill:#008066,stroke:#fff,stroke-width:3px,color:#fff
    style END_SCRIPT fill:#008066,stroke:#fff,stroke-width:2px,color:#fff
    style READY fill:#008066,stroke:#fff,stroke-width:3px,color:#fff

    style LOAD_ENV fill:#cc7a00,stroke:#000,stroke-width:2px,color:#fff
    style ENV_TASKS fill:#cc7a00,stroke:#000,stroke-width:2px,color:#fff

    style LOAD_ZSHRC fill:#006600,stroke:#fff,stroke-width:2px,color:#fff

    style PREPLUGIN_DIR fill:#0080ff,stroke:#fff,stroke-width:2px,color:#fff
    style SAFETY fill:#0080ff,stroke:#fff,stroke-width:2px,color:#fff
    style DEV_PREP fill:#0080ff,stroke:#fff,stroke-width:2px,color:#fff
    style MONITOR_INIT fill:#0080ff,stroke:#fff,stroke-width:2px,color:#fff

    style PLUGIN_DECL fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff
    style CHECK_ZGENOM fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff
    style INSTALL fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff
    style CACHE_CHECK fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff
    style GEN_CACHE fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff
    style LOAD_CACHE fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff
    style SOURCE_PLUGINS fill:#cc0066,stroke:#fff,stroke-width:3px,color:#fff

    style POSTPLUGIN_DIR fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style OPTIONS fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style COMPLETIONS fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style TERMINAL fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style NAVIGATION fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style NEOVIM fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style NODE_ENV fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style UI_ELEMENTS fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style HISTORY fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style KEYBINDINGS fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style ALIASES fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff
    style DEV_TOOLS fill:#6600cc,stroke:#fff,stroke-width:2px,color:#fff

    style DARWIN fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff
    style USER_LOCAL fill:#cc6600,stroke:#000,stroke-width:2px,color:#fff
    style PROMPT_INIT fill:#cc0066,stroke:#fff,stroke-width:2px,color:#fff

    style ERR_ENV fill:#cc0000,stroke:#fff,stroke-width:3px,color:#fff,stroke-width:3px,color:#fff

```

## 🎨 Color Legend

| Color | Represents | Timing |
|-------|------------|--------|
| 🟡 Yellow (`#fff3cd`) | Environment (Phase 1) | ~100ms |
| 🟢 Green (`#d4edda`) | Orchestration (Phase 2) | ~50ms |
| 🔵 Blue (`#cce5ff`) | Pre-Plugin (Phase 3) | ~150ms |
| 🔴 Red (`#f8d7da`) | Plugin Loading (Phase 4) | ~800ms |
| 🟣 Purple (`#e7f3ff`) | Post-Plugin (Phase 5) | ~400ms |
| 🟠 Orange (`#ffeaa7`) | Finalization (Phase 6) | ~300ms |
| 🌸 Pink (`#ffd6e0`) | Prompt/UI | Included |
| 🟩 Mint (`#d1f2eb`) | Ready States | - |

---

**Navigation:** [← Architecture Diagram](010-architecture-diagram.md) | [Top ↑](#startup-flow) | [Symlink Chain →](030-symlink-chain.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-30)*
