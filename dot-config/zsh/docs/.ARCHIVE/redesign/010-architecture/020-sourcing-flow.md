# ZSH Configuration Sourcing Flow

Return: [Index](../README.md) | Related: [Architecture Overview](010-overview.md) | [Styling Architecture](040-styling-architecture.md)
Generated: 2025-08-23
**Updated: 2025-08-24 - Reflects current renamed script structure**

## Script Loading Sequence

The ZSH configuration follows a strict loading sequence to ensure proper initialization order and dependency management.

### Phase 1: Pre-Plugin Initialization (`.zshrc.pre-plugins.d/`)

Scripts loaded in lexicographic order before plugin system activation:

```
00-fzf-setup.zsh                    → FZF early initialization
01-completion-init.zsh              → ⚠️ Legacy completion (needs neutralization)
02-nvm-npm-fix.zsh                  → Node version manager patches
03-macos-defaults-deferred.zsh      → macOS system defaults (deferred)
03-secure-ssh-agent.zsh             → SSH agent security setup
04-lazy-direnv.zsh                  → Direnv lazy loading setup
04-plugin-deferred-loading.zsh      → Plugin deferred loading framework
04-plugin-integrity-verification.zsh → Plugin security verification
05-environment-sanitization.zsh     → ⚠️ Environment cleanup (merge candidate)
05-lazy-git-config.zsh              → Git configuration lazy loading
06-lazy-gh-copilot.zsh             → GitHub Copilot lazy loading
```

### Phase 2: Plugin System Initialization

zgenom framework setup and core plugin loading via `.zgen-setup`:

```
zgenom oh-my-zsh                    → Oh-My-Zsh framework (if enabled)
zgenom load [core plugins]          → Essential plugins (syntax highlighting, etc.)
```

### Phase 3: Plugin Addition (`.zshrc.add-plugins.d/`)

Custom plugin additions loaded **during** plugin setup phase:

```
010-add-plugins.zsh                 → Additional plugin configurations
                                    → Executed within .zgen-setup context
```

### Phase 4: Plugin Finalization

```
zgenom save                         → Plugin manager save and initialization
                                    → Plugin system completion
```

### Phase 5: Core System Configuration (`.zshrc.d/00_*`)

Foundation scripts loaded **after** all plugins are initialized:

```
00_00-standard-helpers.zsh          → Essential helper functions
00_01-environment.zsh               → Core environment variables
00_01-source-execute-detection.zsh  → Script execution context detection
00_02-path-system.zsh               → PATH management and validation
00_03-completion-management.zsh     → Authoritative completion system init
00_03-options.zsh                   → ZSH options and behavior settings
00_04-functions-core.zsh            → Core utility functions
00_05-async-cache.zsh               → Async caching infrastructure
00_05-completion-finalization.zsh   → ⚠️ Completion styling (consolidation target)
00_06-performance-monitoring.zsh    → Performance tracking setup
00_07-review-cycles.zsh             → Configuration review system
00_07-utility-functions.zsh         → Additional utility functions
00_08-environment-sanitization.zsh  → Environment cleanup and validation
00_99-security-check.zsh            → Security validation and checks
00_99-validation.zsh                → Final core phase validation
```

### Phase 6: Development Tools (`.zshrc.d/10_*`)

External tool integrations and development environment setup:

```
10_10-development-tools.zsh         → Core development environment
10_11-path-tools.zsh                → PATH-related utilities
10_12-tool-environments.zsh         → Tool-specific environment setup
10_13-git-vcs-config.zsh            → Version control system configuration
10_14-homebrew.zsh                  → Homebrew package manager setup
10_15-development.zsh               → Additional development tools
10_15-ssh-agent-macos.zsh           → macOS SSH agent integration
10_17-completion.zsh                → ⚠️ Tool completions (fallback cleanup needed)
```

### Phase 7: Plugin Integration (`.zshrc.d/20_*`)

Plugin environment setup and integration:

```
20_01-plugin-metadata.zsh           → Plugin metadata and registry
20_20-plugin-environments.zsh       → Plugin-specific environments
20_22-essential.zsh                 → Essential plugin configurations
20_23-plugin-integration.zsh        → Plugin integration and coordination
20_24-deferred.zsh                  → Deferred plugin loading completion
```

### Phase 8: User Interface (`.zshrc.d/30_*`)

User experience customization and interface setup:

```
30_30-prompt-ui-config.zsh          → Prompt system configuration
30_31-prompt.zsh                    → Prompt theme and setup
30_32-aliases.zsh                   → Command aliases
30_33-ui-enhancements.zsh           → UI enhancement features
30_34-keybindings.zsh               → Keyboard shortcuts and bindings
30_35-context-aware-config.zsh      → Context-aware configuration
30_35-ui-customization.zsh          → Additional UI customizations
```

### Phase 9: Finalization (`.zshrc.d/90_*`)

Final validation and optional components:

```
90_99-splash.zsh.disabled           → ⚠️ Splash screen (currently disabled)
```

### Platform-Specific Extensions (`.zshrc.Darwin.d/`)

macOS-specific configurations loaded after main sequence (when applicable).

## Loading Flow Diagram

```plaintext
┌─────────────────────────────────────────────────────────────┐
│ ZSH Shell Startup                                           │
├─────────────────────────────────────────────────────────────┤
│ 1. Pre-Plugin Phase (.zshrc.pre-plugins.d/)                 │
│    ├── Early environment setup                              │
│    ├── Security initialization                              │
│    ├── Tool pre-configurations                              │
│    └── Plugin integrity verification                        │
├─────────────────────────────────────────────────────────────┤
│ 2. Plugin System Initialization                             │
│    ├── Oh-My-Zsh framework setup                            │
│    ├── Core plugin loading                                  │
│    └── Additional plugin configurations                     │
├─────────────────────────────────────────────────────────────┤
│ 3. Core Phase (.zshrc.d/00_*)                               │
│    ├── Helper functions (00_00)                             │
│    ├── Environment & PATH (00_01, 00_02)                    │
│    ├── Completion system (00_03)                            │
│    ├── Core functions & options (00_04, 00_05)              │
│    ├── Performance & monitoring (00_06, 00_07)              │
│    └── Security & validation (00_08, 00_99)                 │
├─────────────────────────────────────────────────────────────┤
│ 4. Tools Phase (.zshrc.d/10_*)                              │
│    ├── Development environment (10_10-10_15)                │
│    ├── External tool integration                            │
│    └── Tool-specific completions (10_17)                    │
├─────────────────────────────────────────────────────────────┤
│ 5. Plugin Integration (.zshrc.d/20_*)                       │
│    ├── Plugin metadata & environments (20_01, 20_20)        │
│    ├── Essential plugin setup (20_22, 20_23)                │
│    └── Deferred loading completion (20_24)                  │
├─────────────��──────────────────────────────────────────────┤
│ 6. UI Phase (.zshrc.d/30_*)                                 │
│    ├── Prompt configuration (30_30, 30_31)                  │
│    ├── User interface customization (30_32-30_35)           │
│    └── Final UI polish                                      │
├─────────────────────────────────────────────────────────────┤
│ 7. Finalization (.zshrc.d/90_*)                             │
│    └── Optional components & final validation               │
├─────────────────────────────────────────────────────────────┤
│ 8. Platform Extensions (.zshrc.Darwin.d/) [if macOS]        │
│    └── Platform-specific configurations                     │
└────────────────���──────────────────────────────────────────┘
```

## Critical Dependencies

### Completion System Flow
1. **Pre-plugin**: `01-completion-init.zsh` (⚠️ legacy, needs neutralization)
2. **Core**: `00_03-completion-management.zsh` (authoritative `compinit`)
3. **Tools**: `10_17-completion.zsh` (tool-specific completions + fallback)
4. **Core**: `00_05-completion-finalization.zsh` (styling and finalization)

**Target State**: Single `compinit` in `00_03-completion-management.zsh`, with styling extracted from finalization script.

### Environment Sanitization Flow
1. **Pre-plugin**: `05-environment-sanitization.zsh` (early cleanup)
2. **Core**: `00_08-environment-sanitization.zsh` (main cleanup)

**Target State**: Consolidated into single authoritative sanitization in core phase.

### PATH Management Flow
1. **Core**: `00_02-path-system.zsh` (core PATH setup)
2. **Tools**: `10_11-path-tools.zsh` (PATH utilities)
3. **Tools**: Various tool scripts (tool-specific PATH additions)

**Current State**: Well-structured with clear separation.

## Performance Implications

### Loading Time Optimization
- **Async caching**: `00_05-async-cache.zsh` provides caching infrastructure
- **Lazy loading**: Implemented throughout pre-plugin and tool phases
- **Deferred execution**: Plugin and tool configurations loaded on first use

### Memory Footprint
- **Modular loading**: Only required components loaded
- **Function scoping**: Proper function namespace management
- **Variable cleanup**: Environment sanitization removes temporary variables

## Known Issues & Cleanup Targets

### ⚠️ Immediate Attention Required
1. **Duplicate completion init**: `01-completion-init.zsh` conflicts with `00_03-completion-management.zsh`
2. **Monolithic styling**: `00_05-completion-finalization.zsh` needs modularization
3. **Fallback completion**: `10_17-completion.zsh` has unnecessary fallback logic
4. **Duplicate sanitization**: Environment cleanup happens in two places

### 📋 Consolidation Roadmap
1. **Phase 1**: Neutralize legacy completion init → stub with warning
2. **Phase 2**: Extract styling from completion finalization → modular system
3. **Phase 3**: Merge environment sanitization → single authority
4. **Phase 4**: Clean up disabled components → remove or document

---
**Status**: Naming convention complete ✅ | Flow optimization in progress 🔄

**Next Priority**: Eliminate duplicate completion initialization and consolidate styling system.
