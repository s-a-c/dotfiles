# ZSH Startup Flow Diagram

```mermaid
graph TD
    A[ZSH Session Start] --> B{ZSH_DEBUG Set?}
    B -->|Yes| C[Print Debug Header]
    B -->|No| D[Load .zshenv]
    C --> D
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    D[Load .zshenv<br/>305 lines] --> E[Set XDG Directories]
    E --> F[Configure ZDOTDIR]
    F --> G[Setup PATH utilities]
    G --> H[Set Environment Variables]
    H --> I[Load .zshrc<br/>995 lines]
<<<<<<< HEAD

    I --> J[Check P10K Instant Prompt]
    J --> K[Initialize SSH Keys]
    K --> L[Load Pre-Plugin Fragments]

=======
    
    I --> J[Check P10K Instant Prompt]
    J --> K[Initialize SSH Keys]
    K --> L[Load Pre-Plugin Fragments]
    
>>>>>>> origin/develop
    L --> M[003-setopt.zsh<br/>8.9k - Shell Options]
    M --> N[005-secure-env.zsh<br/>3.6k - Security]
    N --> O[007-path.zsh<br/>2.5k - PATH Config]
    O --> P[010-pre-plugins.zsh<br/>32k - Main Pre-Config]
    P --> Q[099-compinit.zsh<br/>1.3k - Completion Init]
    Q --> R[888-zstyle.zsh<br/>26k - ZSH Styling]
<<<<<<< HEAD

    R --> S[Initialize zgenom]
    S --> T[Load zgenom Plugins]
    T --> U[Plugin Loading Loop]

=======
    
    R --> S[Initialize zgenom]
    S --> T[Load zgenom Plugins]
    T --> U[Plugin Loading Loop]
    
>>>>>>> origin/develop
    U --> V[Load Post-Plugin Fragments]
    V --> W[010-post-plugins.zsh<br/>10k - Post-Plugin Config]
    W --> X[020-functions.zsh<br/>7.5k - Custom Functions]
    X --> Y[030-aliases.zsh<br/>6.8k - Aliases]
    Y --> Z[040-tools.zsh<br/>14k - Tool Configs]
    Z --> AA[100-macos-defaults.zsh<br/>3.2k - macOS Settings]
    AA --> BB[995-splash.zsh<br/>598b - Startup Banner]
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    BB --> CC[Load Additional Plugins]
    CC --> DD[Load P10K Configuration]
    DD --> EE[Display SSH Keys]
    EE --> FF[Setup Control-C Handler]
    FF --> GG[ZSH Ready]
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    %% Performance Issues
    P -.->|61.79% startup time| HH[load-shell-fragments<br/>Performance Bottleneck]
    T -.->|12.31% startup time| II[abbr plugin<br/>526 calls]
    S -.->|6.47% startup time| JJ[zgenom<br/>Plugin Manager]
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    %% Error Points
    W -.->|ERROR| KK[path_validate_silent<br/>command not found]
    Z -.->|ERROR| LL[uname command<br/>not found]
    Z -.->|ERROR| MM[sed command<br/>not found]
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    %% Styling
    classDef startup fill:#ff6b6b,stroke:#d63031,stroke-width:3px,color:#fff
    classDef config fill:#4ecdc4,stroke:#00b894,stroke-width:2px,color:#fff
    classDef plugins fill:#fd79a8,stroke:#e84393,stroke-width:2px,color:#fff
    classDef performance fill:#fdcb6e,stroke:#e17055,stroke-width:2px,color:#2d3436
    classDef error fill:#e17055,stroke:#d63031,stroke-width:3px,color:#fff
    classDef ready fill:#00b894,stroke:#00a085,stroke-width:3px,color:#fff
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    class A,D,I startup
    class E,F,G,H,M,N,O,Q,R,W,X,Y,Z,AA,BB config
    class S,T,U,CC plugins
    class HH,II,JJ performance
    class KK,LL,MM error
    class GG ready
    class P performance
```

## Flow Summary

### Startup Phases
1. **Environment Setup** (.zshenv) - 305 lines
<<<<<<< HEAD
2. **Core Configuration** (.zshrc) - 995 lines
=======
2. **Core Configuration** (.zshrc) - 995 lines  
>>>>>>> origin/develop
3. **Pre-Plugin Configuration** - 6 files, ~73k lines total
4. **Plugin Management** (zgenom) - Dynamic loading
5. **Post-Plugin Configuration** - 6 files, ~42k lines total
6. **Finalization** - P10K, SSH, handlers

### Performance Hotspots
- **load-shell-fragments**: 61.79% of startup time
- **abbr plugin**: 12.31% of startup time (526 calls)
- **zgenom**: 6.47% of startup time

### Critical Error Points
- Missing system commands (uname, sed)
- Undefined functions (path_validate_silent, nvm_find_nvmrc)
- Global variable creation warnings

### Total Configuration Size
- **Core files**: ~1.3k lines (.zshenv + .zshrc)
<<<<<<< HEAD
- **Pre-plugin configs**: ~73k lines
=======
- **Pre-plugin configs**: ~73k lines 
>>>>>>> origin/develop
- **Post-plugin configs**: ~42k lines
- **Total managed code**: ~116k lines
