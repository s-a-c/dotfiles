-- ============================================================================
-- GLOBAL CONFIGURATION (SECURITY HARDENED)
-- ============================================================================
-- Configure global objects and utilities for Neovim with namespace protection
--
-- SECURITY IMPROVEMENTS (2025-08-10):
-- - Moved global functions under vim.config namespace to prevent conflicts
-- - Reduced global namespace pollution
-- - Added conflict detection and warnings
-- - Maintained backward compatibility with deprecation notices

-- ============================================================================
-- NAMESPACE ORGANIZATION
-- ============================================================================

-- Create a dedicated namespace for configuration utilities
vim.config = vim.config or {}
vim.config.utils = vim.config.utils or {}

-- ============================================================================
-- ENHANCED UTILITIES (NAMESPACED)
-- ============================================================================

-- Utility functions under vim.config namespace (RECOMMENDED)
vim.config.utils.inspect = function(...)
    print(vim.inspect(...))
    return ...
end

vim.config.utils.reload = function(name)
    if not pcall(require, "plenary.reload") then
        vim.notify("plenary.reload not available", vim.log.levels.WARN)
        return require(name)
    end
    require("plenary.reload").reload_module(name)
    return require(name)
end

vim.config.utils.map = function(mode, lhs, rhs, opts)
    opts = opts or {}
    vim.keymap.set(mode, lhs, rhs, opts)
end

vim.config.utils.autocmd = function(event, opts)
    vim.api.nvim_create_autocmd(event, opts)
end

vim.config.utils.command = function(name, cmd, opts)
    vim.api.nvim_create_user_command(name, cmd, opts or {})
end

-- ============================================================================
-- BACKWARD COMPATIBILITY (DEPRECATED)
-- ============================================================================

-- Provide backward compatibility with deprecation warnings
local function create_deprecated_global(name, new_path, func)
    if _G[name] then
        vim.notify(string.format("Global '%s' already exists - potential conflict detected", name), vim.log.levels.WARN)
        return
    end
    
    _G[name] = function(...)
        vim.notify(string.format("Global '%s' is deprecated. Use '%s' instead.", name, new_path), vim.log.levels.WARN)
        return func(...)
    end
end

-- Create deprecated globals with warnings (for backward compatibility)
create_deprecated_global("P", "vim.config.utils.inspect", vim.config.utils.inspect)
create_deprecated_global("R", "vim.config.utils.reload", vim.config.utils.reload)
create_deprecated_global("map", "vim.config.utils.map", vim.config.utils.map)
create_deprecated_global("autocmd", "vim.config.utils.autocmd", vim.config.utils.autocmd)
create_deprecated_global("command", "vim.config.utils.command", vim.config.utils.command)

-- ============================================================================
-- VIM OBJECT ENHANCEMENTS
-- ============================================================================

-- Add custom properties to vim object for easier access
vim.g.config_path = vim.fn.stdpath('config')
vim.g.data_path = vim.fn.stdpath('data')
vim.g.cache_path = vim.fn.stdpath('cache')

-- Custom vim utilities
vim.utils = vim.utils or {}

-- Utility to check if a plugin is loaded
vim.utils.has_plugin = function(plugin)
    return pcall(require, plugin)
end

-- Utility to safely require a module
vim.utils.safe_require = function(module)
    local ok, result = pcall(require, module)
    if not ok then
        vim.notify("Failed to load module: " .. module, vim.log.levels.ERROR)
        return nil
    end
    return result
end

-- Utility to get current buffer info
vim.utils.buf_info = function()
    return {
        bufnr = vim.api.nvim_get_current_buf(),
        filetype = vim.bo.filetype,
        filename = vim.fn.expand('%:t'),
        filepath = vim.fn.expand('%:p'),
    }
end

-- ============================================================================
-- DEBUGGING UTILITIES (NAMESPACED)
-- ============================================================================

-- Enhanced debugging functions under vim.config namespace
vim.config.debug = vim.config.debug or {}

vim.config.debug.inspect = function(...)
    if vim.utils.has_plugin("snacks") then
        require("snacks").debug.inspect(...)
    else
        print(vim.inspect(...))
    end
end

vim.config.debug.backtrace = function()
    if vim.utils.has_plugin("snacks") then
        require("snacks").debug.backtrace()
    else
        print(debug.traceback())
    end
end

vim.config.debug.profile = function(func, name)
    name = name or "anonymous"
    local start = vim.loop.hrtime()
    local result = func()
    local duration = (vim.loop.hrtime() - start) / 1e6 -- Convert to milliseconds
    vim.notify(string.format("Profile [%s]: %.2fms", name, duration), vim.log.levels.INFO)
    return result
end

-- ============================================================================
-- LSP UTILITIES (NAMESPACED)
-- ============================================================================

vim.config.lsp = vim.config.lsp or {}

vim.config.lsp.info = function()
    local clients = vim.lsp.get_active_clients({ bufnr = 0 })
    if #clients == 0 then
        print("No LSP clients attached")
        return
    end
    
    for _, client in ipairs(clients) do
        print(string.format("LSP: %s (id: %d)", client.name, client.id))
    end
end

vim.config.lsp.restart = function()
    vim.cmd("LspRestart")
    vim.notify("LSP servers restarted", vim.log.levels.INFO)
end

-- ============================================================================
-- DEPRECATED GLOBALS (BACKWARD COMPATIBILITY)
-- ============================================================================

-- Create deprecated debugging globals with warnings
create_deprecated_global("dd", "vim.config.debug.inspect", vim.config.debug.inspect)
create_deprecated_global("bt", "vim.config.debug.backtrace", vim.config.debug.backtrace)
create_deprecated_global("lsp_info", "vim.config.lsp.info", vim.config.lsp.info)

-- Safely override vim.print if not already overridden
if vim.print == print then
    vim.print = vim.config.debug.inspect
end

-- ============================================================================
-- SECURITY NOTICE
-- ============================================================================

-- Log security improvements
vim.notify("Global namespace secured - functions moved to vim.config.*", vim.log.levels.INFO)