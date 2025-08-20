# ZSH Configuration Functions Catalogue

This document catalogues all custom functions defined across the ZSH configuration files.

Generated: 2025-08-18 23:24 UTC

## 1. Functions in `.zshenv`

### 1.1. Command Safety Functions
```zsh
command_exists()          # Check if a command exists safely
safe_uname()             # Safe wrapper for uname command  
safe_sed()               # Safe wrapper for sed command
```

### 1.2. PATH Management Functions ⭐ **PRIMARY DEFINITIONS**
```zsh
_path_remove()           # Remove directory from PATH
_path_append()           # Append directory to PATH (deduped)
_path_prepend()          # Prepend directory to PATH (deduped)
```

### 1.3. Field Management Functions
```zsh
_field_append()          # Append to colon-separated field
_field_prepend()         # Prepend to colon-separated field  
_field_remove()          # Remove from colon-separated field
_field_has()             # Check if field contains value
_field_list()            # List all values in field
_field_count()           # Count values in field
_field_get()             # Get nth value from field
_field_clean()           # Clean and dedupe field
_field_replace()         # Replace value in field
```

### 1.4. Editor Setup Functions
```zsh
set_editor()             # Set EDITOR environment variable
set_visual()             # Set VISUAL environment variable
```

## 2. Functions in `.zshrc.pre-plugins.d/` (Pre-Plugin Phase)

### 2.1. Core Environment (00-core/)

#### 00-core-environment.zsh
```zsh
command_exists()         # Command existence check (optimized)
safe_source()            # Safe file sourcing
env_default()            # Set environment variable defaults
```

#### 05-completion-prep.zsh  
```zsh
prepare_completion_system()    # Initialize completion system
completion_cache_cleanup()     # Clean up completion caches
validate_completion_setup()    # Validate completion configuration
ensure_fpath_setup()          # Ensure fpath is properly configured
```

#### 07-essential-pre-plugin-setup.zsh
```zsh
validate_shell_environment()  # Validate shell setup
optimize_startup_sequence()   # Optimize shell startup
configure_plugin_environment() # Configure plugin loading environment  
finalize_pre_plugin_setup()   # Finalize pre-plugin configuration
```

### 2.2. Plugin Management (20-plugins/)

#### 20-ssh-agent.zsh
```zsh
# No active functions (configuration only)
```

#### 21-plugin-optimization.zsh  
```zsh
defer_plugin()                # Defer plugin loading until first use
is_plugin_loaded()           # Check if plugin is already loaded
safe_plugin_load()           # Safely load a plugin
start_plugin_timer()         # Start timing plugin load
end_plugin_timer()           # End timing and record performance
plugin_performance_report()  # Generate plugin performance report
cache_plugin_completions()   # Cache plugin completion data
clear_plugin_caches()        # Clear all plugin caches  
check_plugin_conflicts()     # Check for plugin conflicts
load_plugin_dependencies()   # Load plugin dependencies
enhanced_plugin_load()       # Enhanced plugin loading with features
plugin_health_check()        # Check plugin health status
cleanup_plugin_environment() # Clean up plugin environment
```

#### 23-nvm-config.zsh
```zsh
detect_nvm_directory()       # Auto-detect NVM installation directory
validate_nvm_setup()         # Validate NVM configuration
configure_nvm_environment()  # Configure NVM environment
setup_nvm_lazy_loading()     # Set up NVM lazy loading
```

## 3. Functions in `.zshrc.d/` (Post-Plugin Phase)

### 3.1. Core Functions (00-core/)

#### 04-functions-core.zsh ⭐ **ACTIVE FUNCTIONS**
```zsh
path_validate()          # Validate and clean PATH entries
dir_exists()             # Quick directory existence check  
command_exists()         # Command existence check with caching
safe_source()            # Safe file sourcing with error handling
env_default()            # Environment variable default setting
clear_command_cache()    # Clear command cache for debugging
time_function()          # Performance timing utility
```

#### 07-utility-functions.zsh
```zsh
# Various utility functions (file needs inspection)
```

### 3.2. Development Tools (10-tools/)

#### 10-development-tools.zsh  
```zsh
setup_development_environment() # Set up development tools
```

#### 12-tool-environments.zsh
```zsh
configure_node_environment()     # Configure Node.js ecosystem
configure_python_environment()   # Configure Python development  
configure_rust_environment()     # Configure Rust development
configure_go_environment()       # Configure Go development
configure_docker_environment()   # Configure Docker
configure_kubernetes_environment() # Configure Kubernetes tools
configure_cloud_tools()          # Configure cloud provider tools
configure_database_tools()       # Configure database tools
configure_editors()              # Configure editor integrations
configure_build_tools()          # Configure build systems
configure_vcs_tools()            # Configure version control tools
configure_performance_tools()    # Configure performance monitoring
# Platform-specific functions
configure_macos_optimizations()  # macOS-specific optimizations
configure_linux_optimizations()  # Linux-specific optimizations
configure_windows_optimizations() # Windows-specific optimizations
# Specialized tools
configure_composer()             # Configure Composer (PHP)
configure_bob()                  # Configure Bob (Neovim manager)
configure_bun()                  # Configure Bun completions
configure_docker_completions()   # Configure Docker completions
configure_gcloud_sdk()           # Configure Google Cloud SDK
configure_mcp_environment()      # Configure MCP AugmentCode
```

#### 13-git-vcs-config.zsh
```zsh  
git_config_setup()       # Configure Git settings
git_aliases_setup()      # Set up Git aliases
configure_git_workflow() # Configure Git workflow
setup_git_hooks()        # Set up Git hooks
configure_git_tools()    # Configure additional Git tools
```

#### 14-homebrew.zsh
```zsh
configure_homebrew_environment() # Configure Homebrew
homebrew_optimization_setup()    # Optimize Homebrew settings
validate_homebrew_setup()        # Validate Homebrew installation
homebrew_maintenance_tools()     # Set up maintenance tools
```

#### 15-development.zsh
```zsh
setup_development_aliases()      # Set up development aliases
configure_development_tools()    # Configure development environment
setup_project_shortcuts()        # Set up project navigation
configure_testing_environment()  # Configure testing tools
setup_debugging_tools()          # Set up debugging utilities
configure_deployment_tools()     # Configure deployment utilities
setup_monitoring_tools()         # Set up monitoring
setup_documentation_tools()      # Set up documentation tools
```

### 3.3. Plugin Management (20-plugins/)

#### 22-essential.zsh
```zsh
# Configuration functions for essential plugins
```

#### 24-deferred.zsh ⭐ **LAZY LOADING SYSTEM**
```zsh
setup_lazy_plugins()            # Configure lazy plugin registry
create_lazy_loader()            # Create lazy loading function for plugin
create_command_placeholders()   # Create command placeholders for lazy loading
init_lazy_loading()             # Initialize the lazy loading system
load_lazy_plugin()              # Manually load a lazy plugin
load_all_lazy_plugins()         # Load all lazy plugins (debugging)

# Lazy loading functions (auto-generated)
lazy_load_sysadmin_util()       # Load skx/sysadmin-util on demand
lazy_load_git_extras()          # Load unixorn/git-extra-commands on demand  
lazy_load_python_plugin()       # Load ohmyzsh python plugin on demand
lazy_load_docker_plugin()       # Load ohmyzsh docker plugin on demand
lazy_load_node_plugin()         # Load ohmyzsh node plugin on demand
lazy_load_golang_plugin()       # Load ohmyzsh golang plugin on demand
lazy_load_zsh_abbr()            # Load olets/zsh-abbr on demand
lazy_load_fzf_zsh()             # Load unixorn/fzf-zsh-plugin on demand
```

### 3.4. User Interface (30-ui/)

#### 31-prompt.zsh
```zsh
configure_prompt()              # Configure shell prompt
setup_prompt_customization()   # Set up prompt customizations
prompt_performance_optimization() # Optimize prompt performance
```

#### 33-ui-enhancements.zsh ⭐ **UI FUNCTIONS** 
```zsh
# All custom command functions are DISABLED to prevent conflicts:
# cds()                 # DISABLED - Smart cd with ls  
# mkcd()                # DISABLED - Create and enter directory
# ff()                  # DISABLED - Enhanced file finding
# fd()                  # DISABLED - Enhanced directory finding  
# psgrep()              # DISABLED - Process finding
# killps()              # DISABLED - Process killing
# extract()             # DISABLED - Archive extraction
```

#### 35-ui-customization.zsh
```zsh
# Additional UI customization functions (mostly DISABLED)
# cds2()                # DISABLED - Alternative cd with ls
# mkcd()                # DISABLED - Duplicate create/enter directory 
# ff()                  # DISABLED - Duplicate file finding
# fd()                  # DISABLED - Duplicate directory finding
# extract()             # DISABLED - Duplicate archive extraction
```

### 3.5. Finalization Functions (90-finalize/)

#### 99-splash.zsh
```zsh
display_welcome_message()      # Display welcome message
show_system_info()            # Show system information  
display_configuration_status() # Show configuration status
```

## 4. Function Status Summary

### 4.1. ✅ **ACTIVE FUNCTIONS** (Safe to use)
- **PATH Management**: `_path_prepend()`, `_path_append()`, `_path_remove()` (.zshenv)
- **Core Utilities**: `path_validate()`, `dir_exists()`, `command_exists()`, `safe_source()`, `env_default()` (04-functions-core.zsh)
- **Plugin Management**: All functions in `21-plugin-optimization.zsh` and `24-deferred.zsh`  
- **Tool Configuration**: All functions in `12-tool-environments.zsh`
- **Field Management**: All `_field_*()` functions (.zshenv)

### 4.2. ❌ **DISABLED FUNCTIONS** (Commented out to prevent conflicts)
- **Command Wrappers**: `cds()`, `mkcd()`, `ff()`, `fd()`, `extract()`, `psgrep()`, `killps()`
- **Location**: `33-ui-enhancements.zsh` and `35-ui-customization.zsh`
- **Reason**: Prevented conflicts with system commands and plugins

### 4.3. 🚫 **INACTIVE FILES** (Disabled with extensions)
- Files ending in `.disabled`, `.temp-disabled`, `.backup`
- These contain additional functions but are not loaded

## 5. Key Design Principles

### 5.1. ⭐ **Single Source of Truth**
- **PATH functions**: Defined ONLY in `.zshenv` - never duplicated
- **Command wrappers**: All disabled to prevent system command conflicts
- **Plugin functions**: Centralized in dedicated plugin files

### 5.2. 🔧 **Performance Optimization**  
- **Lazy loading**: Heavy plugins loaded on-demand via `24-deferred.zsh`
- **Caching**: Command existence cached in `_command_cache` 
- **Timing**: Plugin load times monitored via timer functions

### 5.3. 🛡️ **Conflict Prevention**
- **No system command overrides**: All `fd()`, `ls()`, etc. wrappers disabled
- **Plugin conflict detection**: Built-in conflict checking system
- **Safe loading**: Error handling in all loading functions

## 6. Usage Guidelines

### 6.1. ✅ **Recommended**
```zsh
# Use the PATH functions from .zshenv
_path_prepend /new/directory
_path_append /another/directory  
_path_remove /old/directory

# Use core utility functions
command_exists nvim && echo "Neovim available"
safe_source ~/.local/config
env_default EDITOR vim

# Use lazy loading for heavy tools
load_lazy_plugin docker-plugin
```

### 6.2. ❌ **Avoid**
```zsh  
# Don't redefine PATH functions
function _path_prepend() { ... }  # WRONG - already defined in .zshenv

# Don't create command wrappers  
function fd() { find . -name "*$1*"; }  # WRONG - conflicts with fd command

# Don't load heavy plugins directly
zgenom load ohmyzsh/ohmyzsh plugins/docker  # WRONG - use lazy loading instead
```

---

**Note**: This catalogue reflects the configuration state as of 2025-08-18. Functions marked as DISABLED have been intentionally commented out to prevent system conflicts and maintain clean command namespace.
