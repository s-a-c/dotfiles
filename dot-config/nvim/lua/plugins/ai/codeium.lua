-- ============================================================================
-- CODEIUM AI CONFIGURATION (DISABLED)
-- ============================================================================
-- This configuration is disabled to resolve AI provider conflicts identified
-- in the 2025-08-10 configuration review. Multiple AI providers (Copilot,
-- Codeium, Avante) were causing memory overhead and keymap conflicts.
--
-- CONFLICT RESOLUTION:
-- - Codeium chat keymap <leader>cc conflicted with CopilotChat
-- - CopilotChat moved to <leader>ch* to resolve conflict
-- - Codeium disabled to reduce memory usage and provider competition
-- - Primary AI stack: Copilot (via blink-copilot) + CopilotChat + Avante
--
-- To re-enable Codeium:
-- 1. Uncomment the setup below
-- 2. Choose different keymaps to avoid conflicts
-- 3. Consider disabling other AI providers to prevent competition

--[[
-- Codeium.nvim setup (DISABLED)
require("codeium").setup({
    -- Enable codeium chat
    enable_chat = true,
    -- Disable nvim-cmp integration since we're using blink.cmp
    enable_cmp_source = false,
})

-- Codeium keymaps (DISABLED - conflicted with CopilotChat)
vim.keymap.set('i', '<C-g>', function () return vim.fn['codeium#Accept']() end, { expr = true, silent = true })
vim.keymap.set('i', '<c-;>', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true, silent = true })
vim.keymap.set('i', '<c-,>', function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true, silent = true })
vim.keymap.set('i', '<c-x>', function() return vim.fn['codeium#Clear']() end, { expr = true, silent = true })

-- Chat functionality (DISABLED - conflicted with CopilotChat <leader>cc)
vim.keymap.set('n', '<leader>cd', function() require('codeium.chat').open() end, { desc = 'Open Codeium Chat' })
--]]

-- Notify that this configuration is disabled
vim.notify("Codeium disabled - using Copilot + CopilotChat for AI assistance", vim.log.levels.INFO)
