-- ============================================================================
-- GITSIGNS.NVIM CONFIGURATION
-- ============================================================================
-- Git signs and inline git integration

require("gitsigns").setup({
    signs = {
        add          = { text = '┃' },
        change       = { text = '┃' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
    },
    signs_staged = {
        add          = { text = '┃' },
        change       = { text = '┃' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
    },
    signs_staged_enable = true,
    signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
    numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
    linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
    word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
    watch_gitdir = {
        follow_files = true
    },
    auto_attach = true,
    attach_to_untracked = false,
    current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
    current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
        virt_text_priority = 100,
    },
    current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
    sign_priority = 6,
    update_debounce = 100,
    status_formatter = nil, -- Use default
    max_file_length = 40000, -- Disable if file is longer than this (in lines)
    preview_config = {
        -- Options passed to nvim_open_win
        border = 'single',
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1
    },
})

-- ============================================================================
-- GITSIGNS KEYMAPS
-- ============================================================================

local function map(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
end

-- Navigation
map('n', ']c', function()
    if vim.wo.diff then
        vim.cmd.normal({']c', bang = true})
    else
        require('gitsigns').nav_hunk('next')
    end
end, { desc = "Next Hunk" })

map('n', '[c', function()
    if vim.wo.diff then
        vim.cmd.normal({'[c', bang = true})
    else
        require('gitsigns').nav_hunk('prev')
    end
end, { desc = "Prev Hunk" })

-- Actions
map('n', '<leader>hs', require('gitsigns').stage_hunk, { desc = "Stage Hunk" })
map('n', '<leader>hr', require('gitsigns').reset_hunk, { desc = "Reset Hunk" })
map('v', '<leader>hs', function() require('gitsigns').stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = "Stage Hunk" })
map('v', '<leader>hr', function() require('gitsigns').reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = "Reset Hunk" })
map('n', '<leader>hS', require('gitsigns').stage_buffer, { desc = "Stage Buffer" })
map('n', '<leader>hu', require('gitsigns').undo_stage_hunk, { desc = "Undo Stage Hunk" })
map('n', '<leader>hR', require('gitsigns').reset_buffer, { desc = "Reset Buffer" })
map('n', '<leader>hp', require('gitsigns').preview_hunk, { desc = "Preview Hunk" })
map('n', '<leader>hb', function() require('gitsigns').blame_line{full=true} end, { desc = "Blame Line" })
map('n', '<leader>hd', require('gitsigns').diffthis, { desc = "Diff This" })
map('n', '<leader>hD', function() require('gitsigns').diffthis('~') end, { desc = "Diff This ~" })

-- Toggles
map('n', '<leader>tb', require('gitsigns').toggle_current_line_blame, { desc = "Toggle Git Blame Line" })
map('n', '<leader>td', require('gitsigns').toggle_deleted, { desc = "Toggle Git Deleted" })

-- Text object
map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = "GitSigns Select Hunk" })

-- ============================================================================
-- GITSIGNS AUTOCOMMANDS
-- ============================================================================

-- Setup buffer-local keymaps when attaching to a buffer
vim.api.nvim_create_autocmd("User", {
    pattern = "GitSignsAttach",
    callback = function(args)
        local bufnr = args.buf
        local gs = package.loaded.gitsigns
        
        local function map_buf(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
        end
        
        -- Additional buffer-local mappings
        map_buf('n', '<leader>ghs', gs.stage_hunk, { desc = "Stage Hunk" })
        map_buf('n', '<leader>ghr', gs.reset_hunk, { desc = "Reset Hunk" })
        map_buf('v', '<leader>ghs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = "Stage Hunk" })
        map_buf('v', '<leader>ghr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = "Reset Hunk" })
        map_buf('n', '<leader>ghS', gs.stage_buffer, { desc = "Stage Buffer" })
        map_buf('n', '<leader>ghu', gs.undo_stage_hunk, { desc = "Undo Stage Hunk" })
        map_buf('n', '<leader>ghR', gs.reset_buffer, { desc = "Reset Buffer" })
        map_buf('n', '<leader>ghp', gs.preview_hunk, { desc = "Preview Hunk" })
        map_buf('n', '<leader>ghb', function() gs.blame_line{full=true} end, { desc = "Blame Line" })
        map_buf('n', '<leader>ghd', gs.diffthis, { desc = "Diff This" })
        map_buf('n', '<leader>ghD', function() gs.diffthis('~') end, { desc = "Diff This ~" })
    end,
})

-- ============================================================================
-- INTEGRATION WITH EXISTING WORKFLOW
-- ============================================================================

-- Ensure compatibility with Fugitive
vim.api.nvim_create_autocmd("User", {
    pattern = "FugitiveChanged",
    callback = function()
        -- Refresh gitsigns when fugitive makes changes
        require('gitsigns').refresh()
    end,
})

-- Integration with trouble.nvim for git diagnostics
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        -- Add git hunks to trouble if available
        local ok, trouble = pcall(require, "trouble")
        if ok then
            -- Custom trouble source for git hunks
            local function git_hunks_source()
                local gs = require('gitsigns')
                local hunks = gs.get_hunks() or {}
                local items = {}
                
                for _, hunk in ipairs(hunks) do
                    table.insert(items, {
                        filename = vim.api.nvim_buf_get_name(0),
                        lnum = hunk.added and hunk.added.start or hunk.removed.start,
                        col = 1,
                        text = string.format("%s: %d lines", hunk.type, hunk.added and hunk.added.count or hunk.removed.count),
                        type = hunk.type == "add" and "info" or hunk.type == "delete" and "error" or "warning"
                    })
                end
                
                return items
            end
            
            -- Add keymap to show git hunks in trouble
            map('n', '<leader>xh', function()
                trouble.open({
                    mode = "custom",
                    source = git_hunks_source,
                    title = "Git Hunks"
                })
            end, { desc = "Git Hunks (Trouble)" })
        end
    end,
})

-- ============================================================================
-- STATUSLINE INTEGRATION
-- ============================================================================

-- Function to get git status for statusline
_G.gitsigns_status = function()
    local gs = package.loaded.gitsigns
    if not gs then return "" end
    
    local status = vim.b.gitsigns_status_dict
    if not status then return "" end
    
    local parts = {}
    if status.added and status.added > 0 then
        table.insert(parts, "+" .. status.added)
    end
    if status.changed and status.changed > 0 then
        table.insert(parts, "~" .. status.changed)
    end
    if status.removed and status.removed > 0 then
        table.insert(parts, "-" .. status.removed)
    end
    
    if #parts > 0 then
        return " [" .. table.concat(parts, " ") .. "]"
    end
    return ""
end