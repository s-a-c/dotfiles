-- ============================================================================
-- OPTIMIZED MINI.NVIM CONFIGURATION
-- ============================================================================
-- Focused on modules that complement snacks.nvim functionality
-- Removed redundant modules (mini.files replaced by snacks.explorer)

-- ============================================================================
-- MINI.JUMP - Enhanced f/F/t/T motions (part of flash.nvim replacement)
-- ============================================================================
require('mini.jump').setup({
    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
        forward = 'f',
        backward = 'F',
        forward_till = 't',
        backward_till = 'T',
        repeat_jump = ';',
    },

    -- Delay values (in ms) for different functionalities. Set any of them to
    -- a very big number (like 10^7) to virtually disable.
    delay = {
        -- Delay between jump and highlighting all possible jumps
        highlight = 250,
        -- Delay between jump and automatic stop if idle (no jump is done)
        idle_stop = 10000000,
    },
})

-- ============================================================================
-- MINI.JUMP2D - 2D jumping (completes flash.nvim replacement)
-- ============================================================================
require('mini.jump2d').setup({
    -- Function producing jump spots (byte indexed) for a particular line.
    -- For more information see |MiniJump2d.builtin_opts|.
    spotter = nil,

    -- Characters used for labels of jump spots (in supplied order)
    labels = 'abcdefghijklmnopqrstuvwxyz',

    -- Which lines are used for computing spots
    allowed_lines = {
        blank = true,
        cursor_before = true,
        cursor_at = true,
        cursor_after = true,
        fold = true,
    },

    -- Which windows are used for computing spots
    allowed_windows = {
        current = true,
        not_current = true,
    },

    -- Functions to be executed at certain events
    hooks = {
        before_start = nil,
        after_jump = nil,
    },

    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
        start_jumping = '<CR>',
    },

    -- Whether to disable showing non-jump spots
    silent = false,
})

-- ============================================================================
-- MINI.INDENTSCOPE - Indentation visualization (replaces nvim-biscuits)
-- ============================================================================
require('mini.indentscope').setup({
    -- Draw options
    draw = {
        -- Delay (in ms) between event and start of drawing scope indicator
        delay = 100,

        -- Animation rule for scope's first drawing. A function which, given
        -- next and total step numbers, returns wait time (in ms). See
        -- |MiniIndentscope.gen_animation| for builtin options. To disable
        -- animation, use `require('mini.indentscope').gen_animation.none()`.
        animation = require('mini.indentscope').gen_animation.none(),

        -- Symbol priority. Increase to display on top of more symbols.
        priority = 2,
    },

    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
        -- Textobjects
        object_scope = 'ii',
        object_scope_with_border = 'ai',

        -- Motions (jump to respective border line; if not present - body line)
        goto_top = '[i',
        goto_bottom = ']i',
    },

    -- Options which control scope computation
    options = {
        -- Type of scope's border: which line(s) with smaller indent to
        -- categorize as border. Can be one of: 'both', 'top', 'bottom', 'none'.
        border = 'both',

        -- Whether to use cursor column when computing reference indent.
        -- Useful to see incremental scopes with horizontal cursor movements.
        indent_at_cursor = true,

        -- Whether to first check input line to be a border of adjacent scope.
        -- Use it if you want to place cursor on function header to get scope of
        -- its body.
        try_as_border = false,
    },

    -- Which character to use for drawing scope indicator
    symbol = '╎',
})

-- ============================================================================
-- MINI.AI - Enhanced text objects
-- ============================================================================
require('mini.ai').setup({
    -- Table with textobject id as fields, textobject specification as values.
    -- Also use this to disable builtin textobjects. See |MiniAi.config|.
    custom_textobjects = nil,

    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
        -- Main textobject prefixes
        around = 'a',
        inside = 'i',

        -- Next/last variants
        around_next = 'an',
        inside_next = 'in',
        around_last = 'al',
        inside_last = 'il',

        -- Move cursor to corresponding edge of `a` textobject
        goto_left = 'g[',
        goto_right = 'g]',
    },

    -- Number of lines within which textobject is searched
    n_lines = 50,

    -- How to search for object (first inside current line, then inside
    -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
    -- 'cover_or_nearest', 'next', 'prev', 'nearest'.
    search_method = 'cover_or_next',

    -- Whether to disable showing non-error feedback
    silent = false,
})

-- ============================================================================
-- MINI.SURROUND - Surround operations
-- ============================================================================
require('mini.surround').setup({
    -- Add custom surroundings to be used on top of builtin ones. For more
    -- information with examples, see `:h MiniSurround.config`.
    custom_surroundings = nil,

    -- Duration (in ms) of highlight when calling `MiniSurround.highlight()`
    highlight_duration = 500,

    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
        add = 'sa', -- Add surrounding in Normal and Visual modes
        delete = 'sd', -- Delete surrounding
        find = 'sf', -- Find surrounding (to the right)
        find_left = 'sF', -- Find surrounding (to the left)
        highlight = 'sh', -- Highlight surrounding
        replace = 'sr', -- Replace surrounding
        update_n_lines = 'sn', -- Update `n_lines`

        suffix_last = 'l', -- Suffix to search with "prev" method
        suffix_next = 'n', -- Suffix to search with "next" method
    },

    -- Number of lines within which surrounding is searched
    n_lines = 20,

    -- Whether to respect selection type:
    -- - Place surroundings on separate lines in linewise mode.
    -- - Place surroundings on each line in blockwise mode.
    respect_selection_type = false,

    -- How to search for surrounding (first inside current line, then inside
    -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
    -- 'cover_or_nearest', 'next', 'prev', 'nearest'. For more details,
    -- see `:h MiniSurround.config`.
    search_method = 'cover',

    -- Whether to disable showing non-error feedback
    silent = false,
})

-- ============================================================================
-- MINI.PAIRS - Auto-pairs functionality
-- ============================================================================
require('mini.pairs').setup({
    -- In which modes mappings from this `config` should be created
    modes = { insert = true, command = false, terminal = false },

    -- Global mappings. Each right hand side should be a pair information, a
    -- table with at least these fields (see more in |MiniPairs.map|):
    -- - <action> - one of 'open', 'close', 'closeopen'.
    -- - <pair> - two character string for pair to be used.
    -- By default pair is not inserted after `\`, quotes are not recognized by
    -- `<CR>`, `'` does not insert pair after a letter.
    -- Only parts of tables can be tweaked (others will use these defaults).
    mappings = {
        ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\].' },
        ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\].' },
        ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].' },

        [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
        [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
        ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },

        ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^\\].', register = { cr = false } },
        ["'"] = { action = 'closeopen', pair = "''", neigh_pattern = '[^%a\\].', register = { cr = false } },
        ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\].', register = { cr = false } },
    },
})

-- ============================================================================
-- OPTIMIZED KEYMAPS FOR MINI.NVIM MODULES
-- ============================================================================

-- Note: File explorer keymaps moved to snacks.nvim (snacks.explorer)
-- This provides better integration and consistency

-- Mini.jump2d keymaps (enhanced navigation - complements snacks.nvim)
vim.keymap.set({ "n", "x", "o" }, "s", function()
    require('mini.jump2d').start(require('mini.jump2d').builtin_opts.single_character)
end, { desc = "Jump to character" })

vim.keymap.set({ "n", "x", "o" }, "S", function()
    require('mini.jump2d').start(require('mini.jump2d').builtin_opts.word_start)
end, { desc = "Jump to word start" })

-- Enhanced jump keymaps for better workflow
vim.keymap.set("n", "<leader>js", function()
    require('mini.jump2d').start(require('mini.jump2d').builtin_opts.single_character)
end, { desc = "Mini jump to character" })

vim.keymap.set("n", "<leader>jw", function()
    require('mini.jump2d').start(require('mini.jump2d').builtin_opts.word_start)
end, { desc = "Mini jump to word start" })

vim.keymap.set("n", "<leader>jl", function()
    require('mini.jump2d').start(require('mini.jump2d').builtin_opts.line_start)
end, { desc = "Mini jump to line start" })

-- Mini.surround enhanced keymaps
vim.keymap.set("n", "<leader>sa", "sa", { desc = "Add surrounding", remap = true })
vim.keymap.set("n", "<leader>sd", "sd", { desc = "Delete surrounding", remap = true })
vim.keymap.set("n", "<leader>sr", "sr", { desc = "Replace surrounding", remap = true })

-- Mini.ai enhanced text object keymaps
vim.keymap.set({ "x", "o" }, "an", function()
    return require('mini.ai').textobject('n')
end, { desc = "Next textobject" })

vim.keymap.set({ "x", "o" }, "al", function()
    return require('mini.ai').textobject('l')
end, { desc = "Last textobject" })