-- ============================================================================
-- SNACKS.NVIM OPTIMIZATION CONFIGURATION
-- ============================================================================
-- Advanced configuration for maximizing snacks.nvim functionality and performance

-- ============================================================================
-- PERFORMANCE OPTIMIZATION SETTINGS
-- ============================================================================

-- Enable debug loading for performance monitoring
vim.g.snacks_debug_loading = false -- Set to true for detailed loading times

-- Plugin loading optimization flags
vim.g.enable_ai_plugins = true -- Enable AI assistance plugins
vim.g.enable_extended_ai = true -- Enable additional AI tools (codeium, avante, etc.)
vim.g.enable_testing_plugins = true -- Enable neotest and neogen
vim.g.enable_debug_plugins = true -- Enable DAP debugging
vim.g.enable_visual_plugins = true -- Enable visual enhancements
vim.g.enable_learning_plugins = true -- Enable precognition and learning tools
vim.g.enable_wakatime = false -- Enable time tracking (set to true if you use WakaTime)
vim.g.enable_fun_plugins = false -- Enable fun features like typr

-- Force loading certain plugins regardless of project size
vim.g.force_ui_plugins = false -- Force UI plugins in large projects
vim.g.force_php_plugins = false -- Force PHP plugins regardless of file detection

-- ============================================================================
-- SNACKS.NVIM ADVANCED BUFFER MANAGEMENT
-- ============================================================================

-- Enhanced buffer management with snacks.nvim
local function setup_advanced_buffer_management()
    local snacks = require("snacks")
    
    -- Advanced buffer deletion with confirmation for modified buffers
    vim.keymap.set("n", "<leader>bD", function()
        local modified_buffers = {}
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_get_option(buf, "modified") and vim.api.nvim_buf_is_loaded(buf) then
                table.insert(modified_buffers, {
                    buf = buf,
                    name = vim.api.nvim_buf_get_name(buf),
                })
            end
        end
        
        if #modified_buffers > 0 then
            local choices = {}
            for i, buf_info in ipairs(modified_buffers) do
                table.insert(choices, string.format("%d: %s", i, vim.fn.fnamemodify(buf_info.name, ":t")))
            end
            
            vim.ui.select(choices, {
                prompt = "Modified buffers found. Select action:",
                format_item = function(item) return item end,
            }, function(choice)
                if choice then
                    snacks.bufdelete.all()
                else
                    vim.notify("Buffer deletion cancelled", vim.log.levels.INFO)
                end
            end)
        else
            snacks.bufdelete.all()
        end
    end, { desc = "Delete All Buffers (with confirmation)" })
    
    -- Smart buffer navigation with snacks integration
    vim.keymap.set("n", "<leader>bn", function()
        local buffers = {}
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "buflisted") then
                local name = vim.api.nvim_buf_get_name(buf)
                if name ~= "" then
                    table.insert(buffers, {
                        buf = buf,
                        name = name,
                        modified = vim.api.nvim_buf_get_option(buf, "modified"),
                    })
                end
            end
        end
        
        if #buffers > 1 then
            snacks.picker.buffers()
        else
            vim.notify("Only one buffer open", vim.log.levels.INFO)
        end
    end, { desc = "Navigate Buffers (Smart)" })
end

-- ============================================================================
-- ADVANCED NOTIFICATION SYSTEM
-- ============================================================================

local function setup_advanced_notifications()
    local snacks = require("snacks")
    
    -- Custom notification levels with enhanced styling
    local function notify_with_style(message, level, opts)
        opts = opts or {}
        opts.title = opts.title or "Neovim"
        opts.timeout = opts.timeout or 3000
        
        -- Add custom styling based on level
        if level == vim.log.levels.ERROR then
            opts.icon = " "
            opts.style = "error"
        elseif level == vim.log.levels.WARN then
            opts.icon = " "
            opts.style = "warn"
        elseif level == vim.log.levels.INFO then
            opts.icon = " "
            opts.style = "info"
        end
        
        snacks.notifier.notify(message, level, opts)
    end
    
    -- Override vim.notify to use snacks
    vim.notify = notify_with_style
    
    -- Advanced notification management
    vim.keymap.set("n", "<leader>nc", function()
        snacks.notifier.hide()
        vim.notify("All notifications cleared", vim.log.levels.INFO, { title = "Notifications" })
    end, { desc = "Clear All Notifications" })
    
    vim.keymap.set("n", "<leader>nh", function()
        snacks.notifier.show_history()
    end, { desc = "Show Notification History" })
end

-- ============================================================================
-- PROFILER AND MONITORING SETUP
-- ============================================================================

local function setup_profiler_monitoring()
    local snacks = require("snacks")
    
    -- Advanced profiler commands
    vim.api.nvim_create_user_command("SnacksProfileStart", function()
        snacks.profiler.start()
        vim.notify("Profiler started", vim.log.levels.INFO, { title = "Performance" })
    end, { desc = "Start Snacks profiler" })
    
    vim.api.nvim_create_user_command("SnacksProfileStop", function()
        snacks.profiler.stop()
        vim.notify("Profiler stopped", vim.log.levels.INFO, { title = "Performance" })
    end, { desc = "Stop Snacks profiler" })
    
    vim.api.nvim_create_user_command("SnacksProfileReport", function()
        snacks.profiler.report()
    end, { desc = "Show profiler report" })
    
    -- Startup time monitoring
    vim.api.nvim_create_user_command("SnacksStartupTime", function()
        local start_time = vim.g.start_time or vim.fn.reltime()
        local current_time = vim.fn.reltime()
        local startup_time = vim.fn.reltimestr(vim.fn.reltime(start_time, current_time))
        local startup_ms = tonumber(startup_time) * 1000
        
        vim.notify(string.format("Startup time: %.2fms", startup_ms), 
                 vim.log.levels.INFO, { title = "Performance" })
    end, { desc = "Show startup time" })
end

-- ============================================================================
-- CONDITIONAL LOADING OPTIMIZATIONS
-- ============================================================================

local function setup_conditional_optimizations()
    -- File type based optimizations
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "php", "blade" },
        callback = function()
            if not package.loaded["plugins.lang.php"] then
                require("plugins.lang.php")
            end
        end,
    })
    
    -- Project size based optimizations
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            vim.schedule(function()
                local file_count = vim.fn.system("find . -type f | wc -l 2>/dev/null"):gsub("%s+", "")
                local is_large_project = tonumber(file_count) and tonumber(file_count) > 1000
                
                if is_large_project then
                    vim.notify(string.format("Large project detected (%s files). Some UI plugins disabled for performance.", 
                             file_count), vim.log.levels.INFO, { title = "Performance" })
                    
                    -- Disable heavy features in large projects
                    vim.g.enable_visual_plugins = false
                    vim.g.enable_fun_plugins = false
                end
            end)
        end,
    })
    
    -- Memory usage monitoring
    vim.api.nvim_create_user_command("SnacksMemoryUsage", function()
        local memory_kb = vim.fn.system("ps -o rss= -p " .. vim.fn.getpid()):gsub("%s+", "")
        local memory_mb = tonumber(memory_kb) / 1024
        
        vim.notify(string.format("Memory usage: %.1f MB", memory_mb), 
                 vim.log.levels.INFO, { title = "Performance" })
    end, { desc = "Show memory usage" })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Setup all optimizations when snacks is available
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        local ok, snacks = pcall(require, "snacks")
        if ok then
            setup_advanced_buffer_management()
            setup_advanced_notifications()
            setup_profiler_monitoring()
            setup_conditional_optimizations()
            
            vim.notify("Snacks.nvim optimization loaded", vim.log.levels.INFO, { title = "Optimization" })
        end
    end,
})

return {}