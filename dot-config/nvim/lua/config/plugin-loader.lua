-- ============================================================================
-- ADVANCED PLUGIN LOADING OPTIMIZATION
-- ============================================================================
-- Intelligent plugin loading with performance monitoring and conditional loading

local M = {}

-- Plugin loading metrics
local loading_metrics = {
    total_plugins = 0,
    loaded_plugins = 0,
    failed_plugins = {},
    load_times = {},
    memory_usage = {},
    conditional_skips = {},
}

-- Environment detection
local env_detection = {
    is_large_project = nil,
    is_git_repo = nil,
    is_development = nil,
    available_memory = nil,
    cpu_cores = nil,
}

-- ============================================================================
-- ENVIRONMENT DETECTION
-- ============================================================================

-- Detect if current project is large
local function detect_large_project()
    if env_detection.is_large_project ~= nil then
        return env_detection.is_large_project
    end
    
    local cwd = vim.fn.getcwd()
    local file_count = 0
    
    -- Use cached result if available
    local cache_file = vim.fn.stdpath('cache') .. '/project_size_' .. vim.fn.fnamemodify(cwd, ':t')
    if vim.fn.filereadable(cache_file) == 1 then
        local cached_data = vim.fn.readfile(cache_file)
        if #cached_data > 0 then
            file_count = tonumber(cached_data[1]) or 0
        end
    else
        -- Count files efficiently
        local count_cmd = "find " .. vim.fn.shellescape(cwd) .. " -type f 2>/dev/null | wc -l"
        local result = vim.fn.system(count_cmd)
        file_count = tonumber(result:gsub("%s+", "")) or 0
        
        -- Cache the result
        vim.fn.writefile({tostring(file_count)}, cache_file)
    end
    
    env_detection.is_large_project = file_count > 5000
    return env_detection.is_large_project
end

-- Detect if current directory is a git repository
local function detect_git_repo()
    if env_detection.is_git_repo ~= nil then
        return env_detection.is_git_repo
    end
    
    env_detection.is_git_repo = vim.fn.isdirectory('.git') == 1 or 
                               vim.fn.system('git rev-parse --git-dir 2>/dev/null'):find('.git') ~= nil
    return env_detection.is_git_repo
end

-- Detect development environment
local function detect_development_env()
    if env_detection.is_development ~= nil then
        return env_detection.is_development
    end
    
    local dev_indicators = {
        'package.json', 'Cargo.toml', 'go.mod', 'requirements.txt',
        'Makefile', 'CMakeLists.txt', '.env', 'docker-compose.yml'
    }
    
    for _, indicator in ipairs(dev_indicators) do
        if vim.fn.filereadable(indicator) == 1 then
            env_detection.is_development = true
            return true
        end
    end
    
    env_detection.is_development = false
    return false
end

-- Get available system memory
local function get_available_memory()
    if env_detection.available_memory ~= nil then
        return env_detection.available_memory
    end
    
    local memory_cmd = "free -m 2>/dev/null | awk '/^Mem:/ {print $7}' || vm_stat 2>/dev/null | awk '/Pages free/ {print int($3) * 4096 / 1024 / 1024}'"
    local result = vim.fn.system(memory_cmd)
    env_detection.available_memory = tonumber(result:gsub("%s+", "")) or 4096 -- Default to 4GB
    
    return env_detection.available_memory
end

-- ============================================================================
-- CONDITIONAL PLUGIN LOADING
-- ============================================================================

-- Plugin loading conditions
local loading_conditions = {
    -- Memory-intensive plugins
    heavy_plugins = function()
        return get_available_memory() > 2048 -- Require 2GB+ free memory
    end,
    
    -- Large project optimizations
    large_project_plugins = function()
        return not detect_large_project() -- Skip heavy plugins in large projects
    end,
    
    -- Development-specific plugins
    development_plugins = function()
        return detect_development_env()
    end,
    
    -- Git-related plugins
    git_plugins = function()
        return detect_git_repo()
    end,
    
    -- AI plugins (based on configuration)
    ai_plugins = function()
        local ai_config = vim.g.ai_enabled
        if ai_config == nil then
            ai_config = true -- Default to enabled
        end
        return ai_config and get_available_memory() > 1024
    end,
    
    -- UI enhancement plugins
    ui_plugins = function()
        return not vim.g.minimal_ui and get_available_memory() > 512
    end,
}

-- Check if plugin should be loaded
local function should_load_plugin(plugin_name, conditions)
    if not conditions then
        return true -- No conditions means always load
    end
    
    for _, condition in ipairs(conditions) do
        if loading_conditions[condition] and not loading_conditions[condition]() then
            loading_metrics.conditional_skips[plugin_name] = condition
            return false
        end
    end
    
    return true
end

-- ============================================================================
-- PERFORMANCE-OPTIMIZED PLUGIN LOADER
-- ============================================================================

-- Load plugin with performance monitoring
local function load_plugin_with_monitoring(plugin_spec)
    local plugin_name = plugin_spec.name or plugin_spec[1] or "unknown"
    local start_time = vim.loop.hrtime()
    local start_memory = collectgarbage("count")
    
    loading_metrics.total_plugins = loading_metrics.total_plugins + 1
    
    -- Check loading conditions
    if not should_load_plugin(plugin_name, plugin_spec.conditions) then
        return false
    end
    
    local success, result = pcall(function()
        if plugin_spec.config then
            return plugin_spec.config()
        elseif plugin_spec.setup then
            return plugin_spec.setup()
        else
            return require(plugin_name)
        end
    end)
    
    local end_time = vim.loop.hrtime()
    local end_memory = collectgarbage("count")
    
    local load_time = (end_time - start_time) / 1e6 -- Convert to milliseconds
    local memory_delta = end_memory - start_memory
    
    loading_metrics.load_times[plugin_name] = load_time
    loading_metrics.memory_usage[plugin_name] = memory_delta
    
    if success then
        loading_metrics.loaded_plugins = loading_metrics.loaded_plugins + 1
        
        -- Warn about slow-loading plugins
        if load_time > 100 then
            vim.notify(
                string.format("Slow plugin load: %s (%.2fms)", plugin_name, load_time),
                vim.log.levels.WARN,
                { title = "Plugin Loader" }
            )
        end
        
        -- Warn about memory-heavy plugins
        if memory_delta > 50 then
            vim.notify(
                string.format("Memory-heavy plugin: %s (+%.1fMB)", plugin_name, memory_delta),
                vim.log.levels.WARN,
                { title = "Plugin Loader" }
            )
        end
    else
        table.insert(loading_metrics.failed_plugins, {
            name = plugin_name,
            error = tostring(result),
            load_time = load_time
        })
        
        vim.notify(
            string.format("Failed to load plugin: %s - %s", plugin_name, result),
            vim.log.levels.ERROR,
            { title = "Plugin Loader" }
        )
    end
    
    return success
end

-- ============================================================================
-- LAZY LOADING OPTIMIZATION
-- ============================================================================

-- Enhanced lazy loading with intelligent triggers
local function setup_lazy_loading(plugin_spec)
    local plugin_name = plugin_spec.name or plugin_spec[1]
    local triggers = plugin_spec.lazy_triggers or {}
    
    -- Default triggers based on plugin type
    if plugin_spec.type == "lsp" then
        triggers = vim.tbl_extend("force", triggers, {"LspAttach", "BufReadPre"})
    elseif plugin_spec.type == "completion" then
        triggers = vim.tbl_extend("force", triggers, {"InsertEnter"})
    elseif plugin_spec.type == "git" then
        triggers = vim.tbl_extend("force", triggers, {"BufReadPre"})
    elseif plugin_spec.type == "ui" then
        triggers = vim.tbl_extend("force", triggers, {"VimEnter"})
    end
    
    -- Setup lazy loading
    for _, trigger in ipairs(triggers) do
        if trigger:match("^%u") then -- Event trigger
            vim.api.nvim_create_autocmd(trigger, {
                once = true,
                callback = function()
                    load_plugin_with_monitoring(plugin_spec)
                end
            })
        else -- Command or keymap trigger
            -- Setup command or keymap that loads plugin on first use
            vim.api.nvim_create_user_command(trigger, function()
                load_plugin_with_monitoring(plugin_spec)
                vim.cmd(trigger) -- Execute the actual command
            end, { desc = "Lazy-loaded command" })
        end
    end
end

-- ============================================================================
-- PLUGIN DEPENDENCY MANAGEMENT
-- ============================================================================

-- Resolve plugin dependencies
local function resolve_dependencies(plugins)
    local resolved = {}
    local loading_order = {}
    local visited = {}
    
    local function visit(plugin_name)
        if visited[plugin_name] then
            return
        end
        
        visited[plugin_name] = true
        local plugin = plugins[plugin_name]
        
        if plugin and plugin.dependencies then
            for _, dep in ipairs(plugin.dependencies) do
                visit(dep)
            end
        end
        
        table.insert(loading_order, plugin_name)
    end
    
    for plugin_name, _ in pairs(plugins) do
        visit(plugin_name)
    end
    
    return loading_order
end

-- ============================================================================
-- BATCH LOADING OPTIMIZATION
-- ============================================================================

-- Load plugins in optimized batches
local function load_plugins_in_batches(plugins, batch_size)
    batch_size = batch_size or 5
    local loading_order = resolve_dependencies(plugins)
    
    for i = 1, #loading_order, batch_size do
        local batch = {}
        for j = i, math.min(i + batch_size - 1, #loading_order) do
            table.insert(batch, loading_order[j])
        end
        
        -- Load batch concurrently
        local batch_start = vim.loop.hrtime()
        
        for _, plugin_name in ipairs(batch) do
            local plugin_spec = plugins[plugin_name]
            if plugin_spec then
                if plugin_spec.lazy then
                    setup_lazy_loading(plugin_spec)
                else
                    load_plugin_with_monitoring(plugin_spec)
                end
            end
        end
        
        local batch_time = (vim.loop.hrtime() - batch_start) / 1e6
        
        -- Small delay between batches to prevent overwhelming
        if batch_time < 50 and i + batch_size <= #loading_order then
            vim.defer_fn(function() end, 10)
        end
    end
end

-- ============================================================================
-- PERFORMANCE REPORTING
-- ============================================================================

-- Generate loading performance report
function M.generate_performance_report()
    local total_load_time = 0
    local total_memory = 0
    
    for _, time in pairs(loading_metrics.load_times) do
        total_load_time = total_load_time + time
    end
    
    for _, memory in pairs(loading_metrics.memory_usage) do
        total_memory = total_memory + memory
    end
    
    local report = {
        "=== Plugin Loading Performance Report ===",
        string.format("Total Plugins: %d", loading_metrics.total_plugins),
        string.format("Successfully Loaded: %d", loading_metrics.loaded_plugins),
        string.format("Failed: %d", #loading_metrics.failed_plugins),
        string.format("Conditionally Skipped: %d", vim.tbl_count(loading_metrics.conditional_skips)),
        string.format("Total Load Time: %.2fms", total_load_time),
        string.format("Total Memory Usage: +%.1fMB", total_memory),
        "",
        "=== Environment Detection ===",
        string.format("Large Project: %s", detect_large_project() and "Yes" or "No"),
        string.format("Git Repository: %s", detect_git_repo() and "Yes" or "No"),
        string.format("Development Environment: %s", detect_development_env() and "Yes" or "No"),
        string.format("Available Memory: %.0fMB", get_available_memory()),
    }
    
    -- Add slowest plugins
    if vim.tbl_count(loading_metrics.load_times) > 0 then
        table.insert(report, "")
        table.insert(report, "=== Slowest Plugins ===")
        
        local sorted_plugins = {}
        for name, time in pairs(loading_metrics.load_times) do
            table.insert(sorted_plugins, {name = name, time = time})
        end
        table.sort(sorted_plugins, function(a, b) return a.time > b.time end)
        
        for i = 1, math.min(5, #sorted_plugins) do
            local plugin = sorted_plugins[i]
            table.insert(report, string.format("%.2fms - %s", plugin.time, plugin.name))
        end
    end
    
    -- Add failed plugins
    if #loading_metrics.failed_plugins > 0 then
        table.insert(report, "")
        table.insert(report, "=== Failed Plugins ===")
        for _, failure in ipairs(loading_metrics.failed_plugins) do
            table.insert(report, string.format("❌ %s: %s", failure.name, failure.error))
        end
    end
    
    -- Add skipped plugins
    if vim.tbl_count(loading_metrics.conditional_skips) > 0 then
        table.insert(report, "")
        table.insert(report, "=== Conditionally Skipped ===")
        for plugin, condition in pairs(loading_metrics.conditional_skips) do
            table.insert(report, string.format("⏭️ %s (reason: %s)", plugin, condition))
        end
    end
    
    return table.concat(report, "\n")
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Load plugins with optimization
function M.load_plugins(plugins, options)
    options = options or {}
    local batch_size = options.batch_size or 5
    
    vim.notify("Starting optimized plugin loading...", vim.log.levels.INFO, { title = "Plugin Loader" })
    
    local start_time = vim.loop.hrtime()
    load_plugins_in_batches(plugins, batch_size)
    local total_time = (vim.loop.hrtime() - start_time) / 1e6
    
    vim.defer_fn(function()
        local success_rate = (loading_metrics.loaded_plugins / loading_metrics.total_plugins) * 100
        vim.notify(
            string.format("Plugin loading complete: %d/%d loaded (%.1f%%) in %.2fms", 
                loading_metrics.loaded_plugins, loading_metrics.total_plugins, success_rate, total_time),
            vim.log.levels.INFO,
            { title = "Plugin Loader" }
        )
    end, 100)
end

-- Get loading metrics
function M.get_metrics()
    return loading_metrics
end

-- Reset metrics
function M.reset_metrics()
    loading_metrics = {
        total_plugins = 0,
        loaded_plugins = 0,
        failed_plugins = {},
        load_times = {},
        memory_usage = {},
        conditional_skips = {},
    }
end

-- Setup commands
function M.setup_commands()
    vim.api.nvim_create_user_command("PluginReport", function()
        local report = M.generate_performance_report()
        vim.notify(report, vim.log.levels.INFO, { title = "Plugin Performance" })
    end, { desc = "Show plugin loading performance report" })
    
    vim.api.nvim_create_user_command("PluginReload", function(opts)
        local plugin_name = opts.args
        if plugin_name == "" then
            vim.notify("Please specify a plugin name", vim.log.levels.ERROR)
            return
        end
        
        -- Unload plugin
        package.loaded[plugin_name] = nil
        
        -- Reload plugin
        local success, result = pcall(require, plugin_name)
        if success then
            vim.notify("Plugin reloaded: " .. plugin_name, vim.log.levels.INFO)
        else
            vim.notify("Failed to reload plugin: " .. plugin_name .. " - " .. result, vim.log.levels.ERROR)
        end
    end, {
        nargs = 1,
        desc = "Reload a specific plugin",
        complete = function()
            return vim.tbl_keys(package.loaded)
        end
    })
end

-- Initialize plugin loader
function M.setup()
    M.setup_commands()
    vim.notify("Advanced plugin loader initialized", vim.log.levels.INFO, { title = "Plugin Loader" })
end

return M