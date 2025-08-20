# Neovim Training and Habit Building Plugins Guide

This document provides a comprehensive guide to the training and habit-building plugins integrated into your Neovim configuration.

## 🎯 Overview

Three powerful plugins work together to help you develop better Vim habits and improve your editing efficiency:

1. **hardtime.nvim** - Breaks bad habits by restricting repetitive key usage
2. **precognition.nvim** - Shows movement hints to teach efficient navigation  
3. **vim-be-good** - Provides interactive games for practicing Vim movements

## 🔥 hardtime.nvim

### Purpose
Prevents bad habits like excessive use of hjkl keys and arrow keys, encouraging more efficient movement patterns.

### Key Features
- Limits consecutive repetitive key presses
- Provides helpful hints for better movements
- Progressive difficulty that adapts over time
- Smart detection of when to disable (macros, special buffers)

### Keymaps
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ht` | Toggle Hardtime | Enable/disable hardtime restrictions |
| `<leader>hs` | Show Status | Display current hardtime status and session count |
| `<leader>hr` | Reset Sessions | Reset session counter (for testing different difficulty levels) |

### Configuration Highlights
- **Progressive Difficulty**: Starts lenient and becomes stricter over time
- **Smart Exclusions**: Disabled in special buffers (telescope, oil, etc.)
- **Integration Aware**: Automatically disabled during macro recording
- **Customizable Restrictions**: Different limits for different key patterns

### Usage Tips
1. Start with the plugin enabled and let it guide you
2. Pay attention to the suggestions for better movements
3. Use the status command to track your progress
4. Reset sessions if you want to experience the learning curve again

## 💡 precognition.nvim

### Purpose
Shows visual hints for available Vim motions, helping you learn efficient movement patterns without looking them up.

### Key Features
- Real-time movement hints as you type
- Contextual suggestions based on cursor position
- Smart activation based on movement patterns
- Integration with training sessions

### Keymaps
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>cp` | Toggle Precognition | Enable/disable hints |
| `<leader>cs` | Show Hints | Enable hints temporarily |
| `<leader>ch` | Hide Hints | Disable hints |
| `<leader>cl` | Learning Session | Enable hints for 10-minute learning session |
| `<leader>clt` | Intensive Training | Enable both precognition and hardtime |

### Smart Features
- **Movement Tracking**: Detects inefficient hjkl usage and suggests enabling hints
- **Auto-activation**: Enables during vim-be-good training sessions
- **Contextual Hints**: Shows relevant motions based on current text
- **Progressive Learning**: Gradually reduces dependency on hints

### Usage Tips
1. Use `<leader>cl` for focused learning sessions
2. Pay attention to the automatic suggestions
3. Practice without hints after learning sessions
4. Use `<leader>clt` for intensive training combining multiple tools

## 🎮 vim-be-good

### Purpose
Interactive games that make practicing Vim movements fun and engaging.

### Available Games
- **hjkl** - Basic directional movement practice
- **relative** - Relative line number jumping
- **word** - Word navigation (w, b, e movements)
- **ci** - Change inside practice
- **find** - Character finding (f, F, t, T)
- **substitute** - Search and replace practice
- **delete** - Deletion command practice
- **whackamole** - Fast-paced movement game

### Keymaps
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>vbg` | Launch Game Menu | Open vim-be-good game selection |
| `<leader>vbt` | Training Menu | Interactive game selector with descriptions |
| `<leader>vbp` | Show Progress | Display training statistics |
| `<leader>vbr` | Relative Numbers | Quick launch relative number game |
| `<leader>vbw` | Word Navigation | Quick launch word movement game |
| `<leader>vbc` | Change Inside | Quick launch ci practice |
| `<leader>vbf` | Find Character | Quick launch find character game |

### Progress Tracking
- **Session Logging**: Tracks daily training sessions
- **Progress Reports**: Weekly statistics with `<leader>vbp`
- **Smart Reminders**: Gentle nudges if you haven't trained today
- **Integration**: Automatically enables precognition during games

### Usage Tips
1. Start with `<leader>vbt` for the interactive training menu
2. Begin with basic games (hjkl, relative) before advanced ones
3. Use `<leader>vbp` to track your improvement over time
4. Set aside 5-10 minutes daily for consistent practice

## 🔄 Plugin Integration

### Unified Learning Experience
The three plugins work together to provide a comprehensive learning experience:

1. **precognition.nvim** shows you what movements are available
2. **vim-be-good** lets you practice those movements in a fun way
3. **hardtime.nvim** enforces good habits in real editing

### Smart Coordination
- Precognition automatically enables during vim-be-good sessions
- Hardtime disables during games to avoid interference
- All plugins respect special buffer types and contexts
- Unified learning menu available with `<leader>vl`

### Learning Workflow
```
Start → Enable Precognition → Play Games → Practice Real Editing → Enable Hardtime → Master Efficient Movement
```

## 🛠 Customization

### Global Variables
Control plugin behavior with these variables in your config:

```lua
-- Disable specific plugins
vim.g.enable_learning_plugins = false  -- Disables all learning plugins

-- Precognition settings
vim.g.precognition_smart_activation = true  -- Enable smart movement tracking
vim.g.keep_precognition_after_training = true  -- Keep hints active after games

-- Hardtime settings
vim.g.hardtime_sessions = 0  -- Reset session counter
```

### Plugin-Specific Configuration
Each plugin file contains extensive configuration options that can be modified:
- `lua/plugins/editor/hardtime.lua` - Restriction patterns and difficulty
- `lua/plugins/editor/precognition.lua` - Hint styles and activation rules
- `lua/plugins/editor/vim-be-good.lua` - Game preferences and tracking

## 📈 Learning Path

### Week 1: Foundation
- Enable precognition with `<leader>cl` for daily editing
- Play basic games: hjkl, relative numbers
- Focus on understanding motion hints

### Week 2: Skill Building  
- Add word navigation and find character games
- Start using hardtime for gentle habit correction
- Practice without hints for short periods

### Week 3: Advanced Practice
- Try ci, substitute, and delete games
- Enable intensive training mode with `<leader>clt`
- Gradually reduce precognition dependence

### Week 4: Mastery
- Use hardtime as primary habit enforcer
- Occasional games for maintenance
- Focus on efficient real-world editing

## 🔍 Troubleshooting

### Common Issues
1. **Plugins interfering with each other**: Use the unified learning menu `<leader>vl`
2. **Hints not showing**: Check filetype exclusions in precognition config
3. **Hardtime too strict**: Use `<leader>hr` to reset and start over
4. **Games not launching**: Ensure vim-be-good is properly installed

### Performance Considerations
- All plugins load conditionally and defer heavy operations
- Smart activation prevents unnecessary resource usage
- Automatic disabling in inappropriate contexts

## 🎯 Tips for Success

1. **Consistency**: Practice a little each day rather than long sessions
2. **Patience**: Allow time to build muscle memory
3. **Progressive**: Start with hints, gradually reduce dependence
4. **Playful**: Use games to make learning enjoyable
5. **Mindful**: Pay attention to your movement patterns

---

*Remember: The goal isn't to use these plugins forever, but to internalize efficient Vim movement patterns. Start with maximum assistance and gradually reduce dependence as you improve.*
