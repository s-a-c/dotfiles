-- ============================================================================
-- UFO FOLDING CONFIGURATION
-- ============================================================================
-- Advanced folding configuration

-- UFO folding settings (already set in options.lua, but included here for reference)
vim.o.foldcolumn = '1'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- UFO keymaps
vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = "Open all folds" })
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = "Close all folds" })
vim.keymap.set('n', 'zr', require('ufo').openFoldsExceptKinds, { desc = "Open folds except kinds" })
vim.keymap.set('n', 'zm', require('ufo').closeFoldsWith, { desc = "Close folds with" })
vim.keymap.set('n', 'zp', require('ufo').peekFoldedLinesUnderCursor, { desc = "Peek folded lines" })

-- Additional UFO keymaps
vim.keymap.set('n', '<leader>zR', require('ufo').openAllFolds, { desc = "UFO: Open all folds" })
vim.keymap.set('n', '<leader>zM', require('ufo').closeAllFolds, { desc = "UFO: Close all folds" })
vim.keymap.set('n', '<leader>zp', require('ufo').peekFoldedLinesUnderCursor, { desc = "UFO: Peek folded lines" })
vim.keymap.set('n', '<leader>zP', function()
    local winid = require('ufo').peekFoldedLinesUnderCursor()
    if not winid then
        vim.lsp.buf.hover()
    end
end, { desc = "UFO: Peek or hover" })

-- UFO setup with multiple providers
require('ufo').setup({
    provider_selector = function(bufnr, filetype, buftype)
        -- Handle different file types appropriately
        if filetype == '' or buftype == 'nofile' then
            return ''
        end

        -- For most files, use LSP as main, indent as fallback
        -- Treesitter can be unreliable for some file types
        return {'lsp', 'indent'}
    end,
    open_fold_hl_timeout = 150,
    close_fold_kinds_for_ft = {
        default = {'imports', 'comment'},
        json = {'array'},
        c = {'comment', 'region'}
    },
    preview = {
        win_config = {
            border = {'', '─', '', '', '', '─', '', ''},
            winhighlight = 'Normal:Folded',
            winblend = 0
        },
        mappings = {
            scrollU = '<C-u>',
            scrollD = '<C-d>',
            jumpTop = '[',
            jumpBot = ']'
        }
    },
    fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = (' 󰁂 %d '):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
            local chunkText = chunk[1]
            local chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if targetWidth > curWidth + chunkWidth then
                table.insert(newVirtText, chunk)
            else
                chunkText = truncate(chunkText, targetWidth - curWidth)
                local hlGroup = chunk[2]
                table.insert(newVirtText, {chunkText, hlGroup})
                chunkWidth = vim.fn.strdisplaywidth(chunkText)
                if curWidth + chunkWidth < targetWidth then
                    suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
                end
                break
            end
            curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, {suffix, 'MoreMsg'})
        return newVirtText
    end
})
