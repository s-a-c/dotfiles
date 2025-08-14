-- ============================================================================
-- AUTOCOMMANDS
-- ============================================================================
-- Autocommands for various editor behaviors and enhancements

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- ============================================================================
-- GENERAL EDITOR BEHAVIOR
-- ============================================================================

-- Highlight on yank
local highlight_group = augroup('YankHighlight', { clear = true })
autocmd('TextYankPost', {
    group = highlight_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 300,
        })
    end,
    desc = 'Highlight yanked text',
})

-- Remove trailing whitespace on save
local trim_whitespace_group = augroup('TrimWhitespace', { clear = true })
autocmd('BufWritePre', {
    group = trim_whitespace_group,
    pattern = '*',
    callback = function()
        local save_cursor = vim.fn.getpos('.')
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.setpos('.', save_cursor)
    end,
    desc = 'Remove trailing whitespace on save',
})

-- ============================================================================
-- FILE TYPE SPECIFIC SETTINGS
-- ============================================================================

-- Set specific settings for different file types
local filetype_group = augroup('FileTypeSettings', { clear = true })

-- Markdown files
autocmd('FileType', {
    group = filetype_group,
    pattern = { 'markdown', 'md' },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
        vim.opt_local.conceallevel = 2
    end,
    desc = 'Markdown file settings',
})

-- Git commit messages
autocmd('FileType', {
    group = filetype_group,
    pattern = 'gitcommit',
    callback = function()
        vim.opt_local.spell = true
        vim.opt_local.textwidth = 72
    end,
    desc = 'Git commit message settings',
})

-- JSON files
autocmd('FileType', {
    group = filetype_group,
    pattern = 'json',
    callback = function()
        vim.opt_local.conceallevel = 0
    end,
    desc = 'JSON file settings',
})

-- Help files
autocmd('FileType', {
    group = filetype_group,
    pattern = 'help',
    callback = function()
        vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = true, desc = 'Close help' })
    end,
    desc = 'Help file settings',
})

-- ============================================================================
-- WINDOW AND BUFFER MANAGEMENT
-- ============================================================================

-- Auto-resize windows when terminal is resized
local resize_group = augroup('AutoResize', { clear = true })
autocmd('VimResized', {
    group = resize_group,
    pattern = '*',
    callback = function()
        vim.cmd('tabdo wincmd =')
    end,
    desc = 'Auto-resize windows on terminal resize',
})

-- Close certain filetypes with q
local close_with_q_group = augroup('CloseWithQ', { clear = true })
autocmd('FileType', {
    group = close_with_q_group,
    pattern = {
        'qf',
        'help',
        'man',
        'notify',
        'lspinfo',
        'spectre_panel',
        'startuptime',
        'tsplayground',
        'PlenaryTestPopup',
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true, desc = 'Close buffer' })
    end,
    desc = 'Close certain filetypes with q',
})

-- ============================================================================
-- LSP RELATED AUTOCOMMANDS
-- ============================================================================

-- LSP attach autocommand (will be used by LSP configuration)
local lsp_group = augroup('LspAttach', { clear = true })
autocmd('LspAttach', {
    group = lsp_group,
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        local bufnr = event.buf

        -- Enable completion triggered by <c-x><c-o>
        vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- LSP-specific keymaps (consolidated from lsp/init.lua)
        local opts = { buffer = bufnr, silent = true }
        
        -- Navigation keymaps
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
        vim.keymap.set('i', '<C-h>', vim.lsp.buf.signature_help, opts)
        
        -- Diagnostic keymaps
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
        vim.keymap.set('n', '<leader>vd', vim.diagnostic.open_float, opts)
        
        -- Code actions and refactoring
        vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>vrn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>vrr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', '<leader>vws', vim.lsp.buf.workspace_symbol, opts)
        
        -- Formatting keymap (LSP/Conform integration)
        vim.keymap.set('n', '<leader>lf', function()
            -- Try conform first, fallback to LSP
            local conform_ok, conform = pcall(require, "conform")
            if conform_ok then
                conform.format({
                    async = true,
                    lsp_fallback = true,
                    timeout_ms = 2000,
                })
            else
                vim.lsp.buf.format()
            end
        end, { buffer = bufnr, silent = true, desc = 'Format document (LSP/Conform)' })

        -- Format on save for certain file types
        if client.supports_method('textDocument/formatting') then
            autocmd('BufWritePre', {
                buffer = bufnr,
                callback = function()
                    vim.lsp.buf.format({ bufnr = bufnr })
                end,
                desc = 'Format on save',
            })
        end
    end,
    desc = 'LSP attach configuration',
})

-- ============================================================================
-- STARTUP AND PERFORMANCE
-- ============================================================================

-- Record startup time
vim.g.start_time = vim.fn.reltime()

-- Check if we need to reload the file when it changed
local checktime_group = augroup('Checktime', { clear = true })
autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
    group = checktime_group,
    command = 'checktime',
    desc = 'Check if file changed outside of vim',
})

-- ============================================================================
-- TERMINAL SPECIFIC
-- ============================================================================

-- Terminal settings
local terminal_group = augroup('Terminal', { clear = true })
autocmd('TermOpen', {
    group = terminal_group,
    pattern = '*',
    callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = 'no'
    end,
    desc = 'Terminal settings',
})

-- ============================================================================
-- LARGE FILE HANDLING
-- ============================================================================

-- Handle large files
local large_file_group = augroup('LargeFile', { clear = true })
autocmd('BufReadPre', {
    group = large_file_group,
    pattern = '*',
    callback = function()
        local file_size = vim.fn.getfsize(vim.fn.expand('%'))
        if file_size > 1024 * 1024 then -- 1MB
            vim.opt_local.syntax = 'off'
            vim.opt_local.filetype = ''
            vim.opt_local.undolevels = -1
            vim.opt_local.swapfile = false
            vim.opt_local.loadplugins = false
            vim.notify('Large file detected, some features disabled', vim.log.levels.WARN)
        end
    end,
    desc = 'Handle large files',
})

-- ============================================================================
-- GLOBAL LSP-RELATED KEYMAPS
-- ============================================================================

-- Mason mappings (moved from lsp/init.lua for consolidation)
vim.keymap.set('n', '<leader>lm', '<cmd>Mason<cr>', { desc = 'Mason' })
vim.keymap.set('n', '<leader>li', '<cmd>MasonInstall ', { desc = 'Mason install' })
vim.keymap.set('n', '<leader>lu', '<cmd>MasonUpdate<cr>', { desc = 'Mason update' })
vim.keymap.set('n', '<leader>ls', '<cmd>MasonUninstall ', { desc = 'Mason uninstall' })
