-- ============================================================================
-- BASIC KEYMAPS
-- ============================================================================
-- Basic key mappings that don't depend on plugins
-- Plugin-specific keymaps are defined in their respective plugin files

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ============================================================================
-- BASIC FILE OPERATIONS
-- ============================================================================

-- File operations
keymap('n', '<leader>w', ':write<CR>', { desc = 'Save file' })
keymap('n', '<leader>q', ':quit<CR>', { desc = 'Quit' })
keymap('n', '<leader>Q', ':qa<CR>', { desc = 'Quit all' })
keymap('n', '<leader>o', ':update<CR> :source<CR>', { desc = 'Save and source' })

-- ============================================================================
-- CLIPBOARD OPERATIONS
-- ============================================================================

-- Enhanced clipboard operations
keymap({ 'n', 'v', 'x' }, '<leader>y', '"+y', { desc = 'Yank to system clipboard' })
keymap({ 'n', 'v', 'x' }, '<leader>d', '"+d', { desc = 'Delete to system clipboard' })
keymap('n', '<leader>Y', '"+Y', { desc = 'Yank line to system clipboard' })

-- Paste without overwriting register in visual mode
keymap('x', '<leader>p', [["_dP]], { desc = 'Paste without overwriting register' })

-- ============================================================================
-- WINDOW MANAGEMENT
-- ============================================================================

-- Window navigation
keymap('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
keymap('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom window' })
keymap('n', '<C-k>', '<C-w>k', { desc = 'Move to top window' })
keymap('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- Window splits
keymap('n', '<leader>|', '<C-w>v', { desc = 'Vertical split' })
keymap('n', '<leader>-', '<C-w>s', { desc = 'Horizontal split' })

-- Window resizing
keymap('n', '<leader>=', '<C-w>=', { desc = 'Balance windows' })
keymap('n', '<leader>+', '<C-w>+', { desc = 'Increase height' })
keymap('n', '<leader>_', '<C-w>-', { desc = 'Decrease height' })
keymap('n', '<leader>>', '<C-w>>', { desc = 'Increase width' })
keymap('n', '<leader><', '<C-w><', { desc = 'Decrease width' })

-- ============================================================================
-- BUFFER MANAGEMENT
-- ============================================================================

-- Buffer navigation
keymap('n', '<S-h>', ':bprevious<CR>', { desc = 'Previous buffer' })
keymap('n', '<S-l>', ':bnext<CR>', { desc = 'Next buffer' })
keymap('n', '<leader>bd', ':bdelete<CR>', { desc = 'Delete buffer' })
keymap('n', '<leader>bD', ':bdelete!<CR>', { desc = 'Force delete buffer' })

-- ============================================================================
-- MOVEMENT ENHANCEMENTS
-- ============================================================================

-- Better line joining
keymap('n', 'J', 'mzJ`z', { desc = 'Join lines and restore cursor' })

-- Center screen on navigation
keymap('n', '<C-d>', '<C-d>zz', { desc = 'Half page down and center' })
keymap('n', '<C-u>', '<C-u>zz', { desc = 'Half page up and center' })
keymap('n', 'n', 'nzzzv', { desc = 'Next search result and center' })
keymap('n', 'N', 'Nzzzv', { desc = 'Previous search result and center' })

-- ============================================================================
-- TEXT MANIPULATION
-- ============================================================================

-- Move lines up and down in visual mode
keymap('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
keymap('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- Better indenting
keymap('v', '<', '<gv', { desc = 'Indent left and reselect' })
keymap('v', '>', '>gv', { desc = 'Indent right and reselect' })

-- ============================================================================
-- SEARCH AND REPLACE
-- ============================================================================

-- Clear search highlighting
keymap('n', '<Esc>', ':nohlsearch<CR>', opts)

-- Search and replace word under cursor
keymap('n', '<leader>s', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], 
    { desc = 'Search and replace word under cursor' })

-- ============================================================================
-- UTILITY MAPPINGS
-- ============================================================================

-- Disable Q (ex mode)
keymap('n', 'Q', '<nop>')

-- Make file executable
keymap('n', '<leader>x', '<cmd>!chmod +x %<CR>', { silent = true, desc = 'Make file executable' })

-- Source current file
keymap('n', '<leader><leader>', function()
    vim.cmd('source %')
    vim.notify('File sourced!', vim.log.levels.INFO)
end, { desc = 'Source current file' })

-- ============================================================================
-- ESSENTIAL MISSING KEYMAPS (from recommendations)
-- ============================================================================

-- File explorer (will be overridden by oil.nvim if available)
keymap('n', '<leader>e', function()
    -- Try oil.nvim first, fallback to netrw
    local oil_ok, oil = pcall(require, "oil")
    if oil_ok then
        oil.open_float()
    else
        vim.cmd('Explore')
    end
end, { desc = 'Open file explorer' })

-- Terminal toggle (will be enhanced by snacks.nvim if available)
keymap('n', '<leader>tt', function()
    -- Try snacks terminal first, fallback to basic terminal
    local snacks_ok, snacks = pcall(require, "snacks")
    if snacks_ok and snacks.terminal then
        snacks.terminal()
    else
        vim.cmd('terminal')
    end
end, { desc = 'Toggle terminal' })

-- Search and replace in project (will be enhanced by spectre if available)
keymap('n', '<leader>ss', function()
    -- Try spectre first, fallback to basic search/replace
    local spectre_ok, spectre = pcall(require, "spectre")
    if spectre_ok then
        spectre.toggle()
    else
        -- Fallback to basic search and replace
        local word = vim.fn.expand('<cword>')
        vim.ui.input({ prompt = 'Search for: ', default = word }, function(search)
            if search then
                vim.ui.input({ prompt = 'Replace with: ' }, function(replace)
                    if replace then
                        vim.cmd(string.format('%%s/%s/%s/gc', search, replace))
                    end
                end)
            end
        end)
    end
end, { desc = 'Search and replace in project' })

-- ============================================================================
-- QUICKFIX AND LOCATION LIST
-- ============================================================================

-- Quickfix navigation
keymap('n', '<C-k>', '<cmd>cnext<CR>zz', { desc = 'Next quickfix item' })
keymap('n', '<C-j>', '<cmd>cprev<CR>zz', { desc = 'Previous quickfix item' })

-- Location list navigation
keymap('n', '<leader>k', '<cmd>lnext<CR>zz', { desc = 'Next location item' })
keymap('n', '<leader>j', '<cmd>lprev<CR>zz', { desc = 'Previous location item' })

-- ============================================================================
-- INSERT MODE MAPPINGS
-- ============================================================================

-- Exit insert mode with jk
keymap('i', 'jk', '<Esc>', { desc = 'Exit insert mode' })

-- Better escape
keymap('i', '<C-c>', '<Esc>', { desc = 'Exit insert mode' })

-- ============================================================================
-- COMMAND MODE MAPPINGS
-- ============================================================================

-- Command mode navigation
keymap('c', '<C-h>', '<Left>', { desc = 'Move left in command mode' })
keymap('c', '<C-l>', '<Right>', { desc = 'Move right in command mode' })
keymap('c', '<C-a>', '<Home>', { desc = 'Move to beginning of command' })
keymap('c', '<C-e>', '<End>', { desc = 'Move to end of command' })

-- ============================================================================
-- TERMINAL MAPPINGS
-- ============================================================================

-- Terminal mode escape
keymap('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
keymap('t', '<C-h>', '<C-\\><C-n><C-w>h', { desc = 'Move to left window from terminal' })
keymap('t', '<C-j>', '<C-\\><C-n><C-w>j', { desc = 'Move to bottom window from terminal' })
keymap('t', '<C-k>', '<C-\\><C-n><C-w>k', { desc = 'Move to top window from terminal' })
keymap('t', '<C-l>', '<C-\\><C-n><C-w>l', { desc = 'Move to right window from terminal' })
