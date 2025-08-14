-- ============================================================================
-- ADVANCED ERROR RECOVERY AND DEBUGGING TOOLS
-- ============================================================================
-- Comprehensive debugging, error recovery, and diagnostic tools

local M = {}

-- Debug state and configuration
local debug_state = {
    enabled = false,
    log_level = "INFO",
    log_file = nil,
    error_history = {},
    performance_traces = {},
    plugin_states = {},
    recovery_attempts = {},
}

-- Error recovery strategies
local recovery_strategies = {
    plugin_load_failure = {},
    keymap_conflicts = {},
    lsp_failures = {},
    memory_issues = {},
    startup_failures = {},
}

-- ============================================================================
-- ERROR TRACKING AND LOGGING
-- ============================================================================

-- Initialize debug logging
local function init_debug_logging()
    debug_state.log_file = vim.fn.stdpath('log') .. '/nvim_debug.log'
    
    -- Ensure log directory exists
    vim.fn.mkdir(vim.fn.fnamemodify(debug_state.log_file, ':h'), 'p')
    
    -- Clear old log if it's too large (>10MB)
    local log_size = vim.fn.getfsize(debug_state.log_file)
    if log_size > 10 * 1024 * 1024 then
        vim.fn.delete(debug_state.log_file)
    end
end

-- Log debug message
local function log_debug(level, component, message, data)
    if not debug_state.enabled then return end
    
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local log_entry = string.format("[%s] %s [%s] %s", timestamp, level, component, message)
    
    if data then
        log_entry = log_entry .. " | Data: " .. vim.inspect(data)
    end
    
    -- Write to log file
    local log_file = io.open(debug_state.log_file, "a")
    if log_file then
        log_file:write(log_entry .. "\n")
        log_file:close()
    end
    
    -- Also notify if it's an error
    if level == "ERROR" then
        vim.notify(string.format("[%s] %s", component, message), vim.log.levels.ERROR, { title = "Debug Tools" })
    end
end

-- Track error with context
function M.track_error(component, error_msg, context)
    local error_entry = {
        timestamp = vim.fn.localtime(),
        component = component,
        error = error_msg,
        context = context or {},
        stack_trace = debug.traceback(),
    }
    
    table.insert(debug_state.error_history, error_entry)
    
    -- Keep only last 50 errors
    if #debug_state.error_history > 50 then
        table.remove(debug_state.error_history, 1)
    end
    
    log_debug("ERROR", component, error_msg, context)
    
    -- Attempt automatic recovery
    M.attempt_recovery(component, error_msg, context)
end

-- ============================================================================
-- AUTOMATIC ERROR RECOVERY
-- ============================================================================

-- Register recovery strategy
function M.register_recovery_strategy(error_type, strategy_func)
    if not recovery_strategies[error_type] then
        recovery_strategies[error_type] = {}
    end
    table.insert(recovery_strategies[error_type], strategy_func)
end

-- Attempt automatic recovery
function M.attempt_recovery(component, error_msg, context)
    local recovery_key = component .. ":" .. error_msg
    
    -- Prevent infinite recovery loops
    if debug_state.recovery_attempts[recovery_key] then
        if debug_state.recovery_attempts[recovery_key] > 3 then
            log_debug("WARN", "Recovery", "Max recovery attempts reached for: " .. recovery_key)
            return false
        end
    else
        debug_state.recovery_attempts[recovery_key] = 0
    end
    
    debug_state.recovery_attempts[recovery_key] = debug_state.recovery_attempts[recovery_key] + 1
    
    -- Try component-specific recovery strategies
    local strategies = recovery_strategies[component] or {}
    
    for _, strategy in ipairs(strategies) do
        local success, result = pcall(strategy, error_msg, context)
        if success and result then
            log_debug("INFO", "Recovery", "Successfully recovered from: " .. recovery_key)
            vim.notify("Auto-recovered from error: " .. component, vim.log.levels.INFO, { title = "Debug Tools" })
            return true
        end
    end
    
    -- Try generic recovery strategies
    return M.generic_recovery(component, error_msg, context)
end

-- Generic recovery strategies
function M.generic_recovery(component, error_msg, context)
    -- Plugin loading failure recovery
    if error_msg:match("module.*not found") then
        local plugin_name = error_msg:match("module '([^']+)' not found")
        if plugin_name then
            log_debug("INFO", "Recovery", "Attempting to install missing plugin: " .. plugin_name)
            
            -- Try to suggest plugin installation
            vim.notify(
                string.format("Missing plugin detected: %s\nConsider installing it or disabling the configuration.", plugin_name),
                vim.log.levels.WARN,
                { title = "Plugin Recovery" }
            )
            return true
        end
    end
    
    -- LSP server failure recovery
    if component == "lsp" and error_msg:match("server.*not found") then
        local server_name = error_msg:match("server '([^']+)' not found")
        if server_name then
            log_debug("INFO", "Recovery", "Attempting LSP server recovery: " .. server_name)
            
            -- Try to install via Mason
            local mason_ok, mason = pcall(require, "mason-lspconfig")
            if mason_ok then
                vim.defer_fn(function()
                    vim.cmd("MasonInstall " .. server_name)
                end, 1000)
                return true
            end
        end
    end
    
    -- Keymap conflict recovery
    if error_msg:match("keymap.*already exists") then
        log_debug("INFO", "Recovery", "Attempting keymap conflict recovery")
        
        -- Clear conflicting keymap and retry
        local keymap = error_msg:match("keymap '([^']+)' already exists")
        if keymap then
            vim.keymap.del('n', keymap, { silent = true })
            vim.notify("Cleared conflicting keymap: " .. keymap, vim.log.levels.INFO, { title = "Keymap Recovery" })
            return true
        end
    end
    
    return false
end

-- ============================================================================
-- PLUGIN STATE MONITORING
-- ============================================================================

-- Monitor plugin state
function M.monitor_plugin_state(plugin_name)
    local state = {
        loaded = false,
        load_time = 0,
        memory_usage = 0,
        error_count = 0,
        last_error = nil,
    }
    
    -- Check if plugin is loaded
    local ok, plugin = pcall(require, plugin_name)
    state.loaded = ok
    
    if not ok then
        state.last_error = plugin
        state.error_count = state.error_count + 1
        M.track_error("plugin_monitor", "Plugin load failed: " .. plugin_name, { error = plugin })
    end
    
    debug_state.plugin_states[plugin_name] = state
    return state
end

-- Get plugin health report
function M.get_plugin_health()
    local health_report = {
        total_plugins = 0,
        loaded_plugins = 0,
        failed_plugins = {},
        problematic_plugins = {},
    }
    
    for plugin_name, state in pairs(debug_state.plugin_states) do
        health_report.total_plugins = health_report.total_plugins + 1
        
        if state.loaded then
            health_report.loaded_plugins = health_report.loaded_plugins + 1
        else
            table.insert(health_report.failed_plugins, {
                name = plugin_name,
                error = state.last_error,
                error_count = state.error_count,
            })
        end
        
        if state.error_count > 0 then
            table.insert(health_report.problematic_plugins, {
                name = plugin_name,
                error_count = state.error_count,
                last_error = state.last_error,
            })
        end
    end
    
    return health_report
end

-- ============================================================================
-- PERFORMANCE TRACING
-- ============================================================================

-- Start performance trace
function M.start_trace(trace_name)
    debug_state.performance_traces[trace_name] = {
        start_time = vim.loop.hrtime(),
        end_time = nil,
        duration = nil,
        memory_start = collectgarbage("count"),
        memory_end = nil,
        memory_delta = nil,
    }
end

-- End performance trace
function M.end_trace(trace_name)
    local trace = debug_state.performance_traces[trace_name]
    if not trace then
        log_debug("WARN", "Trace", "Trace not found: " .. trace_name)
        return
    end
    
    trace.end_time = vim.loop.hrtime()
    trace.duration = (trace.end_time - trace.start_time) / 1e6 -- Convert to ms
    trace.memory_end = collectgarbage("count")
    trace.memory_delta = trace.memory_end - trace.memory_start
    
    log_debug("INFO", "Trace", string.format("Trace %s completed: %.2fms, %.2fMB", 
        trace_name, trace.duration, trace.memory_delta))
    
    return trace
end

-- Get performance trace report
function M.get_trace_report()
    local report = {
        "=== Performance Trace Report ===",
        string.format("Total Traces: %d", vim.tbl_count(debug_state.performance_traces)),
        "",
    }
    
    -- Sort traces by duration
    local sorted_traces = {}
    for name, trace in pairs(debug_state.performance_traces) do
        if trace.duration then
            table.insert(sorted_traces, { name = name, trace = trace })
        end
    end
    
    table.sort(sorted_traces, function(a, b) return a.trace.duration > b.trace.duration end)
    
    table.insert(report, "=== Slowest Operations ===")
    for i, entry in ipairs(sorted_traces) do
        if i <= 10 then -- Top 10
            table.insert(report, string.format("%.2fms (%.2fMB) - %s", 
                entry.trace.duration, entry.trace.memory_delta, entry.name))
        end
    end
    
    return table.concat(report, "\n")
end

-- ============================================================================
-- SYSTEM DIAGNOSTICS
-- ============================================================================

-- Run comprehensive system diagnostics
function M.run_diagnostics()
    local diagnostics = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        neovim_version = vim.version(),
        system_info = {},
        plugin_health = M.get_plugin_health(),
        error_summary = {},
        performance_summary = {},
        recommendations = {},
    }
    
    -- System information
    diagnostics.system_info = {
        os = vim.loop.os_uname(),
        memory_usage = collectgarbage("count"),
        uptime = vim.fn.localtime() - (debug_state.session_start or vim.fn.localtime()),
        loaded_modules = vim.tbl_count(package.loaded),
    }
    
    -- Error summary
    local recent_errors = vim.tbl_filter(function(error)
        return (vim.fn.localtime() - error.timestamp) < 3600 -- Last hour
    end, debug_state.error_history)
    
    diagnostics.error_summary = {
        total_errors = #debug_state.error_history,
        recent_errors = #recent_errors,
        error_components = {},
    }
    
    -- Group errors by component
    for _, error in ipairs(recent_errors) do
        if not diagnostics.error_summary.error_components[error.component] then
            diagnostics.error_summary.error_components[error.component] = 0
        end
        diagnostics.error_summary.error_components[error.component] = 
            diagnostics.error_summary.error_components[error.component] + 1
    end
    
    -- Performance summary
    local total_trace_time = 0
    local trace_count = 0
    for _, trace in pairs(debug_state.performance_traces) do
        if trace.duration then
            total_trace_time = total_trace_time + trace.duration
            trace_count = trace_count + 1
        end
    end
    
    diagnostics.performance_summary = {
        total_trace_time = total_trace_time,
        average_trace_time = trace_count > 0 and (total_trace_time / trace_count) or 0,
        trace_count = trace_count,
    }
    
    -- Generate recommendations
    if #recent_errors > 10 then
        table.insert(diagnostics.recommendations, "High error rate detected - consider running :DebugReset")
    end
    
    if diagnostics.system_info.memory_usage > 500 then
        table.insert(diagnostics.recommendations, "High memory usage - consider restarting Neovim")
    end
    
    if #diagnostics.plugin_health.failed_plugins > 0 then
        table.insert(diagnostics.recommendations, "Failed plugins detected - run :DebugPluginHealth for details")
    end
    
    return diagnostics
end

-- ============================================================================
-- RECOVERY COMMANDS
-- ============================================================================

-- Emergency recovery mode
function M.emergency_recovery()
    log_debug("INFO", "Recovery", "Starting emergency recovery")
    
    local recovery_steps = {
        "Clearing plugin cache",
        "Resetting keymaps",
        "Reloading core modules",
        "Validating configuration",
    }
    
    local success_count = 0
    
    -- Clear plugin cache
    for name, _ in pairs(package.loaded) do
        if name:match("^plugins/") then
            package.loaded[name] = nil
        end
    end
    success_count = success_count + 1
    
    -- Reset problematic keymaps
    local problematic_keymaps = {"<leader>cc", "<leader>cp", "<leader>cd"}
    for _, keymap in ipairs(problematic_keymaps) do
        pcall(vim.keymap.del, 'n', keymap)
    end
    success_count = success_count + 1
    
    -- Reload core configuration modules
    local core_modules = {"config.options", "config.keymaps", "config.autocommands"}
    for _, module in ipairs(core_modules) do
        package.loaded[module] = nil
        local ok, _ = pcall(require, module)
        if ok then
            success_count = success_count + 1
        end
    end
    
    -- Run configuration validation
    local validation_ok, validation = pcall(require, "config.validation")
    if validation_ok then
        validation.validate_all()
        success_count = success_count + 1
    end
    
    local report = string.format("Emergency recovery completed: %d/%d steps successful", 
        success_count, #recovery_steps)
    
    vim.notify(report, vim.log.levels.INFO, { title = "Emergency Recovery" })
    log_debug("INFO", "Recovery", report)
    
    return success_count == #recovery_steps
end

-- Safe mode startup
function M.safe_mode()
    log_debug("INFO", "SafeMode", "Starting safe mode")
    
    -- Disable all non-essential plugins
    vim.g.safe_mode = true
    
    -- Load only core functionality
    local core_modules = {
        "config.options",
        "config.keymaps", 
        "config.autocommands",
    }
    
    for _, module in ipairs(core_modules) do
        local ok, err = pcall(require, module)
        if not ok then
            log_debug("ERROR", "SafeMode", "Failed to load core module: " .. module, { error = err })
        end
    end
    
    vim.notify("Safe mode activated - only core functionality loaded", vim.log.levels.INFO, { title = "Safe Mode" })
end

-- ============================================================================
-- DEBUG COMMANDS
-- ============================================================================

-- Setup debug commands
function M.setup_commands()
    vim.api.nvim_create_user_command("DebugEnable", function()
        debug_state.enabled = true
        init_debug_logging()
        vim.notify("Debug mode enabled", vim.log.levels.INFO, { title = "Debug Tools" })
    end, { desc = "Enable debug mode" })
    
    vim.api.nvim_create_user_command("DebugDisable", function()
        debug_state.enabled = false
        vim.notify("Debug mode disabled", vim.log.levels.INFO, { title = "Debug Tools" })
    end, { desc = "Disable debug mode" })
    
    vim.api.nvim_create_user_command("DebugReport", function()
        local diagnostics = M.run_diagnostics()
        local report = vim.inspect(diagnostics)
        vim.notify(report, vim.log.levels.INFO, { title = "Debug Report" })
    end, { desc = "Generate debug report" })
    
    vim.api.nvim_create_user_command("DebugErrors", function()
        if #debug_state.error_history == 0 then
            vim.notify("No errors recorded", vim.log.levels.INFO, { title = "Debug Tools" })
            return
        end
        
        local report = { "=== Recent Errors ===" }
        for i = math.max(1, #debug_state.error_history - 10), #debug_state.error_history do
            local error = debug_state.error_history[i]
            table.insert(report, string.format("[%s] %s: %s", 
                os.date("%H:%M:%S", error.timestamp), error.component, error.error))
        end
        
        vim.notify(table.concat(report, "\n"), vim.log.levels.INFO, { title = "Error History" })
    end, { desc = "Show recent errors" })
    
    vim.api.nvim_create_user_command("DebugTraces", function()
        local report = M.get_trace_report()
        vim.notify(report, vim.log.levels.INFO, { title = "Performance Traces" })
    end, { desc = "Show performance traces" })
    
    vim.api.nvim_create_user_command("DebugPluginHealth", function()
        local health = M.get_plugin_health()
        local report = {
            "=== Plugin Health Report ===",
            string.format("Total Plugins: %d", health.total_plugins),
            string.format("Loaded: %d", health.loaded_plugins),
            string.format("Failed: %d", #health.failed_plugins),
            "",
        }
        
        if #health.failed_plugins > 0 then
            table.insert(report, "=== Failed Plugins ===")
            for _, plugin in ipairs(health.failed_plugins) do
                table.insert(report, string.format("❌ %s: %s", plugin.name, plugin.error))
            end
        end
        
        vim.notify(table.concat(report, "\n"), vim.log.levels.INFO, { title = "Plugin Health" })
    end, { desc = "Show plugin health status" })
    
    vim.api.nvim_create_user_command("DebugRecovery", function()
        M.emergency_recovery()
    end, { desc = "Run emergency recovery" })
    
    vim.api.nvim_create_user_command("DebugSafeMode", function()
        M.safe_mode()
    end, { desc = "Start safe mode" })
    
    vim.api.nvim_create_user_command("DebugReset", function()
        debug_state.error_history = {}
        debug_state.performance_traces = {}
        debug_state.recovery_attempts = {}
        collectgarbage("collect")
        vim.notify("Debug state reset", vim.log.levels.INFO, { title = "Debug Tools" })
    end, { desc = "Reset debug state" })
    
    vim.api.nvim_create_user_command("DebugLog", function()
        if debug_state.log_file and vim.fn.filereadable(debug_state.log_file) == 1 then
            vim.cmd("edit " .. debug_state.log_file)
        else
            vim.notify("Debug log not found", vim.log.levels.WARN, { title = "Debug Tools" })
        end
    end, { desc = "Open debug log file" })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize debug tools
function M.setup()
    debug_state.session_start = vim.fn.localtime()
    
    -- Register default recovery strategies
    M.register_recovery_strategy("plugin_load_failure", function(error_msg, context)
        -- Try to reload the plugin
        local plugin_name = context.plugin_name
        if plugin_name then
            package.loaded[plugin_name] = nil
            local ok, _ = pcall(require, plugin_name)
            return ok
        end
        return false
    end)
    
    M.register_recovery_strategy("lsp_failures", function(error_msg, context)
        -- Try to restart LSP client
        local client_name = context.client_name
        if client_name then
            vim.cmd("LspRestart " .. client_name)
            return true
        end
        return false
    end)
    
    -- Setup error handling
    local original_notify = vim.notify
    vim.notify = function(msg, level, opts)
        if level == vim.log.levels.ERROR then
            M.track_error("notify", msg, opts)
        end
        return original_notify(msg, level, opts)
    end
    
    M.setup_commands()
    
    vim.notify("Advanced debug tools initialized", vim.log.levels.INFO, { title = "Debug Tools" })
end

return M