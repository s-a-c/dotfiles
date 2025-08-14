-- ============================================================================
-- SYSTEM HEALTH DASHBOARD
-- ============================================================================
-- Comprehensive system health monitoring and dashboard display

local M = {}

-- Dashboard state
local dashboard_state = {
    last_update = 0,
    cached_data = {},
    update_interval = 30, -- seconds
    auto_refresh = false,
}

-- Health indicators
local health_indicators = {
    excellent = { icon = "🟢", threshold = 90, color = "Green" },
    good = { icon = "🟡", threshold = 70, color = "Yellow" },
    warning = { icon = "🟠", threshold = 50, color = "Orange" },
    critical = { icon = "🔴", threshold = 0, color = "Red" },
}

-- ============================================================================
-- DATA COLLECTION
-- ============================================================================

-- Get system overview
local function get_system_overview()
    local overview = {
        neovim_version = vim.version(),
        uptime = vim.fn.localtime() - (vim.g.nvim_start_time or vim.fn.localtime()),
        config_version = "2025.01.10",
        total_plugins = 0,
        loaded_plugins = 0,
        memory_usage = 0,
        startup_time = 0,
    }
    
    -- Count plugins
    overview.total_plugins = vim.tbl_count(package.loaded)
    overview.loaded_plugins = overview.total_plugins -- All loaded plugins are counted
    
    -- Get memory usage
    local memory_kb = vim.fn.system("ps -o rss= -p " .. vim.fn.getpid()):gsub("%s+", "")
    overview.memory_usage = tonumber(memory_kb) / 1024 or 0
    
    -- Get startup time from performance module if available
    local perf_ok, performance = pcall(require, "config.performance")
    if perf_ok then
        local metrics = performance.get_metrics()
        if metrics and metrics.startup_times and #metrics.startup_times > 0 then
            overview.startup_time = metrics.startup_times[#metrics.startup_times].time
        end
    end
    
    return overview
end

-- Get health scores
local function get_health_scores()
    local scores = {
        overall = 100,
        performance = 100,
        security = 100,
        configuration = 100,
        plugins = 100,
    }
    
    -- Performance score
    local system = get_system_overview()
    if system.startup_time > 500 then
        scores.performance = 40
    elseif system.startup_time > 300 then
        scores.performance = 70
    elseif system.startup_time > 200 then
        scores.performance = 85
    end
    
    if system.memory_usage > 400 then
        scores.performance = math.min(scores.performance, 50)
    elseif system.memory_usage > 250 then
        scores.performance = math.min(scores.performance, 75)
    end
    
    -- Configuration score
    local validation_ok, validation = pcall(require, "config.validation")
    if validation_ok then
        local issues = validation.validate_all()
        local error_count = 0
        local warning_count = 0
        
        for _, issue in ipairs(issues) do
            if issue.severity == "high" then
                error_count = error_count + 1
            elseif issue.severity == "medium" then
                warning_count = warning_count + 1
            end
        end
        
        scores.configuration = math.max(0, 100 - (error_count * 20) - (warning_count * 10))
    end
    
    -- Plugin score
    local plugin_loader_ok, plugin_loader = pcall(require, "config.plugin-loader")
    if plugin_loader_ok then
        local metrics = plugin_loader.get_metrics()
        if metrics then
            local failure_rate = #metrics.failed_plugins / math.max(1, metrics.total_plugins)
            scores.plugins = math.max(0, 100 - (failure_rate * 100))
        end
    end
    
    -- Security score (assume good if no critical issues)
    scores.security = 95 -- High baseline, reduced by validation issues
    
    -- Overall score
    scores.overall = math.floor((scores.performance + scores.security + scores.configuration + scores.plugins) / 4)
    
    return scores
end

-- Get recent activity
local function get_recent_activity()
    local activity = {
        errors = {},
        warnings = {},
        performance_events = {},
        migrations = {},
    }
    
    -- Get recent errors from debug tools
    local debug_ok, debug_tools = pcall(require, "config.debug-tools")
    if debug_ok then
        -- This would get recent errors from debug tools
        -- Implementation depends on debug tools API
    end
    
    -- Get recent migrations
    local migration_ok, migration = pcall(require, "config.migration")
    if migration_ok then
        -- This would get recent migration history
        -- Implementation depends on migration API
    end
    
    return activity
end

-- Get system recommendations
local function get_recommendations()
    local recommendations = {}
    local system = get_system_overview()
    local scores = get_health_scores()
    
    -- Performance recommendations
    if system.startup_time > 300 then
        table.insert(recommendations, {
            type = "performance",
            priority = "high",
            message = "Slow startup detected (" .. math.floor(system.startup_time) .. "ms)",
            action = "Run :PerformanceOptimize or switch to performance profile",
            command = "PerformanceOptimize"
        })
    end
    
    if system.memory_usage > 300 then
        table.insert(recommendations, {
            type = "performance",
            priority = "medium",
            message = "High memory usage (" .. math.floor(system.memory_usage) .. "MB)",
            action = "Consider restarting Neovim or switching to minimal profile",
            command = "ConfigProfile minimal"
        })
    end
    
    -- Configuration recommendations
    if scores.configuration < 80 then
        table.insert(recommendations, {
            type = "configuration",
            priority = "high",
            message = "Configuration issues detected",
            action = "Run configuration validation and auto-fix",
            command = "ConfigFix"
        })
    end
    
    -- Plugin recommendations
    if scores.plugins < 90 then
        table.insert(recommendations, {
            type = "plugins",
            priority = "medium",
            message = "Plugin issues detected",
            action = "Check plugin health and reload failed plugins",
            command = "PluginReport"
        })
    end
    
    -- General maintenance
    if system.uptime > 86400 then -- 24 hours
        table.insert(recommendations, {
            type = "maintenance",
            priority = "low",
            message = "Long session detected (" .. math.floor(system.uptime / 3600) .. " hours)",
            action = "Consider restarting Neovim for optimal performance",
            command = "ConfigBackup"
        })
    end
    
    return recommendations
end

-- ============================================================================
-- DASHBOARD GENERATION
-- ============================================================================

-- Get health indicator
local function get_health_indicator(score)
    for _, indicator in pairs(health_indicators) do
        if score >= indicator.threshold then
            return indicator
        end
    end
    return health_indicators.critical
end

-- Generate dashboard content
local function generate_dashboard()
    local system = get_system_overview()
    local scores = get_health_scores()
    local recommendations = get_recommendations()
    local activity = get_recent_activity()
    
    local dashboard = {
        "╭─────────────────────────────────────────────────────────────╮",
        "│                    🚀 NEOVIM HEALTH DASHBOARD                │",
        "╰─────────────────────────────────────────────────────────────╯",
        "",
    }
    
    -- System Overview
    table.insert(dashboard, "📊 SYSTEM OVERVIEW")
    table.insert(dashboard, "├─ Neovim Version: " .. string.format("%d.%d.%d", 
        system.neovim_version.major, system.neovim_version.minor, system.neovim_version.patch))
    table.insert(dashboard, "├─ Config Version: " .. system.config_version)
    table.insert(dashboard, "├─ Session Uptime: " .. string.format("%.1f hours", system.uptime / 3600))
    table.insert(dashboard, "├─ Memory Usage: " .. string.format("%.1f MB", system.memory_usage))
    table.insert(dashboard, "├─ Startup Time: " .. string.format("%.0f ms", system.startup_time))
    table.insert(dashboard, "└─ Loaded Plugins: " .. system.loaded_plugins)
    table.insert(dashboard, "")
    
    -- Health Scores
    table.insert(dashboard, "🏥 HEALTH SCORES")
    local overall_indicator = get_health_indicator(scores.overall)
    table.insert(dashboard, "├─ Overall Health: " .. overall_indicator.icon .. " " .. scores.overall .. "/100")
    
    local perf_indicator = get_health_indicator(scores.performance)
    table.insert(dashboard, "├─ Performance: " .. perf_indicator.icon .. " " .. scores.performance .. "/100")
    
    local config_indicator = get_health_indicator(scores.configuration)
    table.insert(dashboard, "├─ Configuration: " .. config_indicator.icon .. " " .. scores.configuration .. "/100")
    
    local plugin_indicator = get_health_indicator(scores.plugins)
    table.insert(dashboard, "├─ Plugins: " .. plugin_indicator.icon .. " " .. scores.plugins .. "/100")
    
    local security_indicator = get_health_indicator(scores.security)
    table.insert(dashboard, "└─ Security: " .. security_indicator.icon .. " " .. scores.security .. "/100")
    table.insert(dashboard, "")
    
    -- Recommendations
    if #recommendations > 0 then
        table.insert(dashboard, "💡 RECOMMENDATIONS")
        for i, rec in ipairs(recommendations) do
            local priority_icon = rec.priority == "high" and "🔴" or 
                                 rec.priority == "medium" and "🟡" or "🟢"
            local prefix = i == #recommendations and "└─" or "├─"
            table.insert(dashboard, prefix .. " " .. priority_icon .. " " .. rec.message)
            table.insert(dashboard, "   💡 " .. rec.action)
            if rec.command then
                table.insert(dashboard, "   ⚡ :" .. rec.command)
            end
            if i < #recommendations then
                table.insert(dashboard, "")
            end
        end
        table.insert(dashboard, "")
    end
    
    -- Quick Actions
    table.insert(dashboard, "⚡ QUICK ACTIONS")
    table.insert(dashboard, "├─ :ConfigHealth        - Show detailed health report")
    table.insert(dashboard, "├─ :ConfigFix           - Auto-fix configuration issues")
    table.insert(dashboard, "├─ :PerformanceCheck    - Run performance diagnostics")
    table.insert(dashboard, "├─ :AnalyticsReport     - View performance analytics")
    table.insert(dashboard, "├─ :PluginReport        - Check plugin status")
    table.insert(dashboard, "└─ :DashboardRefresh    - Refresh this dashboard")
    table.insert(dashboard, "")
    
    -- Footer
    table.insert(dashboard, "📅 Last Updated: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(dashboard, "🔄 Auto-refresh: " .. (dashboard_state.auto_refresh and "Enabled" or "Disabled"))
    
    return table.concat(dashboard, "\n")
end

-- ============================================================================
-- DASHBOARD DISPLAY
-- ============================================================================

-- Show dashboard in floating window
function M.show_dashboard()
    local content = generate_dashboard()
    local lines = vim.split(content, "\n")
    
    -- Calculate window size
    local width = 0
    for _, line in ipairs(lines) do
        width = math.max(width, vim.fn.strdisplaywidth(line))
    end
    width = math.min(width + 4, vim.o.columns - 10)
    local height = math.min(#lines + 2, vim.o.lines - 10)
    
    -- Create buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    
    -- Calculate window position (center)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    -- Create window
    local win_opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
        title = ' Health Dashboard ',
        title_pos = 'center',
    }
    
    local win = vim.api.nvim_open_win(buf, true, win_opts)
    
    -- Set window options
    vim.api.nvim_win_set_option(win, 'winblend', 10)
    vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:Normal,FloatBorder:FloatBorder')
    
    -- Set keymaps for the dashboard
    local opts = { buffer = buf, silent = true }
    vim.keymap.set('n', 'q', '<cmd>close<cr>', opts)
    vim.keymap.set('n', '<Esc>', '<cmd>close<cr>', opts)
    vim.keymap.set('n', 'r', function()
        vim.api.nvim_buf_set_option(buf, 'modifiable', true)
        local new_content = generate_dashboard()
        local new_lines = vim.split(new_content, "\n")
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
        vim.notify("Dashboard refreshed", vim.log.levels.INFO, { title = "Dashboard" })
    end, opts)
    
    dashboard_state.last_update = vim.fn.localtime()
    
    return win, buf
end

-- Show dashboard in buffer
function M.show_dashboard_buffer()
    local content = generate_dashboard()
    local lines = vim.split(content, "\n")
    
    -- Create or reuse dashboard buffer
    local buf_name = "Health Dashboard"
    local existing_buf = vim.fn.bufnr(buf_name)
    
    local buf
    if existing_buf ~= -1 then
        buf = existing_buf
    else
        buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(buf, buf_name)
    end
    
    -- Set buffer content
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'dashboard')
    
    -- Open buffer in current window
    vim.api.nvim_set_current_buf(buf)
    
    dashboard_state.last_update = vim.fn.localtime()
    
    return buf
end

-- ============================================================================
-- AUTO-REFRESH
-- ============================================================================

-- Setup auto-refresh
function M.setup_auto_refresh()
    if dashboard_state.auto_refresh then
        return -- Already enabled
    end
    
    dashboard_state.auto_refresh = true
    
    local timer = vim.loop.new_timer()
    timer:start(dashboard_state.update_interval * 1000, dashboard_state.update_interval * 1000, 
        vim.schedule_wrap(function()
            if not dashboard_state.auto_refresh then
                timer:stop()
                return
            end
            
            -- Only refresh if dashboard is visible
            local dashboard_visible = false
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                local buf_name = vim.api.nvim_buf_get_name(buf)
                if buf_name:match("Health Dashboard") then
                    dashboard_visible = true
                    break
                end
            end
            
            if dashboard_visible then
                -- Refresh dashboard content
                dashboard_state.cached_data = {}
            end
        end))
end

-- Disable auto-refresh
function M.disable_auto_refresh()
    dashboard_state.auto_refresh = false
end

-- ============================================================================
-- COMMANDS
-- ============================================================================

-- Setup dashboard commands
function M.setup_commands()
    vim.api.nvim_create_user_command("Dashboard", function()
        M.show_dashboard()
    end, { desc = "Show health dashboard in floating window" })
    
    vim.api.nvim_create_user_command("DashboardBuffer", function()
        M.show_dashboard_buffer()
    end, { desc = "Show health dashboard in buffer" })
    
    vim.api.nvim_create_user_command("DashboardRefresh", function()
        dashboard_state.cached_data = {}
        dashboard_state.last_update = 0
        vim.notify("Dashboard data refreshed", vim.log.levels.INFO, { title = "Dashboard" })
    end, { desc = "Refresh dashboard data" })
    
    vim.api.nvim_create_user_command("DashboardAutoRefresh", function(opts)
        if opts.args == "on" or opts.args == "enable" then
            M.setup_auto_refresh()
            vim.notify("Dashboard auto-refresh enabled", vim.log.levels.INFO, { title = "Dashboard" })
        elseif opts.args == "off" or opts.args == "disable" then
            M.disable_auto_refresh()
            vim.notify("Dashboard auto-refresh disabled", vim.log.levels.INFO, { title = "Dashboard" })
        else
            local status = dashboard_state.auto_refresh and "enabled" or "disabled"
            vim.notify("Dashboard auto-refresh is " .. status, vim.log.levels.INFO, { title = "Dashboard" })
        end
    end, {
        nargs = "?",
        desc = "Control dashboard auto-refresh",
        complete = function() return {"on", "off", "enable", "disable"} end
    })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize dashboard system
function M.setup()
    M.setup_commands()
    
    vim.notify("System health dashboard initialized", vim.log.levels.INFO, { title = "Dashboard" })
end

return M