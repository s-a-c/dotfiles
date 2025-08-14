-- ============================================================================
-- FLASH.NVIM CONFIGURATION
-- ============================================================================
-- Enhanced jump/search with labels for fast navigation

-- Ensure flash.nvim is available
local ok, flash = pcall(require, "flash")
if not ok then
    vim.notify("flash.nvim not found", vim.log.levels.WARN)
    return
end

-- ============================================================================
-- FLASH SETUP
-- ============================================================================

flash.setup({
    -- Labels for jump targets
    labels = "asdfghjklqwertyuiopzxcvbnm",
    
    -- Search configuration
    search = {
        -- Search/jump in all windows
        multi_window = true,
        -- Search direction
        forward = true,
        -- When `false`, find only matches in the given direction
        wrap = true,
        -- Search mode: exact, search, fuzzy, or custom function
        mode = "exact",
        -- Behave like `incsearch`
        incremental = false,
        -- Excluded filetypes and buftypes from flash
        exclude = {
            "notify",
            "cmp_menu",
            "noice",
            "flash_prompt",
        },
    },
    
    -- Jump configuration
    jump = {
        -- Save location in the jumplist
        jumplist = true,
        -- Jump position: "start", "end", or "range"
        pos = "start",
        -- Add pattern to search history
        history = false,
        -- Add pattern to search register
        register = false,
        -- Clear highlight after jump
        nohlsearch = false,
        -- Automatically jump when there is only one match
        autojump = false,
    },
    
    -- Label configuration
    label = {
        -- Allow uppercase labels
        uppercase = true,
        -- Exclude specific labels
        exclude = "",
        -- Add a label for the first match in the current window
        current = true,
        -- Show the label after the match
        after = true,
        -- Show the label before the match
        before = false,
        -- Position of the label extmark
        style = "overlay", -- "eol", "overlay", "right_align", "inline"
        -- Reuse labels that were already assigned to a position
        reuse = "lowercase", -- "lowercase", "all", "none"
        -- For the current window, label targets closer to the cursor first
        distance = true,
        -- Minimum pattern length to show labels
        min_pattern_length = 0,
        -- Enable rainbow colors to highlight labels
        rainbow = {
            enabled = false,
            shade = 5,
        },
    },
    
    -- Highlight configuration
    highlight = {
        -- Show a backdrop with hl FlashBackdrop
        backdrop = true,
        -- Highlight the search matches
        matches = true,
        -- Extmark priority
        priority = 5000,
        groups = {
            match = "FlashMatch",
            current = "FlashCurrent",
            backdrop = "FlashBackdrop",
            label = "FlashLabel",
        },
    },
    
    -- Action to perform when picking a label
    action = nil,
    
    -- Initial pattern to use when opening flash
    pattern = "",
    
    -- When `true`, flash will try to continue the last search
    continue = false,
    
    -- Configuration for different modes
    modes = {
        -- Options used when flash is activated through regular search with `/` or `?`
        search = {
            -- When `true`, flash will be activated during regular search by default
            enabled = true,
            highlight = { backdrop = false },
            jump = { history = true, register = true, nohlsearch = true },
        },
        
        -- Options used when flash is activated through `f`, `F`, `t`, `T`, `;` and `,` motions
        char = {
            enabled = true,
            -- Dynamic configuration for ftFT motions
            config = function(opts)
                -- Autohide flash when in operator-pending mode
                opts.autohide = opts.autohide or (vim.fn.mode(true):find("no") and vim.v.operator == "y")
                
                -- Disable jump labels when not enabled, when using a count,
                -- or when recording/executing registers
                opts.jump_labels = opts.jump_labels
                    and vim.v.count == 0
                    and vim.fn.reg_executing() == ""
                    and vim.fn.reg_recording() == ""
            end,
            -- Hide after jump when not using jump labels
            autohide = false,
            -- Show jump labels
            jump_labels = false,
            -- Set to `false` to use the current line only
            multi_line = true,
            -- When using jump labels, don't use these keys
            label = { exclude = "hjkliardc" },
            -- Available keymaps
            keys = { "f", "F", "t", "T", ";", "," },
            -- Character actions
            char_actions = function(motion)
                return {
                    [";"] = "next",
                    [","] = "prev",
                    -- Clever-f style
                    [motion:lower()] = "next",
                    [motion:upper()] = "prev",
                }
            end,
            search = { wrap = false },
            highlight = { backdrop = true },
            jump = { register = false },
        },
        
        -- Options used for treesitter selections
        treesitter = {
            labels = "abcdefghijklmnopqrstuvwxyz",
            jump = { pos = "range" },
            search = { incremental = false },
            label = { before = true, after = true, style = "inline" },
            highlight = {
                backdrop = false,
                matches = false,
            },
        },
        
        treesitter_search = {
            jump = { pos = "range" },
            search = { multi_window = true, wrap = true, incremental = false },
            remote_op = { restore = true },
            label = { before = true, after = true, style = "inline" },
        },
        
        -- Options used for remote flash
        remote = {
            remote_op = { restore = true, motion = true },
        },
    },
})

-- ============================================================================
-- FLASH KEYMAPS
-- ============================================================================

local keymap = vim.keymap.set

-- Main flash keymaps
keymap({ "n", "x", "o" }, "s", function()
    flash.jump()
end, { desc = "Flash" })

keymap({ "n", "x", "o" }, "S", function()
    flash.treesitter()
end, { desc = "Flash Treesitter" })

keymap("o", "r", function()
    flash.remote()
end, { desc = "Remote Flash" })

keymap({ "o", "x" }, "R", function()
    flash.treesitter_search()
end, { desc = "Treesitter Search" })

keymap("c", "<c-s>", function()
    flash.toggle()
end, { desc = "Toggle Flash Search" })

-- Additional useful flash keymaps
keymap("n", "<leader>j", function()
    flash.jump()
end, { desc = "Flash jump" })

keymap("n", "<leader>J", function()
    flash.treesitter()
end, { desc = "Flash treesitter" })

-- Flash integration with search
keymap("n", "<leader>/", function()
    flash.jump({
        search = { mode = "search", max_length = 0 },
        label = { after = { 0, 0 } },
        pattern = "^"
    })
end, { desc = "Flash search lines" })

-- ============================================================================
-- WHICH-KEY INTEGRATION
-- ============================================================================

local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
    wk.add({
        { "s", desc = "⚡ Flash" },
        { "S", desc = "⚡ Flash Treesitter" },
        { "<leader>j", desc = "⚡ Flash Jump" },
        { "<leader>J", desc = "⚡ Flash Treesitter" },
        { "<leader>/", desc = "⚡ Flash Search Lines" },
    })
end

vim.notify("flash.nvim configured successfully", vim.log.levels.INFO)