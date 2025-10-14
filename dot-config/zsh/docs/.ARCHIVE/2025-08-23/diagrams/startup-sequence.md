<<<<<<< HEAD

=======
>>>>>>> origin/develop
# ZSH Startup Sequence Diagram

## 🚀 Complete Startup Flow

This diagram shows the complete ZSH startup sequence with all active configuration files and their loading order.

```mermaid
flowchart TD
    A[🚀 ZSH Shell Start] --> B[📄 Load ~/.zshrc]
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    B --> C{🔍 Check Debug Mode}
    C -->|ZSH_DEBUG=1| C1[📝 Enable Debug Output]
    C -->|Normal| C2[📝 Continue Silently]
    C1 --> D
    C2 --> D
<<<<<<< HEAD

    D[⚡ P10k Instant Prompt] --> E[🎨 Font Mode Detection]

=======
    
    D[⚡ P10k Instant Prompt] --> E[🎨 Font Mode Detection]
    
>>>>>>> origin/develop
    E --> F[📁 Pre-Plugin Directory]
    F --> F1[00-fzf-setup.zsh<br/>🔍 FZF Early Setup]
    F1 --> F2[01-completion-init.zsh<br/>⚙️ Completion Init]
    F2 --> F3[02-nvm-npm-fix.zsh<br/>🔧 NVM/NPM Fix]
<<<<<<< HEAD

    F3 --> G[🔌 Plugin Management]
    G --> G1[📄 Load .zgen-setup]
    G1 --> G2[📦 Load Additional Plugins<br/>010-add-plugins.zsh]

=======
    
    F3 --> G[🔌 Plugin Management]
    G --> G1[📄 Load .zgen-setup]
    G1 --> G2[📦 Load Additional Plugins<br/>010-add-plugins.zsh]
    
>>>>>>> origin/develop
    G2 --> H[📁 Main Configuration]
    H --> H1[📊 00_ Directory<br/>6 files]
    H1 --> H2[🛠️ 10_ Directory<br/>8 files]
    H2 --> H3[🔌 20_ Directory<br/>4 files]
    H3 --> H4[🎨 30_ Directory<br/>6 files]
    H4 --> H5[🎯 90_/ Directory<br/>1 file]
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    H5 --> I{🖥️ OS Detection}
    I -->|Darwin| I1[🍎 macOS Specific Config<br/>100-macos-defaults.zsh]
    I -->|Linux| I2[🐧 Linux Config<br/>Not Present]
    I1 --> J
    I2 --> J
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    J[🏢 Work-Specific Config<br/>Not Present]
    J --> K[🔄 PATH Deduplication]
    K --> L[📝 Completion Finalization]
    L --> M[🔑 SSH Key Management]
    M --> N[🎨 Terminal Theme<br/>P10k Configuration]
    N --> O[✅ Startup Complete]

    %% Styling for high contrast
    classDef startEnd fill:#ff6b6b,stroke:#d63031,stroke-width:3px,color:#fff
    classDef directory fill:#74b9ff,stroke:#0984e3,stroke-width:2px,color:#fff
    classDef plugin fill:#00b894,stroke:#00a085,stroke-width:2px,color:#fff
    classDef config fill:#fdcb6e,stroke:#e17055,stroke-width:2px,color:#000
    classDef os fill:#a29bfe,stroke:#6c5ce7,stroke-width:2px,color:#fff
    classDef decision fill:#fd79a8,stroke:#e84393,stroke-width:2px,color:#fff
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    class A,O startEnd
    class F,H directory
    class G,G1,G2 plugin
    class F1,F2,F3,H1,H2,H3,H4,H5,I1,J config
    class I,C decision
    class I1,I2 os
```

## 📊 Loading Statistics

| Phase | Files Loaded | Purpose |
|-------|-------------|---------|
| **Pre-Plugin** | 3 | Early initialization, FZF setup, completion prep |
| **Plugin Management** | 1 | Custom plugin definitions |
| **Main Configuration** | 25 | Core functionality, tools, UI, finalization |
| **OS-Specific** | 1 | macOS-specific configurations |
| **Total Active** | **30** | **Complete system configuration** |

## ⏱️ Performance Notes

- **Fast completion init**: Uses `-C` flag to skip security checks
- **Early FZF setup**: Prevents widget conflicts with other plugins
- **Deferred loading**: Some functionality loaded after plugins
- **PATH optimization**: Automatic deduplication at end

## 🔧 Key Integration Points

1. **FZF Integration**: Loaded early to prevent conflicts
2. **Completion System**: Initialized before plugins need it
3. **NVM Compatibility**: NPM_CONFIG_PREFIX handled properly
4. **Plugin Conflicts**: Resolved through careful loading order

## 🚨 Critical Dependencies

- P10k must load before other prompt modifications
- FZF must load before plugins that use fzf widgets
- Completion system must initialize before compdef commands
- NVM environment must be clean before plugin loading
