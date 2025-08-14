# Conform.nvim Code Formatting Guide

This document provides a complete guide for the conform.nvim integration in your Neovim configuration, which provides fast and flexible code formatting.

## Overview

Conform.nvim is a modern code formatter that provides:
- **Fast formatting** with async support
- **Multiple formatter support** per filetype
- **LSP fallback** when formatters aren't available
- **Format on save** with intelligent fallbacks
- **Extensive language support** with 30+ formatters configured

## Configuration Files

### Core Configuration
- **File:** [`lua/plugins/editor/conform.lua`](../lua/plugins/editor/conform.lua) - Main conform.nvim setup
- **File:** [`lua/plugins/lsp/mason.lua`](../lua/plugins/lsp/mason.lua) - Formatter installation via Mason
- **File:** [`lua/plugins/lsp/init.lua`](../lua/plugins/lsp/init.lua) - LSP integration with conform
- **File:** [`lua/plugins/init.lua`](../lua/plugins/init.lua) - Plugin declaration and loading

## Supported Languages and Formatters

### Web Development
- **JavaScript/TypeScript**: `biome`, `prettier`
- **HTML/CSS/SCSS**: `prettier`
- **JSON/YAML**: `biome`, `prettier`
- **Vue/Svelte/Astro**: `prettier`
- **GraphQL**: `prettier`

### Backend Languages
- **Lua**: `stylua`
- **Python**: `isort`, `black`
- **PHP**: `php_cs_fixer`, `pint` (Laravel)
- **Rust**: `rustfmt`
- **Go**: `gofmt`, `goimports`
- **Java**: `google_java_format`
- **C/C++**: `clang_format`

### Shell and Config
- **Shell Scripts**: `shfmt`
- **TOML**: `taplo`
- **XML**: `xmlformat`
- **SQL**: `sqlformat`
- **Terraform**: `terraform_fmt`
- **Nix**: `nixfmt`

### Mobile and Other
- **Swift**: `swift_format`
- **Kotlin**: `ktlint`
- **Dart**: `dart_format`
- **Ruby**: `rubocop`
- **Elixir**: `mix`
- **Haskell**: `ormolu`

## Key Features

### 1. Format on Save
Automatically formats files when saving with intelligent fallbacks:

```lua
-- Enabled by default, can be toggled with <leader>ct
format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
}
```

### 2. Multiple Formatters per Filetype
Uses the best available formatter for each language:

```lua
-- Example: JavaScript can use biome (faster) or prettier (fallback)
javascript = { "biome", "prettier" }
```

### 3. Smart LSP Integration
Prefers LSP formatting for certain languages (Go, Rust) while using conform for others.

### 4. Async Formatting
All formatting operations are asynchronous to avoid blocking the editor.

## Keymaps

### Primary Formatting
- **`<leader>cf`** - Format current buffer or selection
- **`<leader>cF`** - Choose specific formatter (shows picker)
- **`<leader>lf`** - Format with LSP/Conform integration

### Utility Commands
- **`<leader>ct`** - Toggle format on save
- **`<leader>ci`** - Show available formatters for current buffer

### Visual Mode
- **`<leader>cf`** - Format selected text only

## Usage Examples

### Basic Formatting
```lua
-- Format current buffer
:lua require("conform").format()

-- Format with specific timeout
:lua require("conform").format({ timeout_ms = 2000 })

-- Format selection in visual mode
-- Select text, then press <leader>cf
```

### Advanced Usage
```lua
-- Check if formatting is available
:lua print(vim.conform.can_format())

-- Get available formatters
:lua P(vim.conform.get_formatters())

-- Format with specific formatter
:lua vim.conform.format_with("prettier")
```

### Command Line
```vim
" Format current buffer
:lua require("conform").format()

" Show formatters
:lua P(vim.conform.get_formatters())
```

## Configuration Customization

### Adding New Formatters
Edit [`lua/plugins/editor/conform.lua`](../lua/plugins/editor/conform.lua):

```lua
formatters_by_ft = {
    -- Add new language support
    your_language = { "your_formatter" },
}

formatters = {
    -- Configure formatter options
    your_formatter = {
        prepend_args = { "--your-option", "value" },
    },
}
```

### Installing Formatters
Add to [`lua/plugins/lsp/mason.lua`](../lua/plugins/lsp/mason.lua):

```lua
ensure_installed = {
    -- ... existing formatters ...
    "your-new-formatter",
}
```

### Disabling Format on Save
```lua
-- Temporarily disable
:lua require("conform").format_on_save = nil

-- Or use the toggle keymap
<leader>ct
```

## Formatter-Specific Configuration

### Stylua (Lua)
```lua
stylua = {
    prepend_args = {
        "--column-width", "120",
        "--indent-type", "Spaces",
        "--indent-width", "4",
    },
}
```

### Prettier (Web)
```lua
prettier = {
    prepend_args = {
        "--tab-width", "4",
        "--print-width", "120",
        "--single-quote", "false",
    },
}
```

### Black (Python)
```lua
black = {
    prepend_args = {
        "--line-length", "120",
        "--target-version", "py38",
    },
}
```

## Integration with Other Tools

### LSP Servers
Conform works alongside LSP servers:
- **Primary**: Conform handles most formatting
- **Fallback**: LSP formatting when conform isn't available
- **Specific**: Some languages (Go, Rust) prefer LSP formatting

### Blink.cmp
Formatting integrates with your completion setup without conflicts.

### Which-key
All keymaps are automatically documented in which-key under the `<leader>c` prefix.

## Troubleshooting

### Formatter Not Found
1. Check if formatter is installed: `:Mason`
2. Verify formatter name in Mason matches conform config
3. Check formatter is in PATH: `:!which formatter_name`

### Format on Save Not Working
1. Check if format on save is enabled: `:lua P(require("conform").format_on_save)`
2. Toggle format on save: `<leader>ct`
3. Check for filetype-specific disabling in config

### Slow Formatting
1. Check timeout settings in config
2. Use faster formatters (e.g., `biome` instead of `prettier`)
3. Consider disabling format on save for large files

### Conflicting Formatters
1. Check formatter priority in `formatters_by_ft`
2. Use `<leader>cF` to choose specific formatter
3. Adjust LSP vs conform priority in config

## Performance Tips

1. **Use Biome** instead of Prettier for JavaScript/TypeScript (much faster)
2. **Adjust timeouts** based on project size
3. **Disable format on save** for very large files
4. **Use LSP formatting** for languages with fast LSP formatters

## Migration from Other Formatters

### From null-ls
Conform.nvim is a direct replacement for null-ls formatting. The configuration is similar but more performant.

### From LSP-only Formatting
Keep existing LSP setup - conform integrates seamlessly with LSP fallback.

### From Manual Formatting
All your existing `:!prettier %` type commands can be replaced with conform keymaps.

## Advanced Features

### Custom Formatters
```lua
-- Add custom formatter
formatters = {
    my_custom_formatter = {
        command = "my_formatter",
        args = { "--stdin", "$FILENAME" },
        stdin = true,
    },
}
```

### Conditional Formatting
```lua
-- Format only if certain conditions are met
format_on_save = function(bufnr)
    if vim.bo[bufnr].filetype == "large_file_type" then
        return nil -- Skip formatting
    end
    return { timeout_ms = 500, lsp_fallback = true }
end
```

### Project-Specific Configuration
Create `.conform.lua` in project root for project-specific formatter settings.

## Status Integration

Conform status is available for statusline integration:

```lua
-- Check if buffer can be formatted
local can_format = vim.conform.can_format()

-- Get active formatters
local formatters = vim.conform.get_formatters()