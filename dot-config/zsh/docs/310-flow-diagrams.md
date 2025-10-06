# Flow Diagrams

## Overview

This document contains detailed flow diagrams showing the ZSH configuration processes, error handling flows, and integration patterns. All diagrams use colorblind-accessible palettes and maintain consistency with the architecture diagrams.

## Startup Flow Diagram

### **Complete Startup Sequence**

```mermaid
%%{init: { 'theme': 'base', 'themeVariables': {
  'background': '#ffffff',
  'primaryColor': '#ffffff',
  'primaryTextColor': '#000000',
  'primaryBorderColor': '#cccccc',
  'lineColor': '#666666',
  'sectionBkgColor': '#f9f9f9',
  'altSectionBkgColor': '#f0f0f0',
  'gridColor': '#dddddd',
  'tertiaryColor': '#eeeeee',
  'background': '#ffffff',
  'mainBkg': '#ffffff',
  'secondBkg': '#f8f8f8',
  'tertiaryBkg': '#f0f0f0',
  'primaryBorderColor': '#cccccc',
  'secondaryBorderColor': '#dddddd',
  'tertiaryBorderColor': '#eeeeee'
}}}%%
flowchart TD
    Start([Shell Startup]) --> A{ZDOTDIR<br/>Resolution}
    A -->|Use dotfiles| B[Set ZDOTDIR to<br/>/Users/s-a-c/dotfiles/dot-config/zsh]
    A -->|Fallback| C[Set ZDOTDIR to<br/>XDG config location]
    B --> D[.zshenv Execution]
    C --> D
    D --> E[Critical Environment<br/>Variables Set]
    E --> F[PATH Normalization<br/>& Deduplication]
    F --> G[Terminal Detection<br/>& Configuration]
    G --> H[Cache Directory<br/>Creation]
    H --> I{Interactive<br/>Shell?}
    I -->|No| End1([Non-interactive<br/>Shell Exit])
    I -->|Yes| J[.zshrc Execution]
    J --> K[.zshrc.pre-plugins.d/<br/>Directory Loading]
    K --> L[Security & Safety<br/>Initialization]
    L --> M[Performance Monitoring<br/>Setup]
    M --> N[zgenom Plugin Manager<br/>Initialization]
    N --> O[.zshrc.add-plugins.d/<br/>Plugin Loading]
    O --> P[Performance Plugins<br/>Load]
    P --> Q[Development Tools<br/>Load]
    Q --> R[Productivity Features<br/>Load]
    R --> S[Optional Features<br/>Load]
    S --> T[.zshrc.d/<br/>Integration Setup]
    T --> U[Terminal Integration<br/>& Optimization]
    U --> V[History Management<br/>Configuration]
    V --> W[Completion System<br/>Setup]
    W --> X[Editor Integration<br/>& Helpers]
    X --> Y[.zshrc.local<br/>User Overrides]
    Y --> Z([Prompt Ready])

    %% High-contrast startup flow colors (WCAG AA compliant)
    classDef environment fill:#e3f2fd,stroke:#0d47a1,stroke-width:2px
    classDef main fill:#fff8e1,stroke:#e65100,stroke-width:2px
    classDef preplugin fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef plugin fill:#fce4ec,stroke:#b71c1c,stroke-width:2px
    classDef postplugin fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef completion fill:#ffebee,stroke:#b71c1c,stroke-width:2px

    class A,B,C,D,E,F,G,H environment
    class I,J,K,L,M,N main
    class O,P,Q,R,S preplugin
    class T,U,V,W,X plugin
    class Y,Z postplugin
```

## Error Handling Flow

### **Plugin Loading Error Recovery**

```mermaid
%%{init: { 'theme': 'base', 'themeVariables': {
  'background': '#ffffff',
  'primaryColor': '#ffffff',
  'primaryTextColor': '#000000',
  'primaryBorderColor': '#cccccc',
  'lineColor': '#666666',
  'sectionBkgColor': '#f9f9f9',
  'altSectionBkgColor': '#f0f0f0',
  'gridColor': '#dddddd',
  'tertiaryColor': '#eeeeee',
  'background': '#ffffff',
  'mainBkg': '#ffffff',
  'secondBkg': '#f8f8f8',
  'tertiaryBkg': '#f0f0f0',
  'primaryBorderColor': '#cccccc',
  'secondaryBorderColor': '#dddddd',
  'tertiaryBorderColor': '#eeeeee'
}}}%%
flowchart TD
    Start([Plugin Load Attempt]) --> A{Plugin Manager<br/>Available?}
    A -->|No| B[zf::debug: zgenom not available<br/>Continue without plugins]
    A -->|Yes| C[zgenom load plugin]
    C --> D{Load<br/>Successful?}
    D -->|No| E[zf::debug: Plugin load failed<br/>Check dependencies]
    E --> F{Dependency<br/>Issue?}
    F -->|Yes| G[Log missing dependency<br/>Continue with other plugins]
    F -->|No| H[Log plugin error<br/>Continue with other plugins]
    D -->|Yes| I[Plugin loaded successfully<br/>Continue to next plugin]
    H --> J[Check if critical plugin<br/>Required for shell function?]
    J -->|No| K[Continue loading<br/>Non-critical plugins work]
    J -->|Yes| L[⚠️ Warning: Critical plugin failed<br/>Shell may have reduced functionality]

    B --> End([Continue Shell Startup])
    G --> End
    I --> End
    K --> End
    L --> End

    %% High-contrast error handling colors (WCAG AA compliant)
    classDef attempt fill:#fff8e1,stroke:#bf360c,stroke-width:2px
    classDef failure fill:#ffebee,stroke:#b71c1c,stroke-width:2px
    classDef recovery fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef warning fill:#fff8e1,stroke:#e65100,stroke-width:2px

    class Start,A,C,D attempt
    class B,E,H,L failure
    class F,G,I,K recovery
    class J warning
```

## Security Flow

### **Nounset Protection Flow**

```mermaid
%%{init: { 'theme': 'base', 'themeVariables': {
  'background': '#ffffff',
  'primaryColor': '#ffffff',
  'primaryTextColor': '#000000',
  'primaryBorderColor': '#cccccc',
  'lineColor': '#666666',
  'sectionBkgColor': '#f9f9f9',
  'altSectionBkgColor': '#f0f0f0',
  'gridColor': '#dddddd',
  'tertiaryColor': '#eeeeee',
  'background': '#ffffff',
  'mainBkg': '#ffffff',
  'secondBkg': '#f8f8f8',
  'tertiaryBkg': '#f0f0f0',
  'primaryBorderColor': '#cccccc',
  'secondaryBorderColor': '#dddddd',
  'tertiaryBorderColor': '#eeeeee'
}}}%%
flowchart TD
    Start([Shell Startup]) --> A[Set early variable guards<br/>STARSHIP_*, ZSH, etc.]
    A --> B[Option snapshotting<br/>Save current shell options]
    B --> C{Check if nounset<br/>is enabled}
    C -->|No| D[Continue with normal<br/>nounset handling]
    C -->|Yes| E[Disable nounset for<br/>Oh-My-Zsh compatibility]
    E --> F[Mark nounset as disabled<br/>for plugin compatibility]
    F --> G[Load pre-plugin<br/>safety modules]
    G --> H[Initialize zgenom<br/>plugin manager]
    H --> I[Load all plugins<br/>with safety disabled]
    I --> J[Re-enable nounset safely<br/>after environment stable]
    J --> K[Continue with protected<br/>shell environment]

    D --> End([Safe Shell Environment])
    K --> End

    %% Security flow colors
    classDef early fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef protection fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef compatibility fill:#fff3e0,stroke:#f57c00,stroke-width:2px

    class Start,A,B early
    class C,D protection
    class E,F,G,H,I,J compatibility
```

## Performance Monitoring Flow

### **Segment Timing Flow**

```mermaid
%%{init: { 'theme': 'base', 'themeVariables': {
  'background': '#ffffff',
  'primaryColor': '#ffffff',
  'primaryTextColor': '#000000',
  'primaryBorderColor': '#cccccc',
  'lineColor': '#666666',
  'sectionBkgColor': '#f9f9f9',
  'altSectionBkgColor': '#f0f0f0',
  'gridColor': '#dddddd',
  'tertiaryColor': '#eeeeee',
  'background': '#ffffff',
  'mainBkg': '#ffffff',
  'secondBkg': '#f8f8f8',
  'tertiaryBkg': '#f0f0f0',
  'primaryBorderColor': '#cccccc',
  'secondaryBorderColor': '#dddddd',
  'tertiaryBorderColor': '#eeeeee'
}}}%%
flowchart TD
    Start([Module Execution]) --> A[zf::segment start<br/>Record timestamp]
    A --> B[Module code execution<br/>Plugin loading, setup, etc.]
    B --> C[zf::segment end<br/>Calculate delta time]
    C --> D{Logging<br/>Enabled?}
    D -->|No| E[Debug output only<br/>if ZSH_DEBUG=1]
    D -->|Yes| F[Write to PERF_SEGMENT_LOG<br/>SEGMENT name=... ms=... phase=...]
    F --> G[Debug integration<br/>zf::debug output]
    E --> G
    G --> H[Regression detection<br/>Compare with historical data]

    I[Timing Sources] --> C
    I --> J["Python 3: time.time*1000<br/>Node.js: Date.now<br/>Perl: Time-HiRes<br/>Fallback: date calculation"]

    %% High-contrast performance monitoring colors (WCAG AA compliant)
    classDef execution fill:#fff8e1,stroke:#bf360c,stroke-width:2px
    classDef timing fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef logging fill:#fce4ec,stroke:#b71c1c,stroke-width:2px
    classDef analysis fill:#e3f2fd,stroke:#0d47a1,stroke-width:2px

    class Start,A,B,C execution
    class D,E,F,G,H,I,J timing
    class End logging
    class K,L,M,N,O,P,Q,R,S,T,U,V,W,X analysis
```

## Plugin Loading Flow

### **zgenom Plugin Loading Process**

```mermaid
%%{init: { 'theme': 'base', 'themeVariables': {
  'background': '#ffffff',
  'primaryColor': '#ffffff',
  'primaryTextColor': '#000000',
  'primaryBorderColor': '#cccccc',
  'lineColor': '#666666',
  'sectionBkgColor': '#f9f9f9',
  'altSectionBkgColor': '#f0f0f0',
  'gridColor': '#dddddd',
  'tertiaryColor': '#eeeeee',
  'background': '#ffffff',
  'mainBkg': '#ffffff',
  'secondBkg': '#f8f8f8',
  'tertiaryBkg': '#f0f0f0',
  'primaryBorderColor': '#cccccc',
  'secondaryBorderColor': '#dddddd',
  'tertiaryBorderColor': '#eeeeee'
}}}%%
flowchart TD
    Start([Plugin Load Request]) --> A{Check zgenom<br/>function exists}
    A -->|No| B[zf::debug: zgenom not available<br/>Skip plugin loading]
    A -->|Yes| C[Check if plugin<br/>already cached]
    C -->|Yes| D[Load from cache<br/>Fast path]
    C -->|No| E[Download/load plugin<br/>from source]
    E --> F{Plugin load<br/>successful?}
    F -->|No| G[zf::debug: Plugin load failed<br/>Continue without plugin]
    F -->|Yes| H[Add to zgenom<br/>loaded plugins list]
    H --> I[Update plugin cache<br/>for future loads]

    D --> J[Verify plugin<br/>functionality]
    G --> K{Critical<br/>plugin?}
    K -->|No| L[Continue with<br/>other plugins]
    K -->|Yes| M[⚠️ Warning: Critical plugin failed<br/>Shell functionality reduced]

    B --> End([Plugin Loading Complete])
    I --> End
    J --> End
    L --> End
    M --> End

    %% Plugin loading colors
    classDef request fill:#fff8e1,stroke:#fbc02d,stroke-width:2px
    classDef loading fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef failure fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef success fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px

    class Start,A,C,E,F,H request
    class B,D,I,J loading
    class G,M failure
    class K,L success
```

## Terminal Integration Flow

### **Multi-Terminal Detection Process**

```mermaid
%%{init: { 'theme': 'base', 'themeVariables': {
  'background': '#ffffff',
  'primaryColor': '#ffffff',
  'primaryTextColor': '#000000',
  'primaryBorderColor': '#cccccc',
  'lineColor': '#666666',
  'sectionBkgColor': '#f9f9f9',
  'altSectionBkgColor': '#f0f0f0',
  'gridColor': '#dddddd',
  'tertiaryColor': '#eeeeee',
  'background': '#ffffff',
  'mainBkg': '#ffffff',
  'secondBkg': '#f8f8f8',
  'tertiaryBkg': '#f0f0f0',
  'primaryBorderColor': '#cccccc',
  'secondaryBorderColor': '#dddddd',
  'tertiaryBorderColor': '#eeeeee'
}}}%%
flowchart TD
    Start([Terminal Detection]) --> A{Terminal-specific<br/>environment set?}
    A -->|ALACRITTY_LOG| B[Alacritty detected<br/>TERM_PROGRAM=Alacritty]
    A -->|ITERM_SESSION_ID| C[iTerm2 detected<br/>TERM_PROGRAM=iTerm.app]
    A -->|KITTY_PID| D[Kitty detected<br/>TERM_PROGRAM=kitty]
    A -->|WARP_IS_LOCAL_SHELL_SESSION| E[Warp detected<br/>TERM_PROGRAM=WarpTerminal]
    A -->|WEZTERM_CONFIG_DIR| F[WezTerm detected<br/>TERM_PROGRAM=WezTerm]
    A -->|Parent process check| G{Parent process<br/>name?}
    G -->|Apple Terminal| H[Apple Terminal detected<br/>TERM_PROGRAM=Apple_Terminal]
    G -->|Ghostty| I[Ghostty detected<br/>TERM_PROGRAM=Ghostty]
    G -->|Other| J[Generic terminal<br/>TERM_PROGRAM=unknown]

    B --> K[Terminal-specific<br/>optimizations]
    C --> K
    D --> K
    E --> K
    F --> K
    H --> K
    I --> K
    J --> K

    K --> L[Environment variables<br/>configured for terminal]
    L --> End([Terminal Integration Complete])

    %% Terminal detection colors
    classDef detection fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef terminal fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef generic fill:#e8f5e8,stroke:#388e3c,stroke-width:2px

    class Start,A,G detection
    class B,C,D,E,F,H,I terminal
    class J generic
    class K,L detection
```

## Configuration Validation Flow

### **Configuration Health Check**

```mermaid
%%{init: { 'theme': 'base', 'themeVariables': {
  'background': '#ffffff',
  'primaryColor': '#ffffff',
  'primaryTextColor': '#000000',
  'primaryBorderColor': '#cccccc',
  'lineColor': '#666666',
  'sectionBkgColor': '#f9f9f9',
  'altSectionBkgColor': '#f0f0f0',
  'gridColor': '#dddddd',
  'tertiaryColor': '#eeeeee',
  'background': '#ffffff',
  'mainBkg': '#ffffff',
  'secondBkg': '#f8f8f8',
  'tertiaryBkg': '#f0f0f0',
  'primaryBorderColor': '#cccccc',
  'secondaryBorderColor': '#dddddd',
  'tertiaryBorderColor': '#eeeeee'
}}}%%
flowchart TD
    Start([Configuration Validation]) --> A[Check .zsh syntax<br/>All .zsh files]
    A --> B{Syntax<br/>errors?}
    B -->|Yes| C[❌ Report syntax errors<br/>List problematic files]
    B -->|No| D[Check naming convention<br/>XX_YY-name.zsh format]
    D --> E{Naming<br/>violations?}
    E -->|Yes| F[❌ Report naming violations<br/>List non-compliant files]
    E -->|No| G[Check for duplicate files<br/>Same filename in different dirs]
    G --> H{Duplicates<br/>found?}
    H -->|Yes| I[❌ Report duplicate files<br/>Show conflicting locations]
    H -->|No| J[Validate module headers<br/>Check dependency documentation]
    J --> K{Header<br/>issues?}
    K -->|Yes| L[⚠️ Report header issues<br/>Missing dependency info]
    K -->|No| M[Check plugin availability<br/>Verify zgenom plugins exist]
    M --> N{Plugin<br/>issues?}
    N -->|Yes| O[⚠️ Report plugin issues<br/>Missing or broken plugins]
    N -->|No| P[✅ Configuration validation passed<br/>All checks successful]

    C --> End([Validation Failed])
    F --> End
    I --> End
    L --> End
    O --> End
    P --> End([Validation Successful])

    %% Validation colors
    classDef check fill:#fff8e1,stroke:#fbc02d,stroke-width:2px
    classDef error fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef warning fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef success fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px

    class Start,A,D,G,J,M check
    class B,E,H,K,N error
    class C,F,I,L,O warning
    class P success
```

## Development Tool Integration Flow

### **Multi-Language Development Setup**

```mermaid
%%{init: { 'theme': 'base', 'themeVariables': {
  'background': '#ffffff',
  'primaryColor': '#ffffff',
  'primaryTextColor': '#000000',
  'primaryBorderColor': '#cccccc',
  'lineColor': '#666666',
  'sectionBkgColor': '#f9f9f9',
  'altSectionBkgColor': '#f0f0f0',
  'gridColor': '#dddddd',
  'tertiaryColor': '#eeeeee',
  'background': '#ffffff',
  'mainBkg': '#ffffff',
  'secondBkg': '#f8f8f8',
  'tertiaryBkg': '#f0f0f0',
  'primaryBorderColor': '#cccccc',
  'secondaryBorderColor': '#dddddd',
  'tertiaryBorderColor': '#eeeeee'
}}}%%
flowchart TD
    Start([Development Environment Setup]) --> A[Node.js environment<br/>nvm, npm, yarn, bun]
    A --> B{PHP development<br/>needed?}
    B -->|Yes| C[Herd PHP manager<br/>Composer integration]
    B -->|No| D[Python development<br/>uv package manager]
    D --> E{Rust development<br/>needed?}
    E -->|Yes| F[Rust toolchain<br/>cargo, rustup]
    E -->|No| G[Go development<br/>GOPATH setup]
    G --> H{GitHub CLI<br/>integration?}
    H -->|Yes| I[GitHub CLI setup<br/>gh command integration]

    C --> J[System development tools<br/>All languages configured]
    F --> J
    I --> J

    J --> K[Development<br/>environment ready]
    K --> End([Development Tools Available])

    %% Development integration colors
    classDef setup fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef language fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef tools fill:#e8f5e8,stroke:#388e3c,stroke-width:2px

    class Start,A,B,E,H setup
    class C,D,F,G,I language
    class J,K tools
```

## Error Recovery Flow

### **Multi-Level Error Recovery**

```mermaid
%%{init: { 'theme': 'base', 'themeVariables': {
  'background': '#ffffff',
  'primaryColor': '#ffffff',
  'primaryTextColor': '#000000',
  'primaryBorderColor': '#cccccc',
  'lineColor': '#666666',
  'sectionBkgColor': '#f9f9f9',
  'altSectionBkgColor': '#f0f0f0',
  'gridColor': '#dddddd',
  'tertiaryColor': '#eeeeee',
  'background': '#ffffff',
  'mainBkg': '#ffffff',
  'secondBkg': '#f8f8f8',
  'tertiaryBkg': '#f0f0f0',
  'primaryBorderColor': '#cccccc',
  'secondaryBorderColor': '#dddddd',
  'tertiaryBorderColor': '#eeeeee'
}}}%%
flowchart TD
    Start([Error Encountered]) --> A{Error Type?}
    A -->|Plugin Failure| B[Graceful degradation<br/>Continue without plugin]
    A -->|Configuration Error| C[Debug logging<br/>Error context capture]
    A -->|Environment Error| D[Safe fallbacks<br/>Emergency PATH setup]
    A -->|Performance Issue| E[Timing analysis<br/>Bottleneck identification]

    B --> F{Plugin critical<br/>for shell function?}
    F -->|No| G[Continue operation<br/>Non-critical plugin failed]
    F -->|Yes| H[⚠️ User notification<br/>Reduced functionality]

    C --> I[Error context logged<br/>Debug information saved]

    D --> J{Emergency fallbacks<br/>work?}
    J -->|No| K[❌ Critical failure<br/>Shell may not function]
    J -->|Yes| L[✅ Emergency mode<br/>Basic shell available]

    E --> M[Performance data<br/>collected for analysis]

    G --> End([Continue Operation])
    H --> End
    I --> End
    L --> End
    M --> End
    K --> End([Critical Failure])

    %% Error recovery colors
    classDef error fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef recovery fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef warning fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef critical fill:#fce4ec,stroke:#c2185b,stroke-width:2px

    class Start,A error
    class B,C,D,E recovery
    class F,G,I,J,L,M warning
    class H critical
    class K critical
```

## Integration Flow

### **External Tool Integration Process**

```mermaid
%%{init: { 'theme': 'base', 'themeVariables': {
  'background': '#ffffff',
  'primaryColor': '#ffffff',
  'primaryTextColor': '#000000',
  'primaryBorderColor': '#cccccc',
  'lineColor': '#666666',
  'sectionBkgColor': '#f9f9f9',
  'altSectionBkgColor': '#f0f0f0',
  'gridColor': '#dddddd',
  'tertiaryColor': '#eeeeee',
  'background': '#ffffff',
  'mainBkg': '#ffffff',
  'secondBkg': '#f8f8f8',
  'tertiaryBkg': '#f0f0f0',
  'primaryBorderColor': '#cccccc',
  'secondaryBorderColor': '#dddddd',
  'tertiaryBorderColor': '#eeeeee'
}}}%%
flowchart TD
    Start([Tool Integration]) --> A[Atuin integration<br/>History synchronization]
    A --> B{FZF available?}
    B -->|Yes| C[FZF integration<br/>Fuzzy file/directory finding]
    B -->|No| D[Continue without FZF<br/>Basic shell navigation]
    C --> E{Carapace<br/>completion?}
    E -->|Yes| F[Carapace setup<br/>Enhanced completions]
    E -->|No| G[Standard ZSH<br/>completions only]
    F --> H{Starship prompt<br/>configured?}
    H -->|Yes| I[Starship initialization<br/>Cross-shell prompt]
    H -->|No| J[Standard ZSH prompt<br/>Basic prompt functionality]

    D --> K[Terminal integration<br/>Terminal-specific setup]
    G --> K
    J --> K

    K --> L{Neovim<br/>integration?}
    L -->|Yes| M[Neovim environment<br/>Editor-specific setup]
    L -->|No| N[Generic editor<br/>support only]

    M --> End([Full Integration Complete])
    N --> End

    %% Integration colors
    classDef integration fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef tools fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef fallback fill:#e8f5e8,stroke:#388e3c,stroke-width:2px

    class Start,A,B,E,H,L integration
    class C,F,I,M tools
    class D,G,J,N fallback
    class K integration
```

## Maintenance Flow

### **Configuration Maintenance Process**

```mermaid
%%{init: { 'theme': 'base', 'themeVariables': {
  'background': '#ffffff',
  'primaryColor': '#ffffff',
  'primaryTextColor': '#000000',
  'primaryBorderColor': '#cccccc',
  'lineColor': '#666666',
  'sectionBkgColor': '#f9f9f9',
  'altSectionBkgColor': '#f0f0f0',
  'gridColor': '#dddddd',
  'tertiaryColor': '#eeeeee',
  'background': '#ffffff',
  'mainBkg': '#ffffff',
  'secondBkg': '#f8f8f8',
  'tertiaryBkg': '#f0f0f0',
  'primaryBorderColor': '#cccccc',
  'secondaryBorderColor': '#dddddd',
  'tertiaryBorderColor': '#eeeeee'
}}}%%
flowchart TD
    Start([Maintenance Required]) --> A{Configuration<br/>changes needed?}
    A -->|Yes| B[Edit active files<br/>.zshrc.*.d/ modules]
    A -->|No| C{Cache<br/>rebuild needed?}
    C -->|Yes| D[Clear zgenom cache<br/>rm -rf .zgenom/]
    C -->|No| E{Performance<br/>optimization?}
    E -->|Yes| F[Review performance logs<br/>Check segment timing]
    E -->|No| G{Documentation<br/>updates?}
    G -->|Yes| H[Update documentation<br/>Revise affected sections]

    B --> I[Test configuration<br/>Validate syntax and function]
    D --> J[Rebuild plugin cache<br/>zgenom reset && zgenom save]
    F --> K[Analyze performance data<br/>Identify optimization opportunities]
    H --> L[Validate documentation<br/>Check accuracy and completeness]

    I --> M{Changes<br/>working?}
    M -->|No| N[Debug issues<br/>Check logs and error messages]
    M -->|Yes| O[Deploy to live<br/>Update .00 backup versions]
    O --> P[Commit changes<br/>Update git repository]

    J --> Q[Test plugin loading<br/>Verify all plugins work]
    K --> R{Performance<br/>improved?}
    R -->|No| S[Review optimization strategy<br/>Consider alternative approaches]
    R -->|Yes| O
    L --> T{Documentation<br/>accurate?}
    T -->|No| U[Revise documentation<br/>Correct inaccuracies]
    T -->|Yes| O

    N --> I
    S --> K
    U --> H

    Q --> End([Maintenance Complete])
    P --> End

    %% Maintenance colors
    classDef maintenance fill:#fff8e1,stroke:#fbc02d,stroke-width:2px
    classDef testing fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef deployment fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef debugging fill:#ffebee,stroke:#c62828,stroke-width:2px

    class Start,A,C,E,G maintenance
    class B,D,F,H,I,J,K,L,O,P,Q testing
    class M,N,R,S,T,U debugging
    class End deployment
```

## Color Legend

### **Flow Diagram Color Scheme**

| Color | Hex Code | Usage |
|-------|----------|-------|
| **Blue** | `#1976d2` | Environment setup, primary flows |
| **Orange** | `#f57c00` | Plugin systems, main processes |
| **Green** | `#1b5e20` | Success states, integration, fallbacks |
| **Purple** | `#4a148c` | Post-plugin phase, deployment |
| **Red** | `#b71c1c` | Critical errors, failures |
| **Amber** | `#bf360c` | Performance monitoring, warnings |

### **Flow Status Indicators**

- **✅ Success Path** - Green outline, normal operation
- **⚠️ Warning Path** - Orange outline, degraded functionality
- **❌ Error Path** - Red outline, failure handling
- **🔄 Loop/Retry** - Blue outline, iterative processes

---

*These flow diagrams illustrate the complex processes within the ZSH configuration system, from startup sequences through error recovery and maintenance procedures. The visual representation helps understand the relationships between different components and the flow of execution through various phases.*
