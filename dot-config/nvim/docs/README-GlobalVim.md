# Global Vim Object Configuration Guide

This document explains how the global `vim` object is configured and enhanced in your Neovim setup.

## Overview

The global `vim` object is now fully enabled and enhanced with additional utilities for easier Neovim configuration and development.

## Configuration Files

### Core Configuration
- **File:** [`lua/config/globals.lua`](../lua/config/globals.lua) - Main global object configuration
- **File:** [`lua/config/init.lua`](../lua/config/init.lua) - Loads globals early in the startup process
- **File:** [`lua/plugins/lsp/servers.lua`](../lua/plugins/lsp/servers.lua) - LSP server recognition of globals

## What's Enabled

### 1. Core Vim Object
The `vim` object is globally accessible everywhere in your configuration:

```lua
-- These work anywhere in your config
vim.opt.number = true
vim.keymap.set('n', '<leader>w', ':w<CR>')
vim.api.nvim_create_autocmd('BufWritePre', {...})
```

### 2. Enhanced Global Utilities

#### Debug and Inspection
```lua
-- Pretty print any Lua object
P(vim.opt.number)  -- Prints the option value
P({foo = "bar", baz = 123})  -- Prints table structure

-- Enhanced debugging (uses Snacks if available)
dd(some_variable)  -- Debug dump
bt()  -- Backtrace
```

#### Development Helpers
```lua
-- Reload modules during development
R("config.keymaps")  -- Reloads and returns the module

-- Quick keymap creation
map('n', '<leader>ff', ':Telescope find_files<CR>', { desc = "Find files" })

-- Quick autocmd creation
autocmd('BufWritePre', {
    pattern = '*.lua',
    callback = function() print("Saving Lua file") end
})

-- Quick command creation
command('MyCommand', function() print("Hello!") end, { desc = "My custom command" })
```

#### LSP and Diagnostic Shortcuts
```lua
-- Quick access to LSP functions
lsp.buf.hover()  -- Instead of vim.lsp.buf.hover()
diagnostic.open_float()  -- Instead of vim.diagnostic.open_float()

-- Get info about active LSP clients
lsp_info()  -- Shows all active LSP clients for current buffer
```

### 3. Enhanced Vim Object Properties

#### Path Utilities
```lua
-- Quick access to important paths
print(vim.g.config_path)  -- Your Neovim config directory
print(vim.g.data_path)    -- Neovim data directory
print(vim.g.cache_path)   -- Neovim cache directory
```

#### Utility Functions
```lua
-- Check if a plugin is available
if vim.utils.has_plugin("telescope") then
    -- Use telescope
end

-- Safely require modules
local telescope = vim.utils.safe_require("telescope")
if telescope then
    -- Use telescope safely
end

-- Get current buffer information
local info = vim.utils.buf_info()
print(info.filename)  -- Current file name
print(info.filetype)  -- Current file type
```

## Usage Examples

### In Your Configuration Files
```lua
-- lua/config/keymaps.lua
map('n', '<leader>ff', function()
    if vim.utils.has_plugin("telescope") then
        require("telescope.builtin").find_files()
    else
        vim.cmd("edit .")
    end
end, { desc = "Find files" })

-- lua/config/autocommands.lua
autocmd("BufWritePre", {
    pattern = "*.lua",
    callback = function()
        local info = vim.utils.buf_info()
        print("Saving: " .. info.filename)
    end
})
```

### In Command Line Mode
```vim
" These work in Neovim command line
:lua P(vim.opt.number)
:lua dd(vim.g)
:lua lsp_info()
```

### For Plugin Development
```lua
-- When developing plugins or configurations
local my_plugin = R("my_plugin")  -- Reload and test
P(my_plugin.config)  -- Inspect configuration
dd(my_plugin.state)  -- Debug current state
```

## LSP Integration

The Lua Language Server is configured to recognize all global objects, so you get:

- **Autocompletion** for `vim.*`, `P()`, `dd()`, etc.
- **No warnings** about undefined globals
- **Type hints** and documentation
- **Go-to-definition** support

## Benefits

1. **Cleaner Code**: Shorter, more readable configuration
2. **Better DX**: Enhanced debugging and development tools
3. **Consistency**: Standardized utilities across your config
4. **LSP Support**: Full language server integration
5. **Flexibility**: Easy to extend with more utilities

## Extending the Configuration

To add more global utilities, edit [`lua/config/globals.lua`](../lua/config/globals.lua):

```lua
-- Add your custom globals
_G.my_utility = function()
    -- Your utility function
end

-- Add to LSP globals in lua/plugins/lsp/servers.lua
diagnostics = {
    globals = {
        -- ... existing globals ...
        'my_utility',
    },
},
```

## Migration Notes

If you had any existing global configurations, they should continue to work. The new setup enhances rather than replaces existing functionality.

## Troubleshooting

### LSP Warnings About Globals
If you see warnings about undefined globals, add them to the `globals` list in [`lua/plugins/lsp/servers.lua`](../lua/plugins/lsp/servers.lua).

### Function Not Available
Some enhanced functions (like `dd()` and `bt()`) depend on plugins being loaded. They fall back to basic implementations if plugins aren't available.

### Reload Issues
If you modify [`lua/config/globals.lua`](../lua/config/globals.lua), restart Neovim or use `:lua R("config.globals")` to reload.