-- ============================================================================
-- LSP CONFIGURATION
-- ============================================================================
-- Language Server Protocol configuration and setup

-- Load LSP modules
require("plugins.lsp.mason")
require("plugins.lsp.servers")
require("plugins.lsp.completion")

-- ============================================================================
-- NOTE: LSP KEYMAPS CONSOLIDATED IN autocommands.lua
-- ============================================================================
-- All LSP keymaps are now handled in the LspAttach autocommand in
-- lua/config/autocommands.lua for better organization and to avoid duplication.
-- This includes formatting, navigation, diagnostics, and code actions.
