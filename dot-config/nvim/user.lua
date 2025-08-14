-- ============================================================================
-- USER CONFIGURATION
-- ============================================================================
-- This file is for your personal customizations
-- It will be loaded automatically and is ignored by git

local customization = require('config.customization')

-- ============================================================================
-- EXAMPLE CUSTOMIZATIONS
-- ============================================================================

-- Register a custom hook
-- customization.register_hook('after_init', function()
--     vim.notify('Custom initialization complete!', vim.log.levels.INFO)
-- end)

-- Register a configuration override
-- customization.register_override('opt.number', true)
-- customization.register_override('opt.relativenumber', true)

-- Register a custom module
-- customization.register_module('my_module', {
--     setup = function()
--         -- Your custom setup code here
--     end
-- })

-- Register a custom theme
-- customization.register_theme('my_theme', {
--     colorscheme = 'default',
--     highlights = {
--         Normal = { bg = '#1e1e1e', fg = '#d4d4d4' },
--     },
-- })

-- Register a custom extension
-- customization.register_extension('my_extension', {
--     setup = function()
--         -- Extension setup code
--     end,
--     commands = {
--         MyCommand = {
--             callback = function()
--                 vim.notify('Hello from custom command!')
--             end,
--             opts = { desc = 'My custom command' }
--         }
--     },
--     keymaps = {
--         { lhs = '<leader>mc', rhs = ':MyCommand<CR>', opts = { desc = 'My custom keymap' } }
--     }
-- })

-- ============================================================================
-- YOUR CUSTOMIZATIONS
-- ============================================================================

-- Add your customizations below this line

