-- ============================================================================
-- LSP SERVER CONFIGURATIONS
-- ============================================================================
-- Individual LSP server configurations

local lspconfig = require('lspconfig')

-- ============================================================================
-- LUA LSP CONFIGURATION
-- ============================================================================

lspconfig.lua_ls.setup({
    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT',
            },
            diagnostics = {
                globals = {
                    'vim',
                    'require',
                    '_G',
                    'P',
                    'R',
                    'map',
                    'autocmd',
                    'command',
                    'dd',
                    'bt',
                    'lsp',
                    'diagnostic',
                    'lsp_info'
                },
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
                enable = false,
            },
        },
    },
})

-- ============================================================================
-- PHP LSP CONFIGURATION
-- ============================================================================

-- PHP LSP configuration using standard lspconfig approach
-- Note: phpactor is the standard PHP LSP server available through Mason
-- If you need devsense-php-ls specifically, it should be configured through Mason

-- Standard phpactor configuration (will be auto-configured by Mason)
-- This replaces the manual vim.lsp.start() approach which was deprecated
if vim.fn.executable("phpactor") == 1 then
    lspconfig.phpactor.setup({
        root_dir = lspconfig.util.root_pattern("composer.json", ".git"),
        settings = {
            phpactor = {
                completion = {
                    enabled = true,
                },
                diagnostics = {
                    enabled = true,
                },
            },
        },
    })
end

-- Alternative: If you specifically need devsense-php-ls, add it to Mason packages
-- and it will be automatically configured through the Mason integration

-- ============================================================================
-- OTHER LSP SERVERS
-- ============================================================================

-- Add other LSP server configurations here as needed
-- They will be automatically installed by Mason if listed in mason.lua
