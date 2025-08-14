-- ============================================================================
-- NEOVIM CORE CONFIGURATION LOADER
-- ============================================================================
-- This file loads all core configuration modules in the correct order

local M = {}

-- Load configuration modules in order
function M.setup()
    -- Load core options first
    require("config.options")

    -- Load global objects and utilities
    require("config.globals")

    -- Load basic keymaps (plugin-specific keymaps are loaded with their plugins)
    require("config.keymaps")

    -- Load autocommands
    require("config.autocommands")

    -- Load plugins and their configurations
    require("plugins").setup()

    -- Load the colorscheme
    require("config.colorscheme")

    -- Load snacks.nvim optimizations
    require("config.snacks-optimization")

    -- Initialize performance monitoring and validation systems
    require("config.performance").setup()
    require("config.validation").setup()
    require("config.plugin-loader").setup()
    require("config.analytics").setup()
    require("config.debug-tools").setup()
    require("config.migration").setup()
    require("config.customization").setup()
    require("config.dashboard").setup()
end

return M
