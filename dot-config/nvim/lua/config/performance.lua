-- ============================================================================
-- PERFORMANCE MONITORING AND OPTIMIZATION
-- ============================================================================
-- Performance monitoring, validation, and optimization utilities

local M = {}

-- Performance metrics storage
local metrics = {
    startup_time = 0,
    plugin_load_times = {},
    memory_usage = {},
    last_check = 0,
}

-- ============================================================================
-- STARTUP PERFORMANCE MONITORING
-- ============================================================================

-- Record startup time
function M.record_startup_time()
    local start_time = vim.fn.reltime()
    vim.defer_fn(function()
        metrics.startup_time = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000
        if metrics.startup_time > 200 then
            vim.notify(
                string.format("Slow startup detected: %.2fms", metrics.startup_time),
                vim.log.levels.WARN,
                { title = "Performance Monitor" }
            )
        end
    end, 0)
end

-- ============================================================================
-- PLUGIN PERFORMANCE MONITORING
-- ============================================================================

-- Monitor plugin loading times
function M.monitor_plugin_loading()
    local original_require = require
    
    -- Override require to track plugin loading times
    _G.require = function(module)
        if module:match("^plugins/") then
            local start_time = vim.fn.reltime()
            local result = original_require(module)
            local load_time = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000
            
            metrics.plugin_load_times[module] = load_time
            
            -- Warn about slow-loading plugins
            if load_time > 50 then
                vim.notify(
                    string.format("Slow plugin load: %s (%.2fms)", module, load_time),
                    vim.log.levels.WARN,
                    { title = "Performance Monitor" }
                )
            end
            
            return result
        end
        return original_require(module)
    end
end

-- ============================================================================
-- MEMORY MONITORING
-- ============================================================================

-- Check memory usage
function M.check_memory_usage()
    local memory_kb = vim.fn.system("ps -o rss= -p " .. vim.fn.getpid()):gsub("%s+", "")
    local memory_mb = tonumber(memory_kb) / 1024
    
    metrics.memory_usage[os.time()] = memory_mb
    metrics.last_check = os.time()
    
    -- Warn about high memory usage
    if memory_mb > 500 then
        vim.notify(
            string.format("High memory usage: %.1fMB", memory_mb),
            vim.log.levels.WARN,
            { title = "Performance Monitor" }
        )
    end
    
    return memory_mb
end

-- ============================================================================
-- CONFIGURATION VALIDATION
-- ============================================================================

-- Validate critical configuration
function M.validate_configuration()
    local issues = {}
    
    -- Check for AI provider conflicts
    local ai_providers = {}
    if pcall(require, "copilot") then table.insert(ai_providers, "copilot") end
    if pcall(require, "codeium") then table.insert(ai_providers, "codeium") end
    if pcall(require, "avante") then table.insert(ai_providers, "avante") end
    
    if #ai_providers > 2 then
        table.insert(issues, {
            type = "warning",
            message = "Multiple AI providers detected: " .. table.concat(ai_providers, ", "),
            suggestion = "Consider disabling some providers to reduce conflicts"
        })
    end
    
    -- Check for missing essential plugins
    local essential_plugins = {
        "telescope",
        "nvim-treesitter",
        "mason",
        "which-key",
    }
    
    for _, plugin in ipairs(essential_plugins) do
        if not pcall(require, plugin) then
            table.insert(issues, {
                type = "error",
                message = "Missing essential plugin: " .. plugin,
                suggestion = "Install " .. plugin .. " for core functionality"
            })
        end
    end
    
    -- Check for keymap conflicts
    local keymaps = vim.api.nvim_get_keymap('n')
    local leader_mappings = {}
    
    for _, keymap in ipairs(keymaps) do
        if keymap.lhs:match("^<leader>") then
            if leader_mappings[keymap.lhs] then
                table.insert(issues, {
                    type = "warning",
                    message = "Keymap conflict detected: " .. keymap.lhs,
                    suggestion = "Review keymap assignments to avoid conflicts"
                })
            end
            leader_mappings[keymap.lhs] = true
        end
    end
    
    return issues
end

-- ============================================================================
-- PERFORMANCE OPTIMIZATION
-- ============================================================================

-- Optimize Neovim settings for performance
function M.optimize_performance()
    -- Reduce updatetime for better responsiveness
    vim.opt.updatetime = 250
    
    -- Optimize syntax highlighting
    vim.opt.synmaxcol = 300
    
    -- Reduce redraw frequency
    vim.opt.lazyredraw = true
    
    -- Optimize completion
    vim.opt.completeopt = { "menu", "menuone", "noselect" }
    
    -- Optimize search
    vim.opt.ignorecase = true
    vim.opt.smartcase = true
    
    -- Optimize file handling
    vim.opt.hidden = true
    vim.opt.backup = false
    vim.opt.writebackup = false
    vim.opt.swapfile = false
    
    vim.notify("Performance optimizations applied", vim.log.levels.INFO, { title = "Performance Monitor" })
end

-- ============================================================================
-- HEALTH CHECK
-- ============================================================================

-- Comprehensive health check
function M.health_check()
    local health = {
        startup_time = metrics.startup_time,
        memory_usage = M.check_memory_usage(),
        plugin_count = #vim.tbl_keys(metrics.plugin_load_times),
        issues = M.validate_configuration(),
        timestamp = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    -- Generate health report
    local report = {
        "=== Neovim Performance Health Check ===",
        string.format("Timestamp: %s", health.timestamp),
        string.format("Startup Time: %.2fms", health.startup_time or 0),
        string.format("Memory Usage: %.1fMB", health.memory_usage),
        string.format("Loaded Plugins: %d", health.plugin_count),
        "",
        "=== Issues Found ===",
    }
    
    if #health.issues == 0 then
        table.insert(report, "✅ No issues detected")
    else
        for _, issue in ipairs(health.issues) do
            local icon = issue.type == "error" and "❌" or "⚠️"
            table.insert(report, string.format("%s %s", icon, issue.message))
            table.insert(report, string.format("   💡 %s", issue.suggestion))
        end
    end
    
    -- Display report
    vim.notify(table.concat(report, "\n"), vim.log.levels.INFO, { title = "Health Check" })
    
    return health
end

-- ============================================================================
-- PERFORMANCE COMMANDS
-- ============================================================================

-- Create user commands for performance monitoring
function M.setup_commands()
    vim.api.nvim_create_user_command("PerformanceCheck", function()
        M.health_check()
    end, { desc = "Run performance health check" })
    
    vim.api.nvim_create_user_command("PerformanceOptimize", function()
        M.optimize_performance()
    end, { desc = "Apply performance optimizations" })
    
    vim.api.nvim_create_user_command("PerformanceReport", function()
        local report = {
            "=== Performance Metrics ===",
            string.format("Startup Time: %.2fms", metrics.startup_time or 0),
            string.format("Memory Usage: %.1fMB", M.check_memory_usage()),
            "",
            "=== Plugin Load Times ===",
        }
        
        local sorted_plugins = {}
        for plugin, time in pairs(metrics.plugin_load_times) do
            table.insert(sorted_plugins, { plugin = plugin, time = time })
        end
        table.sort(sorted_plugins, function(a, b) return a.time > b.time end)
        
        for i, plugin_data in ipairs(sorted_plugins) do
            if i <= 10 then -- Show top 10 slowest plugins
                table.insert(report, string.format("%.2fms - %s", plugin_data.time, plugin_data.plugin))
            end
        end
        
        vim.notify(table.concat(report, "\n"), vim.log.levels.INFO, { title = "Performance Report" })
    end, { desc = "Show detailed performance report" })
end

-- ============================================================================
-- AUTO-MONITORING
-- ============================================================================

-- Setup automatic performance monitoring
function M.setup_auto_monitoring()
    -- Monitor startup time
    M.record_startup_time()
    
    -- Setup periodic memory checks
    local timer = vim.loop.new_timer()
    timer:start(60000, 60000, vim.schedule_wrap(function()
        M.check_memory_usage()
    end))
    
    -- Validate configuration on startup
    vim.defer_fn(function()
        local issues = M.validate_configuration()
        if #issues > 0 then
            vim.notify(
                string.format("Configuration issues detected: %d", #issues),
                vim.log.levels.WARN,
                { title = "Config Validation" }
            )
        end
    end, 1000)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize performance monitoring
function M.setup()
    M.setup_commands()
    M.setup_auto_monitoring()
    M.monitor_plugin_loading()
    
    vim.notify("Performance monitoring initialized", vim.log.levels.INFO, { title = "Performance Monitor" })
end

return M