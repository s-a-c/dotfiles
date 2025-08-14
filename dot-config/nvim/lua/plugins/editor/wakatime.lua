-- ============================================================================
-- WAKATIME.NVIM CONFIGURATION
-- ============================================================================
-- Automatic time tracking for development projects

-- Check if wakatime is available and configured
local wakatime_available = vim.fn.executable('wakatime-cli') == 1 or vim.fn.executable('wakatime') == 1

if not wakatime_available then
    -- Silently skip if wakatime is not installed
    vim.notify("Wakatime CLI not found. Install with: pip install wakatime", vim.log.levels.WARN, { title = "Wakatime" })
    return
end

-- Setup wakatime with privacy-focused configuration
require("wakatime").setup({
    -- API key configuration (should be set via environment or wakatime config)
    api_key = nil, -- Will use ~/.wakatime.cfg or environment variable
    
    -- Disable automatic API key prompting
    disable_ssl_verify = false,
    
    -- Project detection
    project_name = function()
        -- Try to get project name from various sources
        local cwd = vim.fn.getcwd()
        local project_name = vim.fn.fnamemodify(cwd, ":t")
        
        -- Check for Laravel project
        if vim.fn.filereadable("artisan") == 1 then
            local composer_json = vim.fn.glob("composer.json")
            if composer_json ~= "" then
                local ok, composer_data = pcall(vim.fn.json_decode, vim.fn.readfile(composer_json))
                if ok and composer_data.name then
                    return composer_data.name
                end
            end
            return project_name .. " (Laravel)"
        end
        
        -- Check for Node.js project
        if vim.fn.filereadable("package.json") == 1 then
            local package_json = vim.fn.glob("package.json")
            if package_json ~= "" then
                local ok, package_data = pcall(vim.fn.json_decode, vim.fn.readfile(package_json))
                if ok and package_data.name then
                    return package_data.name
                end
            end
            return project_name .. " (Node.js)"
        end
        
        -- Check for Git repository
        if vim.fn.isdirectory(".git") == 1 then
            local git_config = vim.fn.glob(".git/config")
            if git_config ~= "" then
                local config_lines = vim.fn.readfile(git_config)
                for _, line in ipairs(config_lines) do
                    local url = line:match("url = (.+)")
                    if url then
                        local repo_name = url:match("([^/]+)%.git$") or url:match("([^/]+)$")
                        if repo_name then
                            return repo_name
                        end
                    end
                end
            end
        end
        
        return project_name
    end,
    
    -- Hide file paths for privacy
    hide_file_names = false,
    hide_project_names = false,
    
    -- Exclude certain file types and directories
    exclude = {
        "COMMIT_EDITMSG",
        "MERGE_MSG",
        "TAG_EDITMSG",
        "*.tmp",
        "*.log",
        "node_modules/*",
        "vendor/*",
        ".git/*",
        "*.min.js",
        "*.min.css",
    },
    
    -- Include only specific file types (optional)
    include = {
        "*.php",
        "*.js",
        "*.ts",
        "*.jsx",
        "*.tsx",
        "*.vue",
        "*.blade.php",
        "*.lua",
        "*.py",
        "*.go",
        "*.rs",
        "*.java",
        "*.c",
        "*.cpp",
        "*.h",
        "*.hpp",
        "*.css",
        "*.scss",
        "*.sass",
        "*.html",
        "*.xml",
        "*.json",
        "*.yaml",
        "*.yml",
        "*.toml",
        "*.md",
        "*.txt",
        "*.sql",
        "*.sh",
        "*.zsh",
        "*.bash",
        "*.fish",
        "*.vim",
        "*.nvim",
    },
    
    -- Heartbeat frequency (in seconds)
    heartbeat_frequency = 120, -- 2 minutes (default is 120)
    
    -- Offline mode support
    offline = true,
    
    -- Debug mode (set to false for production)
    debug = false,
    
    -- Custom user agent
    user_agent = "nvim-wakatime",
    
    -- Timeout for API requests (in seconds)
    timeout = 30,
    
    -- SSL certificate verification
    ssl_certs_file = nil,
    
    -- Proxy settings (if needed)
    proxy = nil,
    
    -- Custom hostname
    hostname = nil,
    
    -- Log file location
    log_file = vim.fn.expand("~/.wakatime.log"),
})

-- ============================================================================
-- WAKATIME AUTOCOMMANDS
-- ============================================================================

-- Create autogroup for wakatime events
local wakatime_group = vim.api.nvim_create_augroup("WakatimeConfig", { clear = true })

-- Track file opens
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = wakatime_group,
    callback = function()
        -- Only track real files, not special buffers
        local buftype = vim.bo.buftype
        local filetype = vim.bo.filetype
        local filename = vim.api.nvim_buf_get_name(0)
        
        if buftype == "" and filename ~= "" and not filename:match("^%w+://") then
            -- Exclude certain filetypes
            local excluded_filetypes = {
                "help",
                "startify",
                "dashboard",
                "packer",
                "neogitstatus",
                "NvimTree",
                "Trouble",
                "alpha",
                "lir",
                "Outline",
                "spectre_panel",
                "toggleterm",
                "DressingSelect",
                "TelescopePrompt",
                "lspinfo",
                "lsp-installer",
                "null-ls-info",
                "quickfix",
                "chadtree",
                "fzf",
                "NeogitStatus",
                "terminal",
            }
            
            for _, ft in ipairs(excluded_filetypes) do
                if filetype == ft then
                    return
                end
            end
            
            -- Send heartbeat for valid files
            vim.schedule(function()
                local ok, wakatime = pcall(require, "wakatime")
                if ok then
                    wakatime.heartbeat({
                        file = filename,
                        time = os.time(),
                        is_write = false,
                    })
                end
            end)
        end
    end,
})

-- Track file saves
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = wakatime_group,
    callback = function()
        local filename = vim.api.nvim_buf_get_name(0)
        if filename ~= "" and not filename:match("^%w+://") then
            vim.schedule(function()
                local ok, wakatime = pcall(require, "wakatime")
                if ok then
                    wakatime.heartbeat({
                        file = filename,
                        time = os.time(),
                        is_write = true,
                    })
                end
            end)
        end
    end,
})

-- Track cursor movement (throttled)
local last_heartbeat = 0
local heartbeat_threshold = 120 -- 2 minutes

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = wakatime_group,
    callback = function()
        local current_time = os.time()
        if current_time - last_heartbeat >= heartbeat_threshold then
            local filename = vim.api.nvim_buf_get_name(0)
            if filename ~= "" and not filename:match("^%w+://") then
                last_heartbeat = current_time
                vim.schedule(function()
                    local ok, wakatime = pcall(require, "wakatime")
                    if ok then
                        wakatime.heartbeat({
                            file = filename,
                            time = current_time,
                            is_write = false,
                        })
                    end
                end)
            end
        end
    end,
})

-- ============================================================================
-- WAKATIME COMMANDS
-- ============================================================================

-- Command to show today's stats
vim.api.nvim_create_user_command("WakatimeToday", function()
    vim.fn.system("wakatime-cli --today")
    local output = vim.fn.system("wakatime-cli --today")
    if vim.v.shell_error == 0 then
        vim.notify(output, vim.log.levels.INFO, { title = "Wakatime Today" })
    else
        vim.notify("Failed to get Wakatime stats", vim.log.levels.ERROR, { title = "Wakatime" })
    end
end, { desc = "Show today's Wakatime stats" })

-- Command to show dashboard URL
vim.api.nvim_create_user_command("WakatimeDashboard", function()
    local url = "https://wakatime.com/dashboard"
    if vim.fn.has("mac") == 1 then
        vim.fn.system("open " .. url)
    elseif vim.fn.has("unix") == 1 then
        vim.fn.system("xdg-open " .. url)
    elseif vim.fn.has("win32") == 1 then
        vim.fn.system("start " .. url)
    end
    vim.notify("Opening Wakatime dashboard...", vim.log.levels.INFO, { title = "Wakatime" })
end, { desc = "Open Wakatime dashboard in browser" })

-- Command to check Wakatime status
vim.api.nvim_create_user_command("WakatimeStatus", function()
    local config_file = vim.fn.expand("~/.wakatime.cfg")
    local log_file = vim.fn.expand("~/.wakatime.log")
    
    local status = {}
    table.insert(status, "Wakatime Status:")
    table.insert(status, "")
    
    -- Check config file
    if vim.fn.filereadable(config_file) == 1 then
        table.insert(status, "✓ Config file found: " .. config_file)
    else
        table.insert(status, "✗ Config file not found: " .. config_file)
    end
    
    -- Check CLI
    if vim.fn.executable("wakatime-cli") == 1 then
        table.insert(status, "✓ Wakatime CLI found")
    elseif vim.fn.executable("wakatime") == 1 then
        table.insert(status, "✓ Wakatime CLI found (legacy)")
    else
        table.insert(status, "✗ Wakatime CLI not found")
    end
    
    -- Check log file
    if vim.fn.filereadable(log_file) == 1 then
        local log_size = vim.fn.getfsize(log_file)
        table.insert(status, "✓ Log file found: " .. log_file .. " (" .. log_size .. " bytes)")
    else
        table.insert(status, "- Log file not found: " .. log_file)
    end
    
    -- Check project detection
    local project_name = require("wakatime").project_name()
    if project_name then
        table.insert(status, "✓ Current project: " .. project_name)
    else
        table.insert(status, "- No project detected")
    end
    
    vim.notify(table.concat(status, "\n"), vim.log.levels.INFO, { title = "Wakatime Status" })
end, { desc = "Check Wakatime configuration and status" })

-- ============================================================================
-- INTEGRATION WITH EXISTING WORKFLOW
-- ============================================================================

-- Integration with project detection
vim.api.nvim_create_autocmd("DirChanged", {
    group = wakatime_group,
    callback = function()
        -- Update project context when changing directories
        vim.schedule(function()
            local ok, wakatime = pcall(require, "wakatime")
            if ok then
                -- Force project re-detection
                local project_name = wakatime.project_name()
                if project_name then
                    vim.g.wakatime_current_project = project_name
                end
            end
        end)
    end,
})

-- Integration with Git for better project detection
vim.api.nvim_create_autocmd("User", {
    pattern = "GitSignsAttach",
    callback = function()
        -- Enhanced project detection when Git is available
        vim.schedule(function()
            local ok, wakatime = pcall(require, "wakatime")
            if ok then
                local project_name = wakatime.project_name()
                if project_name then
                    vim.g.wakatime_current_project = project_name
                end
            end
        end)
    end,
})

-- ============================================================================
-- PRIVACY AND SECURITY
-- ============================================================================

-- Function to toggle sensitive file tracking
_G.wakatime_toggle_privacy = function()
    local current_setting = vim.g.wakatime_hide_filenames or false
    vim.g.wakatime_hide_filenames = not current_setting
    
    local status = vim.g.wakatime_hide_filenames and "enabled" or "disabled"
    vim.notify("Wakatime privacy mode " .. status, vim.log.levels.INFO, { title = "Wakatime" })
end

-- Command to toggle privacy mode
vim.api.nvim_create_user_command("WakatimeTogglePrivacy", function()
    _G.wakatime_toggle_privacy()
end, { desc = "Toggle Wakatime privacy mode" })

-- ============================================================================
-- STATUSLINE INTEGRATION
-- ============================================================================

-- Function to get current project for statusline
_G.wakatime_project = function()
    local project = vim.g.wakatime_current_project
    if project and project ~= "" then
        return " [" .. project .. "]"
    end
    return ""
end

-- Function to show tracking status
_G.wakatime_status = function()
    if wakatime_available then
        local privacy = vim.g.wakatime_hide_filenames and " 🔒" or ""
        return " ⏱️" .. privacy
    end
    return ""
end

-- ============================================================================
-- PERFORMANCE OPTIMIZATION
-- ============================================================================

-- Debounce heartbeats to avoid excessive API calls
local heartbeat_timer = nil
local pending_heartbeat = nil

local function send_heartbeat_debounced(data)
    if heartbeat_timer then
        vim.fn.timer_stop(heartbeat_timer)
    end
    
    pending_heartbeat = data
    heartbeat_timer = vim.fn.timer_start(1000, function() -- 1 second debounce
        if pending_heartbeat then
            local ok, wakatime = pcall(require, "wakatime")
            if ok then
                wakatime.heartbeat(pending_heartbeat)
            end
            pending_heartbeat = nil
        end
        heartbeat_timer = nil
    end)
end

-- Override default heartbeat function with debounced version
if wakatime_available then
    local ok, wakatime = pcall(require, "wakatime")
    if ok and wakatime.heartbeat then
        local original_heartbeat = wakatime.heartbeat
        wakatime.heartbeat = function(data)
            send_heartbeat_debounced(data)
        end
    end
end

-- ============================================================================
-- INITIALIZATION MESSAGE
-- ============================================================================

-- Show initialization status
vim.schedule(function()
    if wakatime_available then
        local config_file = vim.fn.expand("~/.wakatime.cfg")
        if vim.fn.filereadable(config_file) == 1 then
            vim.notify("Wakatime tracking enabled", vim.log.levels.INFO, { title = "Wakatime" })
        else
            vim.notify("Wakatime CLI found but not configured. Run 'wakatime --config' to setup.", vim.log.levels.WARN, { title = "Wakatime" })
        end
    end
end)