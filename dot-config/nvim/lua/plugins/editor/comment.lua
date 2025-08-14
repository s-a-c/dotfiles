-- ============================================================================
-- COMMENT.NVIM CONFIGURATION
-- ============================================================================
-- Smart and powerful comment plugin with treesitter integration

require('Comment').setup({
    -- Add a space b/w comment and the line
    padding = true,
    
    -- Whether the cursor should stay at its position
    sticky = true,
    
    -- Lines to be ignored while (un)comment
    ignore = '^$',
    
    -- LHS of toggle mappings in NORMAL mode
    toggler = {
        -- Line-comment toggle keymap
        line = 'gcc',
        -- Block-comment toggle keymap
        block = 'gbc',
    },
    
    -- LHS of operator-pending mappings in NORMAL and VISUAL mode
    opleader = {
        -- Line-comment keymap
        line = 'gc',
        -- Block-comment keymap
        block = 'gb',
    },
    
    -- LHS of extra mappings
    extra = {
        -- Add comment on the line above
        above = 'gcO',
        -- Add comment on the line below
        below = 'gco',
        -- Add comment at the end of line
        eol = 'gcA',
    },
    
    -- Enable keybindings
    -- NOTE: If given `false` then the plugin won't create any mappings
    mappings = {
        -- Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
        basic = true,
        -- Extra mapping; `gco`, `gcO`, `gcA`
        extra = true,
    },
    
    -- Function to call before (un)comment
    pre_hook = function(ctx)
        -- Only calculate commentstring for tsx filetypes
        if vim.bo.filetype == 'typescriptreact' or vim.bo.filetype == 'javascriptreact' then
            local U = require('Comment.utils')

            -- Determine whether to use linewise or blockwise commentstring
            local type = ctx.ctype == U.ctype.linewise and '__default' or '__multiline'

            -- Determine the location where to calculate commentstring from
            local location = nil
            if ctx.ctype == U.ctype.blockwise then
                location = require('ts_context_commentstring.utils').get_cursor_location()
            elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
                location = require('ts_context_commentstring.utils').get_visual_start_location()
            end

            return require('ts_context_commentstring.internal').calculate_commentstring({
                key = type,
                location = location,
            })
        end
    end,
    
    -- Function to call after (un)comment
    post_hook = nil,
})

-- ============================================================================
-- ADDITIONAL KEYMAPS
-- ============================================================================

-- Additional keymaps for enhanced commenting functionality
local function map(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
end

-- Comment/uncomment current line in insert mode
map('i', '<C-/>', '<Esc>gccA', { desc = 'Comment line (insert mode)' })
map('i', '<C-_>', '<Esc>gccA', { desc = 'Comment line (insert mode)' })

-- Visual mode mappings for better UX
map('x', '<leader>/', 'gc', { desc = 'Comment selection' })
map('x', '<C-/>', 'gc', { desc = 'Comment selection' })
map('x', '<C-_>', 'gc', { desc = 'Comment selection' })

-- Normal mode leader mappings
map('n', '<leader>/', 'gcc', { desc = 'Comment line' })
map('n', '<leader>c<space>', 'gcc', { desc = 'Comment line' })
map('n', '<leader>cb', 'gbc', { desc = 'Comment block' })

-- ============================================================================
-- TREESITTER INTEGRATION SETUP
-- ============================================================================

-- Ensure ts_context_commentstring is properly configured for Comment.nvim
vim.g.skip_ts_context_commentstring_module = true

-- Set up context-aware commenting for various filetypes
local ft_to_lang = {
    typescript = 'typescript',
    typescriptreact = 'tsx',
    javascript = 'javascript',
    javascriptreact = 'jsx',
    vue = 'vue',
    svelte = 'svelte',
    astro = 'astro',
    php = 'php',
    blade = 'php',
}

-- Configure commentstring for different contexts
for ft, lang in pairs(ft_to_lang) do
    vim.api.nvim_create_autocmd('FileType', {
        pattern = ft,
        callback = function()
            require('ts_context_commentstring.internal').update_commentstring({
                key = '__default',
                lang = lang,
            })
        end,
    })
end