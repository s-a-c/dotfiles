# Blink-Copilot Integration Guide

This document provides a complete guide for the blink-copilot integration in your Neovim configuration, which brings GitHub Copilot completions directly into your blink.cmp completion engine.

## Overview

Blink-copilot seamlessly integrates GitHub Copilot's AI-powered code completions with blink.cmp, providing intelligent code suggestions directly in your completion menu alongside LSP, snippets, and other sources.

## Installation

The plugin has been integrated into your configuration with the following changes:

### 1. Plugin Declaration
**File:** `lua/plugins/init.lua` (line 113)
```lua
{ src = "https://github.com/fang2hou/blink-copilot" },
```

### 2. Configuration Files
**File:** `lua/plugins/ai/blink-copilot.lua`
- Comprehensive blink-copilot setup with optimized defaults
- Copilot status management functions
- Performance and caching configuration
- Custom keymaps for Copilot control

### 3. Blink.cmp Integration
**File:** `lua/plugins/lsp/completion.lua` (lines 72-91)
- Added Copilot as the highest priority completion source
- Custom transform function for Copilot branding
- Optimized settings for AI completions

### 4. Plugin Loading
**File:** `lua/plugins/init.lua` (line 189)
```lua
require("plugins.ai.blink-copilot")
```

## Key Features

### Intelligent Completion Integration
- **High Priority**: Copilot suggestions appear first in completion menu
- **AI Branding**: Copilot completions are clearly marked with  icon
- **Smart Filtering**: Duplicate and low-quality suggestions are filtered out
- **Context Awareness**: Uses surrounding code context for better suggestions

### Performance Optimization
- **Caching**: Intelligent caching system for faster responses
- **Debouncing**: 150ms debounce delay to reduce API calls
- **Async Processing**: Non-blocking completion requests
- **Timeout Control**: 5-second timeout for completion requests

### Customizable Behavior
- **Trigger Length**: Minimum 1 character to trigger completions
- **Max Completions**: Up to 3 suggestions per request
- **Context Lines**: Up to 100 lines of surrounding context
- **File Extension**: Includes file type in context

## Keymaps Reference

### Copilot Control
| Keymap | Description |
|--------|-------------|
| `<leader>cpt` | Toggle Copilot on/off |
| `<leader>cps` | Show Copilot status |
| `<leader>cpa` | Authenticate Copilot |
| `<leader>cpu` | Setup Copilot |

### Blink-Copilot Specific
| Keymap | Description |
|--------|-------------|
| `<leader>cpr` | Refresh Copilot cache |
| `<leader>cpd` | Toggle debug mode |

### Completion Navigation (in completion menu)
| Keymap | Description |
|--------|-------------|
| `<C-space>` | Show/hide completion menu |
| `<C-n>` | Next completion item |
| `<C-p>` | Previous completion item |
| `<C-y>` | Accept selected completion |
| `<C-e>` | Hide completion menu |
| `<Tab>` | Navigate snippets forward |
| `<S-Tab>` | Navigate snippets backward |

## Configuration Details

### Source Priority Order
1. **Copilot** (Priority: 100) - AI-powered completions
2. **LSP** - Language server completions
3. **Path** - File path completions
4. **Snippets** - Code snippets
5. **Buffer** - Text from current buffer

### Copilot Settings
```lua
-- In lua/plugins/ai/blink-copilot.lua
copilot = {
    enabled = true,
    api = {
        timeout = 5000,
        max_completions = 3,
    },
    completion = {
        min_trigger_length = 1,
        debounce_delay = 150,
        max_context_lines = 100,
    },
    performance = {
        cache_enabled = true,
        cache_size = 100,
        cache_ttl = 300,
        async = true,
    },
}
```

### Blink.cmp Integration
```lua
-- In lua/plugins/lsp/completion.lua
sources = {
    default = { 'copilot', 'lsp', 'path', 'snippets', 'buffer' },
    providers = {
        copilot = {
            name = 'Copilot',
            module = 'blink-copilot',
            enabled = true,
            opts = {
                priority = 100,
                timeout = 5000,
                max_completions = 3,
                min_trigger_length = 1,
                debounce_delay = 150,
            },
        },
    },
}
```

## Usage Examples

### 1. Basic Code Completion
```
1. Start typing in any supported file
2. Copilot suggestions appear with  icon
3. Use <C-n>/<C-p> to navigate
4. Press <C-y> to accept suggestion
```

### 2. Function Implementation
```
1. Type function signature: `function calculateTotal(`
2. Copilot suggests complete implementation
3. Review suggestion in completion menu
4. Accept with <C-y> or continue typing
```

### 3. Context-Aware Suggestions
```
1. Write comments describing functionality
2. Start typing function/variable names
3. Copilot provides contextually relevant suggestions
4. Suggestions adapt to your coding patterns
```

### 4. Multi-line Completions
```
1. Copilot can suggest entire code blocks
2. Suggestions appear as single completion items
3. Accept to insert complete implementation
4. Use snippet navigation if applicable
```

## Troubleshooting

### Common Issues

1. **No Copilot suggestions appearing**
   - Check Copilot authentication: `<leader>cps`
   - Ensure Copilot is enabled: `<leader>cpt`
   - Verify internet connection
   - Check if file type is supported

2. **Slow completion responses**
   - Check network connectivity
   - Increase timeout: Edit `timeout` in configuration
   - Clear cache: `<leader>cpr`
   - Reduce `max_context_lines` for better performance

3. **Too many/few suggestions**
   - Adjust `max_completions` in configuration
   - Modify `min_trigger_length` for sensitivity
   - Check `debounce_delay` for responsiveness

4. **Copilot authentication issues**
   - Run `:Copilot auth` or use `<leader>cpa`
   - Check GitHub Copilot subscription status
   - Verify VS Code Copilot extension is not conflicting

### Debug Mode
Enable debug mode for troubleshooting:
```lua
-- In lua/plugins/ai/blink-copilot.lua
debug = {
    enabled = true,
    level = 3, -- 1=error, 2=warn, 3=info, 4=debug
}
```

Or toggle at runtime: `<leader>cpd`

### Performance Tuning

For better performance on slower systems:
```lua
-- Reduce context and increase delays
completion = {
    min_trigger_length = 2,
    debounce_delay = 300,
    max_context_lines = 50,
},
api = {
    timeout = 3000,
    max_completions = 1,
},
```

For faster systems with good connectivity:
```lua
-- More aggressive settings
completion = {
    min_trigger_length = 1,
    debounce_delay = 100,
    max_context_lines = 200,
},
api = {
    timeout = 8000,
    max_completions = 5,
},
```

## Integration with Other Tools

### Which-Key
- All keymaps are automatically registered with descriptions
- Press `<leader>cp` to see all Copilot-related options

### LSP Integration
- Copilot works alongside LSP completions
- LSP diagnostics inform Copilot suggestions
- No conflicts with existing LSP setup

### Snippet Integration
- Copilot suggestions can include snippet placeholders
- Use `<Tab>`/`<S-Tab>` to navigate snippet fields
- Works with existing snippet sources

### Git Integration
- Copilot considers git history for suggestions
- Works well with commit message generation
- Respects .gitignore patterns

## Customization Options

### Custom Highlight Groups
```lua
-- In lua/plugins/ai/blink-copilot.lua
vim.api.nvim_set_hl(0, "BlinkCmpCopilot", {
    fg = "#6CC644", -- GitHub green
    italic = true,
})
```

### Custom Transform Function
```lua
-- Modify completion item appearance
transform_items = function(ctx, items)
    for _, item in ipairs(items) do
        item.source_name = "AI"
        item.label = "🤖 " .. item.label
    end
    return items
end,
```

### File Type Specific Settings
```lua
-- Disable for certain file types
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "text" },
    callback = function()
        require('blink-copilot').disable()
    end,
})
```

## Best Practices

1. **Authentication**: Ensure Copilot is properly authenticated before use
2. **Context**: Provide clear comments and function signatures for better suggestions
3. **Review**: Always review AI-generated code before accepting
4. **Performance**: Monitor completion speed and adjust settings as needed
5. **Privacy**: Be aware of code context sent to Copilot API
6. **Fallback**: Keep other completion sources enabled for comprehensive coverage

## Advanced Configuration

### Custom API Endpoint
```lua
-- For enterprise GitHub instances
api = {
    endpoint = "https://your-enterprise.github.com/api/copilot",
}
```

### Conditional Enabling
```lua
-- Enable only for specific projects
enabled = vim.fn.getcwd():match("/work/projects") ~= nil,
```

### Custom Caching Strategy
```lua
performance = {
    cache_enabled = true,
    cache_size = 200,
    cache_ttl = 600, -- 10 minutes
    -- Custom cache key function
    cache_key = function(context)
        return context.bufnr .. ":" .. context.cursor[1]
    end,
}
```

## Support

- **Plugin Repository**: [fang2hou/blink-copilot](https://github.com/fang2hou/blink-copilot)
- **Blink.cmp**: [saghen/blink.cmp](https://github.com/saghen/blink.cmp)
- **GitHub Copilot**: [Official Documentation](https://docs.github.com/en/copilot)
- **Issues**: Report integration issues to respective repositories