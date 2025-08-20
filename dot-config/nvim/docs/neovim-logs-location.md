# Neovim Logs Location Guide

## Standard Log Locations

### On macOS (your system)
- **Main log file**: `~/.local/share/nvim/log` or `$XDG_DATA_HOME/nvim/log`
- **Cache directory**: `~/.cache/nvim/` or `$XDG_CACHE_HOME/nvim/`
- **LSP logs**: `~/.local/share/nvim/lsp.log`
- **Plugin logs**: Often in `~/.local/share/nvim/`

### Standard Paths
```bash
# View main log
tail -f ~/.local/share/nvim/log

# LSP server logs
ls ~/.local/share/nvim/lsp.log

# Or using Neovim's stdpath function
:echo stdpath('log')
:echo stdpath('data')
:echo stdpath('cache')
```

## Plugin-Specific Logs

### Mason (LSP installer)
- Location: `~/.local/share/nvim/mason/`
- Mason logs: `~/.local/share/nvim/mason/mason.log`

### DAP (Debugger)
- Location: Usually in `~/.local/share/nvim/`
- File: `dap.log` or similar

### Your Custom Logs
Based on your config structure, check:
- `~/.config/nvim/reports/` (you have checkhealth outputs here)
- Any custom logging you've set up in your Lua configs

## Commands to Check Logs

### In Neovim
```vim
:messages          " Show recent messages
:checkhealth       " System diagnostics
:LspInfo          " LSP server information
:Mason            " Mason installer interface
```

### In Terminal
```bash
# Find all nvim-related logs
find ~ -name "*nvim*" -type f -name "*.log" 2>/dev/null

# Monitor logs in real-time  
tail -f ~/.local/share/nvim/log

# Check for errors in logs
grep -i "error\|warn\|fail" ~/.local/share/nvim/log
```

## Your Configuration Structure
Your nvim config appears to have its own logging in:
- `reports/checkhealth_output*.txt` - Health check reports
- Potentially logs from your analytics and performance monitoring setup

## Quick Debug Script
```bash
#!/bin/bash
echo "=== Neovim Log Locations ==="
echo "Data dir: $(nvim --headless -c 'echo stdpath("data")' -c 'quit' 2>/dev/null)"
echo "Log dir: $(nvim --headless -c 'echo stdpath("log")' -c 'quit' 2>/dev/null)"  
echo "Cache dir: $(nvim --headless -c 'echo stdpath("cache")' -c 'quit' 2>/dev/null)"
echo ""
echo "=== Found Log Files ==="
find ~/.local/share/nvim/ -name "*.log" 2>/dev/null || echo "No .log files found"
find ~/.cache/nvim/ -name "*.log" 2>/dev/null || echo "No cache logs found"
```
