-- ============================================================================
-- DEBUG ADAPTER PROTOCOL CONFIGURATION
-- ============================================================================
-- Debugging configuration

local dap = require('dap')

-- ============================================================================
-- DAP ADAPTERS
-- ============================================================================

-- Basic DAP configuration for common languages
-- JavaScript/TypeScript (Node.js)
dap.adapters.node2 = {
    type = 'executable',
    command = 'node',
    args = { vim.fn.stdpath('data') .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js' },
}

-- ============================================================================
-- DAP CONFIGURATIONS
-- ============================================================================

dap.configurations.javascript = {
    {
        name = 'Launch',
        type = 'node2',
        request = 'launch',
        program = '${file}',
        cwd = vim.fn.getcwd(),
        sourceMaps = true,
        protocol = 'inspector',
        console = 'integratedTerminal',
    },
}

dap.configurations.typescript = dap.configurations.javascript

-- ============================================================================
-- DAP KEYMAPS
-- ============================================================================

-- Basic DAP keymaps (can be expanded as needed)
vim.keymap.set('n', '<F5>', function() require('dap').continue() end, { desc = 'DAP Continue' })
vim.keymap.set('n', '<F10>', function() require('dap').step_over() end, { desc = 'DAP Step Over' })
vim.keymap.set('n', '<F11>', function() require('dap').step_into() end, { desc = 'DAP Step Into' })
vim.keymap.set('n', '<F12>', function() require('dap').step_out() end, { desc = 'DAP Step Out' })
vim.keymap.set('n', '<leader>db', function() require('dap').toggle_breakpoint() end, { desc = 'DAP Toggle Breakpoint' })
vim.keymap.set('n', '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, { desc = 'DAP Set Conditional Breakpoint' })
vim.keymap.set('n', '<leader>dr', function() require('dap').repl.open() end, { desc = 'DAP Open REPL' })
