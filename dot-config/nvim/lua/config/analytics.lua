-- ============================================================================
-- ADVANCED PERFORMANCE ANALYTICS
-- ============================================================================
-- Comprehensive performance tracking, analysis, and optimization recommendations

local M = {}

-- Analytics data storage
local analytics = {
    session_start = 0,
    metrics = {
        startup_times = {},
        memory_usage = {},
        plugin_performance = {},
        keymap_usage = {},
        command_usage = {},
        file_operations = {},
        lsp_performance = {},
        completion_stats = {},
    },
    trends = {},
    recommendations = {},
    last_analysis = 0,
}

-- Performance thresholds
local thresholds = {
    startup_time = { good = 300, warning = 500, critical = 1000 },
    memory_usage = { good = 150, warning = 300, critical = 500 },
    plugin_load = { good = 50, warning = 100, critical = 200 },
    lsp_response = { good = 100, warning = 300, critical = 1000 },
    completion_time = { good = 50, warning = 150, critical = 500 },
}

-- ============================================================================
-- DATA COLLECTION
-- ============================================================================

-- Record startup performance
function M.record_startup()
    local startup_time = vim.fn.reltime()
    analytics.session_start = vim.fn.localtime()
    
    vim.defer_fn(function()
        local time_ms = vim.fn.reltimefloat(vim.fn.reltime(startup_time)) * 1000
        table.insert(analytics.metrics.startup_times, {
            timestamp = analytics.session_start,
            time = time_ms,
            plugin_count = #vim.tbl_keys(package.loaded),
        })
        
        M.analyze_startup_trend()
    end, 100)
end

-- Record memory usage
function M.record_memory_usage()
    local memory_kb = vim.fn.system("ps -o rss= -p " .. vim.fn.getpid()):gsub("%s+", "")
    local memory_mb = tonumber(memory_kb) / 1024
    
    table.insert(analytics.metrics.memory_usage, {
        timestamp = vim.fn.localtime(),
        memory = memory_mb,
        buffers = #vim.api.nvim_list_bufs(),
        windows = #vim.api.nvim_list_wins(),
    })
    
    -- Keep only last 100 measurements
    if #analytics.metrics.memory_usage > 100 then
        table.remove(analytics.metrics.memory_usage, 1)
    end
end

-- Record keymap usage
function M.record_keymap_usage(keymap)
    local timestamp = vim.fn.localtime()
    if not analytics.metrics.keymap_usage[keymap] then
        analytics.metrics.keymap_usage[keymap] = {
            count = 0,
            first_used = timestamp,
            last_used = timestamp,
            avg_frequency = 0,
        }
    end
    
    local usage = analytics.metrics.keymap_usage[keymap]
    usage.count = usage.count + 1
    usage.last_used = timestamp
    
    -- Calculate average frequency (uses per hour)
    local hours_since_first = (timestamp - usage.first_used) / 3600
    if hours_since_first > 0 then
        usage.avg_frequency = usage.count / hours_since_first
    end
end

-- Record command usage
function M.record_command_usage(command)
    local timestamp = vim.fn.localtime()
    if not analytics.metrics.command_usage[command] then
        analytics.metrics.command_usage[command] = {
            count = 0,
            first_used = timestamp,
            last_used = timestamp,
        }
    end
    
    local usage = analytics.metrics.command_usage[command]
    usage.count = usage.count + 1
    usage.last_used = timestamp
end

-- Record file operation performance
function M.record_file_operation(operation, file_size, duration)
    table.insert(analytics.metrics.file_operations, {
        timestamp = vim.fn.localtime(),
        operation = operation,
        file_size = file_size,
        duration = duration,
        throughput = file_size / duration, -- bytes per ms
    })
    
    -- Keep only last 50 operations
    if #analytics.metrics.file_operations > 50 then
        table.remove(analytics.metrics.file_operations, 1)
    end
end

-- Record LSP performance
function M.record_lsp_performance(server, operation, duration)
    if not analytics.metrics.lsp_performance[server] then
        analytics.metrics.lsp_performance[server] = {}
    end
    
    if not analytics.metrics.lsp_performance[server][operation] then
        analytics.metrics.lsp_performance[server][operation] = {
            count = 0,
            total_time = 0,
            avg_time = 0,
            min_time = math.huge,
            max_time = 0,
        }
    end
    
    local perf = analytics.metrics.lsp_performance[server][operation]
    perf.count = perf.count + 1
    perf.total_time = perf.total_time + duration
    perf.avg_time = perf.total_time / perf.count
    perf.min_time = math.min(perf.min_time, duration)
    perf.max_time = math.max(perf.max_time, duration)
end

-- Record completion statistics
function M.record_completion_stats(provider, items_count, duration)
    if not analytics.metrics.completion_stats[provider] then
        analytics.metrics.completion_stats[provider] = {
            requests = 0,
            total_items = 0,
            total_time = 0,
            avg_items = 0,
            avg_time = 0,
        }
    end
    
    local stats = analytics.metrics.completion_stats[provider]
    stats.requests = stats.requests + 1
    stats.total_items = stats.total_items + items_count
    stats.total_time = stats.total_time + duration
    stats.avg_items = stats.total_items / stats.requests
    stats.avg_time = stats.total_time / stats.requests
end

-- ============================================================================
-- TREND ANALYSIS
-- ============================================================================

-- Analyze startup time trends
function M.analyze_startup_trend()
    local startup_times = analytics.metrics.startup_times
    if #startup_times < 2 then return end
    
    local recent_times = {}
    local cutoff = vim.fn.localtime() - (7 * 24 * 3600) -- Last 7 days
    
    for _, entry in ipairs(startup_times) do
        if entry.timestamp > cutoff then
            table.insert(recent_times, entry.time)
        end
    end
    
    if #recent_times < 2 then return end
    
    -- Calculate trend
    local sum = 0
    for _, time in ipairs(recent_times) do
        sum = sum + time
    end
    local avg = sum / #recent_times
    
    -- Compare with previous period
    local prev_avg = 0
    local prev_count = 0
    local prev_cutoff = cutoff - (7 * 24 * 3600)
    
    for _, entry in ipairs(startup_times) do
        if entry.timestamp > prev_cutoff and entry.timestamp <= cutoff then
            prev_avg = prev_avg + entry.time
            prev_count = prev_count + 1
        end
    end
    
    if prev_count > 0 then
        prev_avg = prev_avg / prev_count
        local trend = ((avg - prev_avg) / prev_avg) * 100
        
        analytics.trends.startup_time = {
            current_avg = avg,
            previous_avg = prev_avg,
            trend_percent = trend,
            direction = trend > 5 and "worsening" or trend < -5 and "improving" or "stable"
        }
    end
end

-- Analyze memory usage trends
function M.analyze_memory_trend()
    local memory_data = analytics.metrics.memory_usage
    if #memory_data < 10 then return end
    
    -- Get recent data (last hour)
    local recent_data = {}
    local cutoff = vim.fn.localtime() - 3600
    
    for _, entry in ipairs(memory_data) do
        if entry.timestamp > cutoff then
            table.insert(recent_data, entry.memory)
        end
    end
    
    if #recent_data < 5 then return end
    
    -- Calculate trend using linear regression
    local n = #recent_data
    local sum_x, sum_y, sum_xy, sum_x2 = 0, 0, 0, 0
    
    for i, memory in ipairs(recent_data) do
        sum_x = sum_x + i
        sum_y = sum_y + memory
        sum_xy = sum_xy + (i * memory)
        sum_x2 = sum_x2 + (i * i)
    end
    
    local slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
    
    analytics.trends.memory_usage = {
        slope = slope,
        direction = slope > 1 and "increasing" or slope < -1 and "decreasing" or "stable",
        current_avg = sum_y / n,
    }
end

-- ============================================================================
-- PERFORMANCE ANALYSIS
-- ============================================================================

-- Analyze overall performance
function M.analyze_performance()
    local analysis = {
        timestamp = vim.fn.localtime(),
        scores = {},
        issues = {},
        recommendations = {},
    }
    
    -- Startup performance score
    local startup_times = analytics.metrics.startup_times
    if #startup_times > 0 then
        local latest_startup = startup_times[#startup_times].time
        local startup_score = 100
        
        if latest_startup > thresholds.startup_time.critical then
            startup_score = 20
            table.insert(analysis.issues, "Critical startup time: " .. math.floor(latest_startup) .. "ms")
            table.insert(analysis.recommendations, "Consider disabling heavy plugins or implementing lazy loading")
        elseif latest_startup > thresholds.startup_time.warning then
            startup_score = 60
            table.insert(analysis.issues, "Slow startup time: " .. math.floor(latest_startup) .. "ms")
            table.insert(analysis.recommendations, "Review plugin loading order and implement conditional loading")
        elseif latest_startup > thresholds.startup_time.good then
            startup_score = 80
        end
        
        analysis.scores.startup = startup_score
    end
    
    -- Memory performance score
    local memory_data = analytics.metrics.memory_usage
    if #memory_data > 0 then
        local latest_memory = memory_data[#memory_data].memory
        local memory_score = 100
        
        if latest_memory > thresholds.memory_usage.critical then
            memory_score = 20
            table.insert(analysis.issues, "Critical memory usage: " .. math.floor(latest_memory) .. "MB")
            table.insert(analysis.recommendations, "Restart Neovim or disable memory-intensive plugins")
        elseif latest_memory > thresholds.memory_usage.warning then
            memory_score = 60
            table.insert(analysis.issues, "High memory usage: " .. math.floor(latest_memory) .. "MB")
            table.insert(analysis.recommendations, "Monitor plugin memory usage and consider alternatives")
        elseif latest_memory > thresholds.memory_usage.good then
            memory_score = 80
        end
        
        analysis.scores.memory = memory_score
    end
    
    -- LSP performance score
    local lsp_score = 100
    for server, operations in pairs(analytics.metrics.lsp_performance) do
        for operation, perf in pairs(operations) do
            if perf.avg_time > thresholds.lsp_response.warning then
                lsp_score = math.min(lsp_score, 70)
                table.insert(analysis.issues, string.format("Slow LSP %s.%s: %.0fms avg", server, operation, perf.avg_time))
            end
        end
    end
    analysis.scores.lsp = lsp_score
    
    -- Calculate overall score
    local scores = analysis.scores
    local total_score = 0
    local score_count = 0
    
    for _, score in pairs(scores) do
        total_score = total_score + score
        score_count = score_count + 1
    end
    
    analysis.overall_score = score_count > 0 and (total_score / score_count) or 100
    
    analytics.last_analysis = vim.fn.localtime()
    return analysis
end

-- ============================================================================
-- OPTIMIZATION RECOMMENDATIONS
-- ============================================================================

-- Generate optimization recommendations
function M.generate_recommendations()
    local recommendations = {}
    
    -- Analyze keymap usage for optimization
    local keymap_usage = analytics.metrics.keymap_usage
    local unused_keymaps = {}
    local frequently_used = {}
    
    for keymap, usage in pairs(keymap_usage) do
        if usage.avg_frequency < 0.1 then -- Less than once per 10 hours
            table.insert(unused_keymaps, keymap)
        elseif usage.avg_frequency > 5 then -- More than 5 times per hour
            table.insert(frequently_used, keymap)
        end
    end
    
    if #unused_keymaps > 0 then
        table.insert(recommendations, {
            category = "Keymap Optimization",
            priority = "low",
            message = "Consider removing unused keymaps: " .. table.concat(unused_keymaps, ", "),
            action = "Review and remove unused keymap definitions"
        })
    end
    
    if #frequently_used > 0 then
        table.insert(recommendations, {
            category = "Keymap Optimization",
            priority = "medium",
            message = "Frequently used keymaps: " .. table.concat(frequently_used, ", "),
            action = "Ensure these keymaps are optimally positioned for ergonomics"
        })
    end
    
    -- Analyze plugin performance
    local slow_plugins = {}
    for plugin, time in pairs(analytics.metrics.plugin_performance) do
        if time > thresholds.plugin_load.warning then
            table.insert(slow_plugins, {plugin = plugin, time = time})
        end
    end
    
    if #slow_plugins > 0 then
        table.sort(slow_plugins, function(a, b) return a.time > b.time end)
        local plugin_names = {}
        for _, p in ipairs(slow_plugins) do
            table.insert(plugin_names, p.plugin)
        end
        
        table.insert(recommendations, {
            category = "Plugin Performance",
            priority = "high",
            message = "Slow-loading plugins detected: " .. table.concat(plugin_names, ", "),
            action = "Implement lazy loading or find faster alternatives"
        })
    end
    
    -- Analyze completion performance
    for provider, stats in pairs(analytics.metrics.completion_stats) do
        if stats.avg_time > thresholds.completion_time.warning then
            table.insert(recommendations, {
                category = "Completion Performance",
                priority = "medium",
                message = string.format("Slow completion provider: %s (%.0fms avg)", provider, stats.avg_time),
                action = "Consider adjusting completion settings or switching providers"
            })
        end
    end
    
    return recommendations
end

-- ============================================================================
-- REPORTING
-- ============================================================================

-- Generate comprehensive analytics report
function M.generate_report()
    local analysis = M.analyze_performance()
    local recommendations = M.generate_recommendations()
    
    local report = {
        "=== Advanced Performance Analytics Report ===",
        string.format("Generated: %s", os.date("%Y-%m-%d %H:%M:%S")),
        string.format("Session Duration: %.1f hours", (vim.fn.localtime() - analytics.session_start) / 3600),
        "",
        "=== Performance Scores ===",
        string.format("Overall Score: %.0f/100", analysis.overall_score),
    }
    
    for category, score in pairs(analysis.scores) do
        local status = score >= 80 and "🟢" or score >= 60 and "🟡" or "🔴"
        table.insert(report, string.format("%s %s: %.0f/100", status, category:gsub("^%l", string.upper), score))
    end
    
    -- Add trend information
    if analytics.trends.startup_time then
        table.insert(report, "")
        table.insert(report, "=== Performance Trends ===")
        local trend = analytics.trends.startup_time
        table.insert(report, string.format("Startup Time: %.0fms (trend: %s, %.1f%%)", 
            trend.current_avg, trend.direction, trend.trend_percent))
    end
    
    if analytics.trends.memory_usage then
        local trend = analytics.trends.memory_usage
        table.insert(report, string.format("Memory Usage: %.0fMB (trend: %s)", 
            trend.current_avg, trend.direction))
    end
    
    -- Add issues
    if #analysis.issues > 0 then
        table.insert(report, "")
        table.insert(report, "=== Performance Issues ===")
        for _, issue in ipairs(analysis.issues) do
            table.insert(report, "⚠️ " .. issue)
        end
    end
    
    -- Add recommendations
    if #recommendations > 0 then
        table.insert(report, "")
        table.insert(report, "=== Optimization Recommendations ===")
        
        -- Group by priority
        local by_priority = {high = {}, medium = {}, low = {}}
        for _, rec in ipairs(recommendations) do
            table.insert(by_priority[rec.priority], rec)
        end
        
        for _, priority in ipairs({"high", "medium", "low"}) do
            if #by_priority[priority] > 0 then
                table.insert(report, string.format("--- %s Priority ---", priority:gsub("^%l", string.upper)))
                for _, rec in ipairs(by_priority[priority]) do
                    table.insert(report, string.format("📋 %s: %s", rec.category, rec.message))
                    table.insert(report, string.format("   💡 %s", rec.action))
                end
            end
        end
    end
    
    -- Add usage statistics
    table.insert(report, "")
    table.insert(report, "=== Usage Statistics ===")
    table.insert(report, string.format("Total Keymaps Used: %d", vim.tbl_count(analytics.metrics.keymap_usage)))
    table.insert(report, string.format("Total Commands Used: %d", vim.tbl_count(analytics.metrics.command_usage)))
    table.insert(report, string.format("File Operations: %d", #analytics.metrics.file_operations))
    
    return table.concat(report, "\n")
end

-- ============================================================================
-- AUTO-MONITORING SETUP
-- ============================================================================

-- Setup automatic monitoring
function M.setup_monitoring()
    -- Record startup
    M.record_startup()
    
    -- Setup periodic memory monitoring
    local memory_timer = vim.loop.new_timer()
    memory_timer:start(30000, 30000, vim.schedule_wrap(function()
        M.record_memory_usage()
        M.analyze_memory_trend()
    end))
    
    -- Setup keymap usage tracking
    local original_keymap_set = vim.keymap.set
    vim.keymap.set = function(mode, lhs, rhs, opts)
        local result = original_keymap_set(mode, lhs, rhs, opts)
        
        -- Track when keymap is actually used
        if type(rhs) == "function" then
            local original_rhs = rhs
            rhs = function(...)
                M.record_keymap_usage(lhs)
                return original_rhs(...)
            end
        end
        
        return result
    end
    
    -- Setup periodic analysis
    local analysis_timer = vim.loop.new_timer()
    analysis_timer:start(300000, 300000, vim.schedule_wrap(function() -- Every 5 minutes
        M.analyze_startup_trend()
        M.analyze_memory_trend()
    end))
end

-- ============================================================================
-- COMMANDS
-- ============================================================================

-- Setup user commands
function M.setup_commands()
    vim.api.nvim_create_user_command("AnalyticsReport", function()
        local report = M.generate_report()
        vim.notify(report, vim.log.levels.INFO, { title = "Performance Analytics" })
    end, { desc = "Show comprehensive performance analytics report" })
    
    vim.api.nvim_create_user_command("AnalyticsReset", function()
        analytics.metrics = {
            startup_times = {},
            memory_usage = {},
            plugin_performance = {},
            keymap_usage = {},
            command_usage = {},
            file_operations = {},
            lsp_performance = {},
            completion_stats = {},
        }
        analytics.trends = {}
        vim.notify("Analytics data reset", vim.log.levels.INFO, { title = "Performance Analytics" })
    end, { desc = "Reset analytics data" })
    
    vim.api.nvim_create_user_command("AnalyticsExport", function()
        local export_file = vim.fn.stdpath('data') .. '/analytics_export_' .. os.date("%Y%m%d_%H%M%S") .. '.json'
        local export_data = vim.fn.json_encode(analytics)
        vim.fn.writefile({export_data}, export_file)
        vim.notify("Analytics exported to: " .. export_file, vim.log.levels.INFO, { title = "Performance Analytics" })
    end, { desc = "Export analytics data to JSON file" })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize analytics system
function M.setup()
    M.setup_commands()
    M.setup_monitoring()
    
    vim.notify("Advanced performance analytics initialized", vim.log.levels.INFO, { title = "Performance Analytics" })
end

return M