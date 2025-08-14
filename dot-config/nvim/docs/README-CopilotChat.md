# CopilotChat.nvim Integration Guide

This document provides a complete guide for the CopilotChat.nvim integration in your Neovim configuration.

## Overview

CopilotChat.nvim adds conversational AI capabilities to your existing GitHub Copilot setup, allowing you to have interactive discussions about your code, get explanations, generate documentation, and much more.

## Installation

The plugin has been integrated into your configuration with the following changes:

### 1. Plugin Declaration
**File:** `lua/plugins/init.lua` (line 111)
```lua
{ src = "https://github.com/CopilotC-Nvim/CopilotChat.nvim", checkout = "canary" },
```

### 2. Configuration File
**File:** `lua/plugins/ai/copilot-chat.lua`
- Complete setup with optimized defaults
- Comprehensive keymap configuration
- Which-key integration
- Auto-commands for better UX

### 3. Plugin Loading
**File:** `lua/plugins/init.lua` (line 187)
```lua
require("plugins.ai.copilot-chat")
```

## Key Features

### Chat Interface
- **Vertical layout** by default (50% screen width)
- **Rounded borders** for better visual appeal
- **Auto-follow cursor** for seamless interaction
- **History persistence** in `~/.local/share/nvim/copilotchat_history`

### Pre-configured Prompts
- **Explain**: Get detailed explanations of code
- **Review**: Code review and suggestions
- **Fix**: Bug fixes and improvements
- **Optimize**: Performance and readability improvements
- **Docs**: Generate documentation
- **Tests**: Create unit tests
- **Commit**: Generate commit messages
- **FixDiagnostic**: Help with LSP diagnostics

## Keymaps Reference

### Main Chat Operations
| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>co` | Normal | Open Copilot Chat |
| `<leader>ct` | Normal | Toggle Copilot Chat |
| `<leader>cr` | Normal | Reset Copilot Chat |
| `<leader>cs` | Normal | Save Copilot Chat |
| `<leader>cl` | Normal | Load Copilot Chat |

### Quick Actions (Normal Mode)
| Keymap | Description |
|--------|-------------|
| `<leader>ce` | Explain code under cursor/buffer |
| `<leader>cf` | Fix code issues |
| `<leader>cd` | Generate documentation |
| `<leader>cu` | Generate unit tests |
| `<leader>cp` | Optimize code |

### Visual Mode Actions
| Keymap | Description |
|--------|-------------|
| `<leader>ce` | Explain selected code |
| `<leader>cv` | Review selected code |
| `<leader>cf` | Fix selected code |
| `<leader>cd` | Document selected code |
| `<leader>cu` | Generate tests for selection |
| `<leader>cp` | Optimize selected code |

### Git Integration
| Keymap | Description |
|--------|-------------|
| `<leader>cgc` | Generate commit message |
| `<leader>cgs` | Generate commit message for staged files |

### Diagnostic Assistance
| Keymap | Description |
|--------|-------------|
| `<leader>cfd` | Fix diagnostic issues |

### Interactive Chat
| Keymap | Description |
|--------|-------------|
| `<leader>cq` | Quick chat with custom prompt |
| `<leader>cb` | Chat about current buffer |

## Chat Window Controls

### Inside Chat Window
| Keymap | Mode | Description |
|--------|------|-------------|
| `<Tab>` | Insert | Auto-complete prompts |
| `<CR>` | Normal | Submit prompt |
| `<C-s>` | Insert | Submit prompt |
| `q` | Normal | Close chat |
| `<C-c>` | Insert | Close chat |
| `<C-r>` | Both | Reset chat |
| `<C-y>` | Both | Accept diff |
| `gy` | Normal | Yank diff |
| `gd` | Normal | Show diff |
| `gp` | Normal | Show system prompt |
| `gs` | Normal | Show user selection |

## Usage Examples

### 1. Explain Code
```
1. Place cursor on function/class
2. Press <leader>ce
3. Get detailed explanation in chat window
```

### 2. Fix Code Issues
```
1. Select problematic code in visual mode
2. Press <leader>cf
3. Review suggested fixes
4. Apply with <C-y> if satisfied
```

### 3. Generate Documentation
```
1. Select function/class
2. Press <leader>cd
3. Get properly formatted documentation
4. Copy and paste where needed
```

### 4. Code Review
```
1. Select code block in visual mode
2. Press <leader>cv
3. Get comprehensive code review
4. Address suggestions as needed
```

### 5. Generate Commit Messages
```
1. Stage your changes with git
2. Press <leader>cgc (all changes) or <leader>cgs (staged)
3. Get conventional commit message
4. Copy to git commit
```

### 6. Interactive Chat
```
1. Press <leader>cq for quick question
2. Type your question
3. Get contextual response based on current buffer
```

## Configuration Customization

### Window Layout Options
Edit `lua/plugins/ai/copilot-chat.lua` line 21:
```lua
layout = 'vertical', -- Options: 'vertical', 'horizontal', 'float', 'replace'
```

### Model Selection
Edit `lua/plugins/ai/copilot-chat.lua` line 18:
```lua
model = 'gpt-4', -- Options: 'gpt-3.5-turbo', 'gpt-4'
```

### Temperature Control
Edit `lua/plugins/ai/copilot-chat.lua` line 21:
```lua
temperature = 0.1, -- Range: 0.0 (focused) to 2.0 (creative)
```

## Troubleshooting

### Common Issues

1. **Chat not opening**
   - Ensure GitHub Copilot is authenticated: `:Copilot setup`
   - Check if plugin loaded: `:CopilotChat`

2. **No responses**
   - Verify internet connection
   - Check Copilot subscription status
   - Try resetting chat: `<leader>cr`

3. **Keymap conflicts**
   - Check existing keymaps: `:map <leader>c`
   - Modify keymaps in `lua/plugins/ai/copilot-chat.lua`

### Debug Mode
Enable debug mode in `lua/plugins/ai/copilot-chat.lua`:
```lua
debug = true,
```

## Integration with Existing Tools

### Which-Key
- All keymaps are automatically registered with descriptions
- Press `<leader>c` to see all available options

### Telescope
- Chat history can be searched (if telescope integration enabled)
- File selection works with telescope pickers

### LSP Integration
- Diagnostic fixes work with your existing LSP setup
- Context-aware suggestions based on LSP information

## Best Practices

1. **Use specific selections** - Select relevant code for better context
2. **Clear chat regularly** - Use `<leader>cr` to start fresh conversations
3. **Save important sessions** - Use `<leader>cs` for valuable discussions
4. **Combine with git workflow** - Use commit message generation
5. **Review suggestions carefully** - Always validate AI-generated code

## Advanced Usage

### Custom Prompts
Add custom prompts in `lua/plugins/ai/copilot-chat.lua`:
```lua
prompts = {
    YourCustomPrompt = {
        prompt = 'Your custom prompt text here',
        selection = require("CopilotChat.select").buffer,
    },
}
```

### Custom Keymaps
Add additional keymaps:
```lua
keymap('n', '<leader>cX', '<cmd>CopilotChatYourCustomPrompt<CR>', { desc = 'Your description' })
```

## Support

- **Plugin Documentation**: [CopilotChat.nvim GitHub](https://github.com/CopilotC-Nvim/CopilotChat.nvim)
- **GitHub Copilot**: [Official Documentation](https://docs.github.com/en/copilot)
- **Issues**: Check plugin repository for known issues and solutions