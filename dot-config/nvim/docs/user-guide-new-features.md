# Neovim Configuration User Guide - New Features
**Version:** 2025.01.10  
**Last Updated:** January 10, 2025  
**Target Users:** All Neovim users with the enhanced configuration

## Table of Contents

- [Quick Start](#quick-start)
- [Performance Monitoring](#performance-monitoring)
- [Configuration Validation](#configuration-validation)
- [Plugin Management](#plugin-management)
- [Performance Analytics](#performance-analytics)
- [Configuration Profiles](#configuration-profiles)
- [New Essential Plugins](#new-essential-plugins)
- [Enhanced Keymaps](#enhanced-keymaps)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## Quick Start

### First Time Setup
After updating your configuration, run these commands to get started:

```vim
:ConfigValidate    " Check configuration health
:PerformanceCheck  " Verify performance status
:ConfigHealth      " Get overall health score
```

### Daily Usage Commands
```vim
:AnalyticsReport   " View performance insights
:PluginReport      " Check plugin loading performance
:ConfigFix         " Auto-fix any issues
```

## Performance Monitoring

### Overview
The performance monitoring system tracks startup time, memory usage, and plugin performance in real-time.

### Commands

#### `:PerformanceCheck`
Runs a comprehensive performance health check.

**Example Output:**
```
=== Neovim Performance Health Check ===
Timestamp: 2025-01-10 15:30:00
Startup Time: 245.32ms
Memory Usage: 142.3MB
Loaded Plugins: 47

=== Issues Found ===
✅ No issues detected
```

#### `:PerformanceOptimize`
Applies automated performance optimizations.

**What it does:**
- Adjusts `updatetime` to 250ms
- Sets `synmaxcol` to 300 for better syntax highlighting
- Enables `lazyredraw` for smoother scrolling
- Optimizes completion settings

#### `:PerformanceReport`
Shows detailed performance metrics and plugin load times.

**Example Output:**
```
=== Performance Metrics ===
Startup Time: 245.32ms
Memory Usage: 142.3MB

=== Plugin Load Times ===
15.23ms - telescope.nvim
12.45ms - nvim-treesitter
8.67ms - which-key.nvim
```

### Automatic Monitoring
The system automatically:
- Warns if startup time exceeds 200ms
- Alerts if memory usage exceeds 500MB
- Tracks plugin loading performance
- Monitors memory usage every minute

## Configuration Validation

### Overview
The validation system continuously monitors configuration health and can automatically fix common issues.

### Commands

#### `:ConfigValidate`
Runs comprehensive configuration validation.

**Checks performed:**
- Plugin conflicts and missing dependencies
- Keymap conflicts and missing essential keymaps
- LSP server configuration
- Security settings
- Performance-impacting settings

**Example Output:**
```
=== Configuration Validation Report ===
Timestamp: 2025-01-10 15:30:00
Issues Found: 2

=== Performance Settings ===
⚠️ 🟡 updatetime is set to 400 (recommended: 250)
   💡 Consider reducing updatetime for better performance

=== Missing Keymaps ===
⚠️ 🟢 Missing essential keymaps: <leader>fg
   💡 Add missing keymaps for better workflow
```

#### `:ConfigFix`
Automatically fixes configuration issues.

**What it fixes:**
- Performance settings (updatetime, timeoutlen, synmaxcol)
- Security settings (disables modeline, fixes backup directory)
- Missing essential keymaps (adds with intelligent fallbacks)

**Example Output:**
```
=== Auto-Fix Report ===
✅ Fixed updatetime setting
✅ Fixed synmaxcol setting
✅ Added missing keymap: <leader>fg
⚠️ Could not auto-fix: Missing LSP server: gopls

Auto-fixed 3 out of 4 issues
💾 Consider saving your configuration to persist these fixes
```

#### `:ConfigHealth`
Shows configuration health score (0-100).

**Scoring:**
- 90-100: Excellent configuration health
- 70-89: Good configuration with minor issues
- 50-69: Configuration needs attention
- 0-49: Configuration requires immediate fixes

#### `:ConfigBackup`
Creates a timestamped backup of your configuration.

**Example:**
```
Configuration backed up to: ~/.local/share/nvim/config_backups/config_backup_20250110_153000.tar.gz
```

## Plugin Management

### Overview
The advanced plugin loader provides intelligent plugin loading with environment detection and performance monitoring.

### Commands

#### `:PluginReport`
Shows plugin loading performance with environment detection.

**Example Output:**
```
=== Plugin Loading Performance Report ===
Total Plugins: 47
Successfully Loaded: 45
Failed: 1
Conditionally Skipped: 1
Total Load Time: 234.56ms
Total Memory Usage: +89.2MB

=== Environment Detection ===
Large Project: No
Git Repository: Yes
Development Environment: Yes
Available Memory: 8192MB

=== Slowest Plugins ===
15.23ms - telescope.nvim
12.45ms - nvim-treesitter
8.67ms - which-key.nvim

=== Failed Plugins ===
❌ some-plugin: Plugin not found

=== Conditionally Skipped ===
⏭️ heavy-plugin (reason: large_project_plugins)
```

#### `:PluginReload <name>`
Hot-reloads a specific plugin.

**Usage:**
```vim
:PluginReload telescope    " Reload telescope plugin
```

### Environment Detection
The system automatically detects:
- **Large Projects**: >5000 files (skips heavy plugins)
- **Git Repositories**: Enables git-related plugins
- **Development Environment**: Detects package.json, Cargo.toml, etc.
- **Available Memory**: Adjusts plugin loading based on system resources

### Conditional Loading
Plugins are loaded based on:
- Available system memory
- Project size and type
- Development environment indicators
- User preferences and profiles

## Performance Analytics

### Overview
Advanced analytics system that tracks usage patterns, performance trends, and provides optimization recommendations.

### Commands

#### `:AnalyticsReport`
Shows comprehensive performance analytics with trends.

**Example Output:**
```
=== Advanced Performance Analytics Report ===
Generated: 2025-01-10 15:30:00
Session Duration: 2.5 hours

=== Performance Scores ===
Overall Score: 85/100
🟢 Startup: 90/100
🟡 Memory: 75/100
🟢 Lsp: 95/100

=== Performance Trends ===
Startup Time: 245ms (trend: stable, -2.1%)
Memory Usage: 142MB (trend: stable)

=== Optimization Recommendations ===
--- Medium Priority ---
📋 Completion Performance: Slow completion provider: cmp_nvim_lsp (180ms avg)
   💡 Consider adjusting completion settings or switching providers

=== Usage Statistics ===
Total Keymaps Used: 23
Total Commands Used: 15
File Operations: 42
```

#### `:AnalyticsReset`
Resets analytics data for fresh tracking.

#### `:AnalyticsExport`
Exports analytics data to JSON file for external analysis.

**Example:**
```
Analytics exported to: ~/.local/share/nvim/analytics_export_20250110_153000.json
```

### Tracked Metrics
- **Startup Times**: Historical startup performance
- **Memory Usage**: Real-time memory consumption
- **Plugin Performance**: Individual plugin loading times
- **Keymap Usage**: Frequency of keymap usage
- **Command Usage**: Most used commands
- **LSP Performance**: Language server response times
- **Completion Stats**: Completion provider performance

### Trend Analysis
- **Performance Trends**: Week-over-week performance comparison
- **Usage Patterns**: Identification of frequently/rarely used features
- **Optimization Opportunities**: Automated recommendations

## Configuration Profiles

### Overview
Multiple configuration profiles for different use cases and environments.

### Available Profiles

#### Minimal Profile
- **Use Case**: Low-resource environments, remote servers
- **Features**: Essential functionality only, no AI, minimal UI
- **Memory Usage**: ~50-80MB
- **Startup Time**: ~100-200ms

#### Development Profile
- **Use Case**: Full-featured development environment
- **Features**: All plugins enabled, AI assistance, debugging tools
- **Memory Usage**: ~150-250MB
- **Startup Time**: ~200-400ms

#### Performance Profile
- **Use Case**: Performance-optimized for speed
- **Features**: AI enabled, heavy plugins disabled, optimized settings
- **Memory Usage**: ~100-150MB
- **Startup Time**: ~150-250ms

#### Presentation Profile
- **Use Case**: Clean interface for demonstrations
- **Features**: Minimal UI, large fonts, no distractions
- **Memory Usage**: ~80-120MB
- **Startup Time**: ~100-200ms

### Commands

#### `:ConfigProfile`
Lists available profiles.

#### `:ConfigProfile <name>`
Applies a specific profile.

**Examples:**
```vim
:ConfigProfile minimal       " Apply minimal profile
:ConfigProfile development   " Apply development profile
:ConfigProfile performance   " Apply performance profile
:ConfigProfile presentation  " Apply presentation profile
```

**Example Output:**
```
=== Profile Applied: performance ===
Performance-optimized configuration

Changes applied:
✅ Applied performance optimizations
✅ Applied minimal UI settings
✅ Heavy plugins will be disabled on next restart
```

## New Essential Plugins

### nvim-spectre (Advanced Search & Replace)
**Purpose**: Project-wide search and replace with preview

**Key Features:**
- Visual search and replace interface
- Regex support with live preview
- Integration with ripgrep for fast searching
- Undo/redo support for replacements

**Keymaps:**
- `<leader>ss` - Toggle Spectre
- `<leader>sw` - Search current word
- `<leader>sp` - Search in current file

**Usage Example:**
1. Press `<leader>ss` to open Spectre
2. Enter search term in the search field
3. Enter replacement in the replace field
4. Review matches in the preview
5. Press `<C-c>` to execute replacements

### flash.nvim (Enhanced Navigation)
**Purpose**: Lightning-fast navigation with labeled jumps

**Key Features:**
- Label-based jumping to any visible location
- Treesitter integration for smart navigation
- Multiple jump modes (char, word, line)
- Search integration with live highlighting

**Keymaps:**
- `s` - Flash jump
- `S` - Flash treesitter
- `r` - Remote flash (in operator mode)
- `R` - Treesitter search
- `<c-s>` - Toggle flash search

**Usage Example:**
1. Press `s` in normal mode
2. Type the character you want to jump to
3. Press the highlighted label to jump

### oil.nvim (File Explorer)
**Purpose**: Edit your filesystem like a buffer

**Key Features:**
- Edit directories like normal buffers
- Direct file manipulation (rename, delete, create)
- Integration with existing Neovim workflows
- Floating window support

**Keymaps:**
- `<leader>e` - Open file explorer (floating)
- `<leader>E` - Open file explorer (buffer)

**Usage Example:**
1. Press `<leader>e` to open the file explorer
2. Navigate using normal Neovim motions
3. Edit filenames directly in the buffer
4. Save the buffer to apply changes

### indent-blankline.nvim (Indentation Guides)
**Purpose**: Visual indentation guides with scope highlighting

**Key Features:**
- Indentation guides for better code structure visibility
- Scope highlighting for current context
- Rainbow indentation support
- Performance-optimized rendering

**Commands:**
- `:IBLToggle` - Toggle indent guides
- `:IBLToggleScope` - Toggle scope guides

## Enhanced Keymaps

### New Essential Keymaps
All new keymaps include intelligent fallbacks for when plugins aren't available.

#### File Explorer
- `<leader>e` - Open file explorer
  - **Primary**: Oil.nvim floating window
  - **Fallback**: Netrw file explorer

#### Terminal Management
- `<leader>tt` - Toggle terminal
  - **Primary**: Snacks terminal
  - **Fallback**: Basic terminal

#### Search and Replace
- `<leader>ss` - Search and replace in project
  - **Primary**: Spectre interface
  - **Fallback**: Basic search/replace dialog

### Enhanced Which-Key Integration
All new plugins are fully integrated with Which-Key for better discoverability:

- `<leader>e` group - Explorer functions
- `<leader>s` group - Search functions (enhanced)
- `<leader>t` group - Terminal functions (enhanced)
- `<leader>u` group - UI toggles (enhanced with new plugins)

## Troubleshooting

### Common Issues and Solutions

#### Slow Startup
**Symptoms**: Neovim takes >500ms to start
**Solutions**:
1. Run `:PerformanceCheck` to identify issues
2. Run `:PerformanceOptimize` to apply fixes
3. Consider switching to performance profile: `:ConfigProfile performance`
4. Check plugin report: `:PluginReport`

#### High Memory Usage
**Symptoms**: Memory usage >300MB
**Solutions**:
1. Run `:AnalyticsReport` to see memory trends
2. Switch to minimal profile: `:ConfigProfile minimal`
3. Restart Neovim to clear memory leaks
4. Check for memory-heavy plugins in `:PluginReport`

#### Plugin Conflicts
**Symptoms**: Unexpected behavior, error messages
**Solutions**:
1. Run `:ConfigValidate` to check for conflicts
2. Run `:ConfigFix` to auto-resolve issues
3. Check `:PluginReport` for failed plugins
4. Reload problematic plugins: `:PluginReload <name>`

#### Missing Features
**Symptoms**: Expected functionality not working
**Solutions**:
1. Run `:ConfigValidate` to check for missing dependencies
2. Verify plugin installation with `:PluginReport`
3. Check if features are disabled in current profile
4. Run `:ConfigFix` to add missing keymaps

### Debug Commands
```vim
:ConfigHealth          " Overall health score
:ConfigValidate        " Detailed validation report
:PerformanceCheck      " Performance health check
:PluginReport          " Plugin loading status
:AnalyticsReport       " Performance analytics
```

### Getting Help
1. **Check Documentation**: Review this guide and inline help
2. **Run Diagnostics**: Use the debug commands above
3. **Check Logs**: Look for error messages in `:messages`
4. **Reset Configuration**: Use `:ConfigFix` for auto-repair

## Advanced Usage

### Custom Profile Creation
You can create custom profiles by modifying the profiles table in `lua/config/validation.lua`:

```lua
local profiles = {
    custom = {
        ai_enabled = true,
        heavy_plugins = false,
        performance_optimized = true,
        custom_setting = true,
        description = "My custom configuration profile"
    }
}
```

### Performance Monitoring Integration
Monitor specific operations by using the performance tracking functions:

```lua
-- Track custom operation performance
require('config.performance').track_operation('my_operation', function()
    -- Your code here
end)
```

### Analytics Integration
Add custom metrics to the analytics system:

```lua
-- Record custom metrics
require('config.analytics').record_custom_metric('operation_name', duration, metadata)
```

### Plugin Loader Customization
Customize plugin loading conditions:

```lua
-- Add custom loading condition
local plugin_loader = require('config.plugin-loader')
plugin_loader.add_condition('my_condition', function()
    return vim.fn.has('gui_running') == 1
end)
```

### Validation Rules
Add custom validation rules:

```lua
-- Add custom validation
local validation = require('config.validation')
validation.add_validator('my_check', function()
    -- Return issues table
    return {}
end)
```

## Best Practices

### Daily Workflow
1. **Morning Setup**: Run `:ConfigHealth` to check system status
2. **Performance Monitoring**: Periodically check `:PerformanceCheck`
3. **Issue Resolution**: Use `:ConfigFix` when issues are detected
4. **Analytics Review**: Weekly `:AnalyticsReport` for optimization insights

### Profile Usage
- **Development Work**: Use `development` profile for full features
- **Remote Servers**: Use `minimal` profile for resource constraints
- **Performance Critical**: Use `performance` profile for speed
- **Presentations**: Use `presentation` profile for clean interface

### Maintenance
- **Weekly**: Review `:AnalyticsReport` for optimization opportunities
- **Monthly**: Run `:ConfigBackup` to create configuration snapshots
- **As Needed**: Use `:ConfigFix` to resolve emerging issues

### Optimization
- **Monitor Trends**: Use analytics to identify performance degradation
- **Profile Switching**: Adapt profiles to current work requirements
- **Plugin Management**: Regularly review `:PluginReport` for optimization

---

**Need Help?** Run `:ConfigValidate` for health checks or `:ConfigFix` for auto-repair.  
**Performance Issues?** Try `:PerformanceOptimize` or switch profiles with `:ConfigProfile`.  
**Want Insights?** Use `:AnalyticsReport` for comprehensive performance analytics.