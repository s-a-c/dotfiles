# Neovim Configuration Command Reference & Quick Start Guide
**Version:** 2025.01.10  
**Last Updated:** January 10, 2025  
**Quick Reference for Enhanced Neovim Configuration**

## 🚀 Quick Start

### First Time Setup
```vim
:ConfigHealth          " Check overall system health (0-100 score)
:PerformanceCheck      " Verify performance status
:ConfigValidate        " Run comprehensive validation
:MigrationStatus       " Check for any pending updates
```

### Daily Workflow Commands
```vim
:AnalyticsReport       " View performance insights and trends
:ConfigFix             " Auto-fix any detected issues
:PluginReport          " Check plugin loading performance
:ConfigProfile performance  " Switch to performance mode
```

### Emergency Commands
```vim
:DebugRecovery         " Emergency recovery if issues occur
:DebugSafeMode         " Start with minimal functionality
:ConfigBackup          " Create configuration backup
```

## 📋 Complete Command Reference

### 🔧 Performance Commands (3 commands)

#### `:PerformanceCheck`
**Purpose:** Run comprehensive performance health check  
**Usage:** `:PerformanceCheck`  
**Output:** Health report with startup time, memory usage, and issues  
**Example:**
```
=== Neovim Performance Health Check ===
Startup Time: 245.32ms
Memory Usage: 142.3MB
✅ No issues detected
```

#### `:PerformanceOptimize`
**Purpose:** Apply automated performance optimizations  
**Usage:** `:PerformanceOptimize`  
**What it does:**
- Sets `updatetime` to 250ms
- Optimizes `synmaxcol` for syntax highlighting
- Enables `lazyredraw` for smoother scrolling
- Configures completion settings

#### `:PerformanceReport`
**Purpose:** Show detailed performance metrics and plugin load times  
**Usage:** `:PerformanceReport`  
**Output:** Detailed breakdown of plugin loading times and memory usage

### ✅ Validation Commands (5 commands)

#### `:ConfigValidate`
**Purpose:** Run full configuration validation with detailed report  
**Usage:** `:ConfigValidate`  
**Checks:**
- Plugin conflicts and missing dependencies
- Keymap conflicts and missing essential keymaps
- LSP server configuration
- Security settings
- Performance-impacting settings

#### `:ConfigFix`
**Purpose:** Auto-fix configuration issues with smart fallbacks  
**Usage:** `:ConfigFix`  
**Auto-fixes:**
- Performance settings (updatetime, timeoutlen, synmaxcol)
- Security settings (disables modeline, fixes backup directory)
- Missing essential keymaps (adds with intelligent fallbacks)

#### `:ConfigHealth`
**Purpose:** Show configuration health score (0-100)  
**Usage:** `:ConfigHealth`  
**Scoring:**
- 90-100: Excellent configuration health
- 70-89: Good configuration with minor issues
- 50-69: Configuration needs attention
- 0-49: Configuration requires immediate fixes

#### `:ConfigBackup`
**Purpose:** Create timestamped backup of configuration  
**Usage:** `:ConfigBackup`  
**Output:** Backup location with timestamp

#### `:ConfigProfile <name>`
**Purpose:** Apply configuration profile  
**Usage:** `:ConfigProfile [profile_name]`  
**Profiles:**
- `minimal` - Low-resource environments
- `development` - Full-featured development
- `performance` - Speed-optimized
- `presentation` - Clean interface for demos

**Examples:**
```vim
:ConfigProfile                    " List available profiles
:ConfigProfile performance        " Apply performance profile
:ConfigProfile minimal           " Apply minimal profile
```

### 📊 Analytics Commands (3 commands)

#### `:AnalyticsReport`
**Purpose:** Show comprehensive performance analytics with trends  
**Usage:** `:AnalyticsReport`  
**Output:** Performance scores, trends, usage statistics, and optimization recommendations

#### `:AnalyticsReset`
**Purpose:** Reset analytics data for fresh tracking  
**Usage:** `:AnalyticsReset`  
**Use case:** Start fresh tracking after major changes

#### `:AnalyticsExport`
**Purpose:** Export analytics data to JSON file  
**Usage:** `:AnalyticsExport`  
**Output:** JSON file with timestamp in data directory

### 🔌 Plugin Management Commands (2 commands)

#### `:PluginReport`
**Purpose:** Show plugin loading performance with environment detection  
**Usage:** `:PluginReport`  
**Output:** Plugin loading times, environment detection, failed plugins, and conditionally skipped plugins

#### `:PluginReload <name>`
**Purpose:** Hot-reload specific plugin  
**Usage:** `:PluginReload <plugin_name>`  
**Example:** `:PluginReload telescope`  
**Use case:** Reload plugin after configuration changes

### 🐛 Debug Commands (8 commands)

#### `:DebugEnable`
**Purpose:** Enable debug mode with comprehensive logging  
**Usage:** `:DebugEnable`  
**Effect:** Activates error tracking, performance tracing, and debug logging

#### `:DebugDisable`
**Purpose:** Disable debug mode  
**Usage:** `:DebugDisable`  
**Effect:** Stops debug logging and tracking

#### `:DebugReport`
**Purpose:** Generate comprehensive debug report  
**Usage:** `:DebugReport`  
**Output:** System diagnostics, error summary, performance data

#### `:DebugErrors`
**Purpose:** Show recent error history  
**Usage:** `:DebugErrors`  
**Output:** Last 10 errors with timestamps and components

#### `:DebugTraces`
**Purpose:** Show performance traces  
**Usage:** `:DebugTraces`  
**Output:** Slowest operations with timing and memory usage

#### `:DebugPluginHealth`
**Purpose:** Show plugin health status  
**Usage:** `:DebugPluginHealth`  
**Output:** Plugin loading status, failed plugins, error counts

#### `:DebugRecovery`
**Purpose:** Run emergency recovery  
**Usage:** `:DebugRecovery`  
**Actions:**
- Clears plugin cache
- Resets problematic keymaps
- Reloads core modules
- Validates configuration

#### `:DebugSafeMode`
**Purpose:** Start safe mode with minimal functionality  
**Usage:** `:DebugSafeMode`  
**Effect:** Loads only core functionality, disables non-essential plugins

### 🔄 Migration Commands (4 commands)

#### `:MigrationStatus`
**Purpose:** Show migration status and pending updates  
**Usage:** `:MigrationStatus`  
**Output:** Current version, latest version, pending migrations

#### `:MigrationRun`
**Purpose:** Run configuration migrations  
**Usage:** `:MigrationRun`  
**Actions:**
- Creates backup before migration
- Runs pending migrations in order
- Updates configuration version

#### `:MigrationHistory`
**Purpose:** Show migration history  
**Usage:** `:MigrationHistory`  
**Output:** Previous migrations with success/failure status

#### `:MigrationCheck`
**Purpose:** Check for configuration updates  
**Usage:** `:MigrationCheck`  
**Output:** Available updates and new features

### 🎨 Customization Commands (5 commands)

#### `:CustomizationStatus`
**Purpose:** Show customization system status  
**Usage:** `:CustomizationStatus`  
**Output:** User config status, custom modules, hooks, themes, extensions

#### `:CustomizationReload`
**Purpose:** Reload user customizations  
**Usage:** `:CustomizationReload`  
**Actions:** Reloads user config, applies overrides, loads custom modules

#### `:CustomizationTemplate`
**Purpose:** Create user configuration template  
**Usage:** `:CustomizationTemplate`  
**Output:** Creates `user.lua` template with examples

#### `:CustomizationTheme <name>`
**Purpose:** Apply custom theme  
**Usage:** `:CustomizationTheme [theme_name]`  
**Examples:**
```vim
:CustomizationTheme               " List available themes
:CustomizationTheme my_theme      " Apply custom theme
```

#### `:CustomizationExtension <action> <name>`
**Purpose:** Manage custom extensions  
**Usage:** `:CustomizationExtension [enable|disable|list] [name]`  
**Examples:**
```vim
:CustomizationExtension list              " List all extensions
:CustomizationExtension enable my_ext     " Enable extension
:CustomizationExtension disable my_ext    " Disable extension
```

## 🎯 Essential Keymaps

### File Management
- **`<leader>e`** - Open file explorer (Oil.nvim → netrw fallback)
- **`<leader>E`** - Open file explorer in buffer mode

### Search and Replace
- **`<leader>ss`** - Toggle Spectre (project-wide search/replace)
- **`<leader>sw`** - Search current word
- **`<leader>sp`** - Search in current file

### Terminal Management
- **`<leader>tt`** - Toggle terminal (Snacks → basic terminal fallback)
- **`<leader>tf`** - Terminal in file directory
- **`<leader>tg`** - LazyGit

### Navigation Enhancement (Flash.nvim)
- **`s`** - Flash jump to any visible location
- **`S`** - Flash treesitter navigation
- **`r`** - Remote flash (operator mode)
- **`R`** - Treesitter search

### UI Toggles
- **`<leader>ui`** - Toggle indent guides
- **`<leader>us`** - Toggle scope guides

## 🔄 Workflow Examples

### Daily Startup Routine
```vim
" Check system health
:ConfigHealth

" If health score < 80
:ConfigFix

" Check performance
:PerformanceCheck

" View analytics (weekly)
:AnalyticsReport
```

### Performance Optimization Workflow
```vim
" Check current performance
:PerformanceReport

" Apply optimizations
:PerformanceOptimize

" Switch to performance profile
:ConfigProfile performance

" Monitor plugin loading
:PluginReport
```

### Troubleshooting Workflow
```vim
" Enable debug mode
:DebugEnable

" Check for errors
:DebugErrors

" Run diagnostics
:DebugReport

" If issues persist
:DebugRecovery

" Last resort
:DebugSafeMode
```

### Configuration Update Workflow
```vim
" Check for updates
:MigrationCheck

" View current status
:MigrationStatus

" Create backup
:ConfigBackup

" Run migrations
:MigrationRun

" Verify health
:ConfigHealth
```

## 🎨 Customization Examples

### Creating Custom Theme
```lua
-- In user.lua
local customization = require('config.customization')

customization.theme('my_dark_theme', {
    colorscheme = 'default',
    highlights = {
        Normal = { bg = '#1e1e1e', fg = '#d4d4d4' },
        Comment = { fg = '#6a9955', italic = true },
    },
    settings = {
        number = true,
        relativenumber = true,
    }
})
```

### Creating Custom Extension
```lua
-- In user.lua
customization.extension('my_tools', {
    setup = function()
        -- Extension initialization
    end,
    commands = {
        MyCommand = {
            callback = function()
                vim.notify('Hello from custom command!')
            end,
            opts = { desc = 'My custom command' }
        }
    },
    keymaps = {
        { lhs = '<leader>mc', rhs = ':MyCommand<CR>', opts = { desc = 'My custom keymap' } }
    }
})
```

### Adding Custom Hooks
```lua
-- In user.lua
customization.hook('after_init', function()
    vim.notify('Custom initialization complete!', vim.log.levels.INFO)
end)

customization.hook('on_file_open', function(filename)
    -- Custom logic when files are opened
end)
```

## 🚨 Emergency Procedures

### System Not Starting
1. Start in safe mode: `:DebugSafeMode`
2. Check errors: `:DebugErrors`
3. Run recovery: `:DebugRecovery`
4. If still failing, restore from backup

### Performance Issues
1. Check performance: `:PerformanceCheck`
2. Apply optimizations: `:PerformanceOptimize`
3. Switch profile: `:ConfigProfile minimal`
4. Check plugin report: `:PluginReport`

### Configuration Corruption
1. Run validation: `:ConfigValidate`
2. Auto-fix issues: `:ConfigFix`
3. If severe, run: `:DebugRecovery`
4. Last resort: restore from `:ConfigBackup`

## 📈 Performance Monitoring

### Key Metrics to Monitor
- **Startup Time**: Should be < 300ms (check with `:PerformanceCheck`)
- **Memory Usage**: Should be < 200MB (check with `:AnalyticsReport`)
- **Plugin Load Times**: Individual plugins < 50ms (check with `:PluginReport`)
- **Health Score**: Should be > 80 (check with `:ConfigHealth`)

### Optimization Strategies
1. **Use Performance Profile**: `:ConfigProfile performance`
2. **Monitor Analytics**: Weekly `:AnalyticsReport` review
3. **Plugin Optimization**: Remove unused plugins based on `:PluginReport`
4. **Environment Adaptation**: Let system auto-detect and optimize

## 🔧 Configuration Profiles

### Profile Characteristics

#### Minimal Profile
- **Memory**: ~50-80MB
- **Startup**: ~100-200ms
- **Features**: Essential only
- **Use Case**: Remote servers, low-resource environments

#### Development Profile
- **Memory**: ~150-250MB
- **Startup**: ~200-400ms
- **Features**: All plugins enabled
- **Use Case**: Full development work

#### Performance Profile
- **Memory**: ~100-150MB
- **Startup**: ~150-250ms
- **Features**: Optimized selection
- **Use Case**: Performance-critical work

#### Presentation Profile
- **Memory**: ~80-120MB
- **Startup**: ~100-200ms
- **Features**: Clean UI, large fonts
- **Use Case**: Demonstrations, teaching

## 📚 Additional Resources

### Documentation Files
- **User Guide**: `docs/user-guide-new-features.md` - Comprehensive feature guide
- **Implementation Summary**: `docs/comprehensive-implementation-summary-2025-01-10.md`
- **Project Completion**: `docs/final-project-completion-summary.md`

### Configuration Files
- **User Customization**: `user.lua` - Your personal customizations
- **Performance Config**: `lua/config/performance.lua`
- **Validation Config**: `lua/config/validation.lua`

### Getting Help
1. **Check Health**: `:ConfigHealth` for overall status
2. **Run Validation**: `:ConfigValidate` for detailed issues
3. **View Analytics**: `:AnalyticsReport` for performance insights
4. **Debug Mode**: `:DebugEnable` then `:DebugReport` for diagnostics

---

**Quick Help**: Run `:ConfigHealth` for system status or `:ConfigFix` for auto-repair.  
**Performance Issues**: Try `:PerformanceOptimize` or `:ConfigProfile performance`.  
**Need Insights**: Use `:AnalyticsReport` for comprehensive analytics.  
**Emergency**: Use `:DebugRecovery` for automatic recovery.