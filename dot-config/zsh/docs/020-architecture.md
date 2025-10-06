# System Architecture

## Overview

The ZSH configuration implements a sophisticated modular architecture designed for maintainability, performance, and extensibility. The system is built around three distinct loading phases with clear separation of concerns and standardized interfaces.

## Core Design Principles

### **Modular Loading Architecture**

The configuration is organized into three distinct phases:

```
.zshenv → .zshrc.pre-plugins.d/ → .zshrc.add-plugins.d/ → .zshrc.d/
     ↑         ↑                        ↑                   ↑
  Environment  Security/Safety        Plugin Loading     Integration
   Setup        Setup                 & Features       & Environment
```

### **Standardized Naming Convention**

All modules follow the `XX_YY-name.zsh` pattern:

- **XX** (000-999): Load order and priority
- **YY** (-): Category separator
- **name**: Descriptive identifier

**Examples:**
- `010-shell-safety-nounset.zsh` - Load order 010, shell safety category
- `100-perf-core.zsh` - Load order 100, performance core category
- `195-optional-brew-abbr.zsh` - Load order 195, optional feature category

### **Feature-Driven Design Philosophy**

Rather than rigid structural constraints, the system prioritizes:
- **Feature enablement** over configuration complexity
- **User customization** without requiring forks
- **Clear extension points** for new functionality

## Loading Phase Architecture

### **Phase 1: Pre-Plugin Setup** (`.zshrc.pre-plugins.d/`)

**Purpose:** Establish safe environment before plugin loading

**Key Components:**
- **000-layer-set-marker.zsh** - Layered system initialization
- **010-shell-safety-nounset.zsh** - Nounset safety and variable guards
- **015-xdg-extensions.zsh** - XDG base directory setup
- **020-delayed-nounset-activation.zsh** - Controlled nounset enabling
- **025-log-rotation.zsh** - Log management and rotation
- **030-segment-management.zsh** - Performance monitoring setup

**Load Order:** 000 → 010 → 015 → 020 → 025 → 030

### **Phase 2: Plugin Definition** (`.zshrc.add-plugins.d/`)

**Purpose:** Load and configure zgenom plugins

**Categories:**
- **100-130: Core Systems** - Performance, development tools
- **140-170: Productivity** - Navigation, search, integration
- **180-199: Optional Features** - Auto-pairing, abbreviations

**Load Order:**
- `100-perf-core.zsh` - Performance utilities (evalcache, zsh-async, zsh-defer)
- `110-dev-php.zsh` - PHP development environment
- `120-dev-node.zsh` - Node.js development tools
- `130-dev-systems.zsh` - System development utilities
- `136-dev-python-uv.zsh` - Python/UV development
- `140-dev-github.zsh` - GitHub CLI integration
- `150-productivity-nav.zsh` - Navigation enhancements
- `160-productivity-fzf.zsh` - FZF fuzzy finder integration
- `180-optional-autopair.zsh` - Auto-pairing functionality
- `190-optional-abbr.zsh` - Abbreviation system
- `195-optional-brew-abbr.zsh` - Homebrew aliases

### **Phase 3: Post-Plugin Integration** (`.zshrc.d/`)

**Purpose:** Terminal integration and environment-specific setup

**Categories:**
- **100-199: Core Integration** - Terminal, prompt, completions
- **300-399: Advanced Features** - History, navigation, Neovim

**Load Order:**
- `100-terminal-integration.zsh` - Terminal detection and setup
- `110-starship-prompt.zsh` - Starship prompt configuration
- `115-live-segment-capture.zsh` - Real-time performance monitoring
- `195-optional-brew-abbr.zsh` - ⚠️ **DUPLICATE** with add-plugins.d version
- `300-shell-history.zsh` - History management and configuration
- `310-navigation.zsh` - Navigation and directory management
- `320-fzf.zsh` - FZF shell integration
- `330-completions.zsh` - Tab completion setup
- `335-completion-styles.zsh` - Completion styling and behavior
- `340-neovim-environment.zsh` - Neovim environment integration
- `345-neovim-helpers.zsh` - Neovim helper functions

## Security Architecture

### **Nounset Safety System**

**Problem:** ZSH's `set -u` (nounset) option causes "parameter not set" errors when variables are undefined, breaking many Oh-My-Zsh and zgenom plugins.

**Solution:** Multi-layered protection system:

1. **Early Variable Guards** (`.zshenv`)
   ```bash
   : ${ZSH_DEBUG:=0}
   : ${STARSHIP_CMD_STATUS:=0}
   : ${STARSHIP_PIPE_STATUS:=""}
   ```

2. **Plugin Compatibility Mode** (`010-shell-safety-nounset.zsh`)
   ```bash
   if [[ -o nounset ]]; then
       export _ZQS_NOUNSET_WAS_ON=1
       unsetopt nounset
       export _ZQS_NOUNSET_DISABLED_FOR_OMZ=1
   fi
   ```

3. **Controlled Re-enablement** (`020-delayed-nounset-activation.zsh`)
   ```bash
   zf::enable_nounset_safe() {
       # Safe nounset activation after environment stabilization
   }
   ```

### **Path Security**

**Features:**
- **Path deduplication** - Removes duplicate entries while preserving order
- **Directory validation** - Only adds existing directories to PATH
- **XDG compliance** - Uses XDG base directories when available

## Performance Architecture

### **Segment Monitoring System**

**Implementation:** (`030-segment-management.zsh`)

```bash
zf::segment() {
    local module_name="$1" action="$2" phase="${3:-other}"
    # Normalize and track timing
}

zf::segment_fallback() {
    # Millisecond-precision timing with multiple backends
    # python3, node, perl, or date fallback
}
```

**Timing Sources:**
1. **Primary:** `python3 -c "import time; print(int(time.time() * 1000))"`
2. **Secondary:** `node -e "console.log(Date.now())"`
3. **Tertiary:** `perl -MTime::HiRes=time -E 'say int(time*1000)'`
4. **Fallback:** `$(($(date +%s) * 1000))`

### **Performance Targets**

- **Startup Time:** ~1.8 seconds
- **Plugin Load Time:** < 500ms for core plugins
- **Memory Usage:** Monitored through segment system
- **Cache Efficiency:** zgenom handles plugin caching

## Plugin Management Architecture

### **zgenom Integration**

**Configuration Strategy:**
- **Centralized Setup:** `.zgen-setup` file manages plugin loading
- **Conditional Loading:** Plugins only load if zgenom function exists
- **Error Handling:** Non-fatal plugin load failures with debug logging

**Plugin Categories:**
- **Performance:** evalcache, zsh-async, zsh-defer
- **Development:** PHP, Node.js, Python, GitHub tools
- **Productivity:** FZF, navigation, abbreviations
- **Optional:** Auto-pairing, Homebrew integration

### **Cache Management**

- **Auto-reset:** Plugin definition changes trigger cache rebuild
- **Location:** `${ZDOTDIR}/.zgenom/` (localized to config directory)
- **Integrity:** Plugin loading verification and error reporting

## Layered Configuration Architecture

### **Symlink-Based Versioning**

**Structure:**
```
.zshrc.add-plugins.d -> .zshrc.add-plugins.d.live -> .zshrc.add-plugins.d.00
```

**Benefits:**
- **Safe Updates:** Active config is symlink to stable version
- **Rollback:** Quick reversion to previous working state
- **Development:** Non-.00 directories for active development

**Files Involved:**
- `.zshrc.add-plugins.d` → `.zshrc.add-plugins.d.live` → `.zshrc.add-plugins.d.00`
- `.zshrc.d` → `.zshrc.d.live` → `.zshrc.d.00`
- `.zshenv` → `.zshenv.live` → `.zshenv.00`

## Integration Architecture

### **Terminal Detection System**

**Implementation:** (`.zshenv` lines 174-197)

```bash
if [[ -n ${ALACRITTY_LOG:-} ]]; then
    export TERM_PROGRAM=Alacritty
elif ps -o comm= -p "$(ps -o ppid= -p $$)" | grep -qi terminal; then
    export TERM_PROGRAM=Apple_Terminal
# ... additional terminal detection
fi
```

**Supported Terminals:**
- **Alacritty** - Cross-platform GPU terminal
- **Apple Terminal** - macOS built-in terminal
- **Ghostty** - Modern terminal emulator
- **iTerm2** - Advanced macOS terminal
- **Kitty** - GPU-accelerated terminal
- **Warp** - AI-enhanced terminal
- **WezTerm** - Cross-platform terminal

### **Development Tool Integration**

**Language Runtimes:**
- **Node.js/nvm** - JavaScript runtime management
- **PHP/Herd** - PHP version management
- **Python/uv** - Python package management
- **Rust** - Systems programming language
- **Go** - Cloud-native programming language

**Productivity Tools:**
- **Atuin** - Shell history synchronization
- **FZF** - Fuzzy finder integration
- **Carapace** - Multi-shell completions
- **Starship** - Cross-shell prompt

## Error Handling Architecture

### **Debug System**

**Components:**
- **zf::debug()** - Conditional debug output
- **ZSH_DEBUG** - Master debug flag
- **ZSH_DEBUG_LOG** - Debug log file location
- **Performance Tracing** - Segment-based performance logging

**Usage:**
```bash
export ZSH_DEBUG=1                    # Enable debug output
export PERF_SEGMENT_LOG="/path/to/log" # Enable performance logging
export PERF_SEGMENT_TRACE=1           # Verbose segment tracing
```

### **Error Recovery**

**Strategies:**
- **Graceful Degradation** - Continue operation despite plugin failures
- **Fallback Systems** - Alternative implementations when primary fails
- **User Notification** - Clear error messages for troubleshooting

## Extension Architecture

### **Module Header Format**

**Standard Header:**
```bash
#!/usr/bin/env zsh
# XX_YY-name.zsh - Brief description
# Phase: [pre_plugin|add_plugin|post_plugin]
# PRE_PLUGIN_DEPS: comma,separated,list
# POST_PLUGIN_DEPS: comma,separated,list
# RESTART_REQUIRED: [yes|no]
```

### **Integration Points**

**Available Functions:**
- `zf::segment "module" "start|end"` - Performance monitoring
- `zf::debug "message"` - Debug logging
- `zf::path_prepend/append/remove` - Safe PATH management
- `zf::has_command "cmd"` - Command existence checking

**Environment Variables:**
- `ZDOTDIR` - Configuration directory
- `ZSH_CACHE_DIR` - Cache location
- `ZSH_LOG_DIR` - Log directory
- `XDG_*` - XDG base directories

## Assessment

### **Strengths**
- ✅ **Clear separation of concerns**
- ✅ **Comprehensive performance monitoring**
- ✅ **Robust error handling**
- ✅ **Extensive integration capabilities**
- ✅ **Sophisticated security model**

### **Areas for Improvement**
- ⚠️ **Duplicate filename issue** in `.zshrc.d/`
- ⚠️ **Layered system complexity** may confuse newcomers
- ⚠️ **Extensive configuration** options increase learning curve

### **Scalability Considerations**
- **Modular design** supports easy feature additions
- **Performance monitoring** enables optimization
- **Standardized interfaces** ensure consistency
- **Layered system** provides safe update mechanisms

---

*This architecture documentation provides the foundation for understanding how the ZSH configuration system is designed and operates. For implementation details, see the specific phase documentation.*
