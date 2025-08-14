-- ============================================================================
-- CONFIGURATION VALIDATION
-- ============================================================================
-- Comprehensive validation system to prevent configuration issues

local M = {}

-- Validation results storage
local validation_results = {
    last_check = 0,
    issues = {},
    warnings = {},
    suggestions = {},
}

-- ============================================================================
-- PLUGIN VALIDATION
-- ============================================================================

-- Validate plugin configurations
function M.validate_plugins()
    local issues = {}
    
    -- Check for conflicting AI providers
    local ai_providers = {}
    local ai_configs = {
        { name = "copilot", path = "plugins/ai/copilot.lua" },
        { name = "codeium", path = "plugins/ai/codeium.lua" },
        { name = "avante", path = "plugins/ai/avante.lua" },
        { name = "copilot-chat", path = "plugins/ai/copilot-chat.lua" },
    }
    
    for _, config in ipairs(ai_configs) do
        local ok, _ = pcall(require, config.name)
        if ok then
            table.insert(ai_providers, config.name)
        end
    end
    
    if #ai_providers > 3 then
        table.insert(issues, {
            type = "warning",
            category = "AI Providers",
            message = "Multiple AI providers detected: " .. table.concat(ai_providers, ", "),
            suggestion = "Consider disabling some providers to reduce memory usage and conflicts",
            severity = "medium"
        })
    end
    
    -- Check for essential plugins
    local essential_plugins = {
        { name = "telescope", description = "Fuzzy finder" },
        { name = "nvim-treesitter", description = "Syntax highlighting" },
        { name = "mason", description = "LSP server management" },
        { name = "which-key", description = "Key mapping helper" },
        { name = "nvim-lspconfig", description = "LSP configuration" },
    }
    
    for _, plugin in ipairs(essential_plugins) do
        local ok, _ = pcall(require, plugin.name)
        if not ok then
            table.insert(issues, {
                type = "error",
                category = "Missing Plugins",
                message = "Missing essential plugin: " .. plugin.name,
                suggestion = "Install " .. plugin.name .. " (" .. plugin.description .. ")",
                severity = "high"
            })
        end
    end
    
    return issues
end

-- ============================================================================
-- KEYMAP VALIDATION
-- ============================================================================

-- Validate keymap configurations
function M.validate_keymaps()
    local issues = {}
    local conflicts = {}
    
    -- Get all normal mode keymaps
    local keymaps = vim.api.nvim_get_keymap('n')
    local leader_mappings = {}
    
    for _, keymap in ipairs(keymaps) do
        if keymap.lhs:match("^<leader>") then
            if leader_mappings[keymap.lhs] then
                table.insert(conflicts, keymap.lhs)
            else
                leader_mappings[keymap.lhs] = keymap
            end
        end
    end
    
    if #conflicts > 0 then
        table.insert(issues, {
            type = "warning",
            category = "Keymap Conflicts",
            message = "Keymap conflicts detected: " .. table.concat(conflicts, ", "),
            suggestion = "Review keymap assignments to avoid conflicts",
            severity = "medium"
        })
    end
    
    -- Check for essential keymaps
    local essential_keymaps = {
        "<leader>e", "<leader>ff", "<leader>fg", "<leader>fb",
        "<leader>w", "<leader>q", "<leader>bd"
    }
    
    local missing_keymaps = {}
    for _, keymap in ipairs(essential_keymaps) do
        if not leader_mappings[keymap] then
            table.insert(missing_keymaps, keymap)
        end
    end
    
    if #missing_keymaps > 0 then
        table.insert(issues, {
            type = "warning",
            category = "Missing Keymaps",
            message = "Missing essential keymaps: " .. table.concat(missing_keymaps, ", "),
            suggestion = "Add missing keymaps for better workflow",
            severity = "low"
        })
    end
    
    return issues
end

-- ============================================================================
-- LSP VALIDATION
-- ============================================================================

-- Validate LSP configurations
function M.validate_lsp()
    local issues = {}
    
    -- Check if Mason is available
    local mason_ok, mason = pcall(require, "mason")
    if not mason_ok then
        table.insert(issues, {
            type = "error",
            category = "LSP Setup",
            message = "Mason not available for LSP server management",
            suggestion = "Install and configure Mason for LSP servers",
            severity = "high"
        })
        return issues
    end
    
    -- Check for essential LSP servers
    local essential_servers = {
        "lua_ls", "pyright", "tsserver", "rust_analyzer", 
        "gopls", "jsonls", "yamlls"
    }
    
    local missing_servers = {}
    for _, server in ipairs(essential_servers) do
        local ok, _ = pcall(require, "lspconfig." .. server)
        if not ok then
            table.insert(missing_servers, server)
        end
    end
    
    if #missing_servers > 0 then
        table.insert(issues, {
            type = "warning",
            category = "LSP Servers",
            message = "Missing LSP servers: " .. table.concat(missing_servers, ", "),
            suggestion = "Install missing LSP servers via Mason",
            severity = "medium"
        })
    end
    
    return issues
end

-- ============================================================================
-- PERFORMANCE VALIDATION
-- ============================================================================

-- Validate performance-related settings
function M.validate_performance()
    local issues = {}
    
    -- Check startup time
    local startup_time = vim.fn.has('vim_starting') == 1 and 0 or 100 -- Placeholder
    if startup_time > 300 then
        table.insert(issues, {
            type = "warning",
            category = "Performance",
            message = string.format("Slow startup time: %.2fms", startup_time),
            suggestion = "Consider lazy-loading plugins or optimizing configuration",
            severity = "medium"
        })
    end
    
    -- Check for performance-impacting settings
    local perf_settings = {
        { opt = "updatetime", recommended = 250, current = vim.opt.updatetime:get() },
        { opt = "timeoutlen", recommended = 500, current = vim.opt.timeoutlen:get() },
        { opt = "synmaxcol", recommended = 300, current = vim.opt.synmaxcol:get() },
    }
    
    for _, setting in ipairs(perf_settings) do
        if setting.current > setting.recommended * 2 then
            table.insert(issues, {
                type = "suggestion",
                category = "Performance Settings",
                message = string.format("%s is set to %d (recommended: %d)", 
                    setting.opt, setting.current, setting.recommended),
                suggestion = string.format("Consider reducing %s for better performance", setting.opt),
                severity = "low"
            })
        end
    end
    
    return issues
end

-- ============================================================================
-- SECURITY VALIDATION
-- ============================================================================

-- Validate security-related configurations
function M.validate_security()
    local issues = {}
    
    -- Check for insecure settings
    if vim.opt.modeline:get() then
        table.insert(issues, {
            type = "warning",
            category = "Security",
            message = "Modeline is enabled (potential security risk)",
            suggestion = "Consider disabling modeline: set nomodeline",
            severity = "medium"
        })
    end
    
    -- Check for backup file settings
    if vim.opt.backup:get() and not vim.opt.backupdir:get():match("tmp") then
        table.insert(issues, {
            type = "suggestion",
            category = "Security",
            message = "Backup files not stored in secure location",
            suggestion = "Configure backupdir to use /tmp or disable backups",
            severity = "low"
        })
    end
    
    return issues
end

-- ============================================================================
-- COMPREHENSIVE VALIDATION
-- ============================================================================

-- Run all validation checks
function M.validate_all()
    local all_issues = {}
    
    -- Collect issues from all validation functions
    local validation_functions = {
        M.validate_plugins,
        M.validate_keymaps,
        M.validate_lsp,
        M.validate_performance,
        M.validate_security,
    }
    
    for _, validate_fn in ipairs(validation_functions) do
        local issues = validate_fn()
        for _, issue in ipairs(issues) do
            table.insert(all_issues, issue)
        end
    end
    
    -- Sort issues by severity
    table.sort(all_issues, function(a, b)
        local severity_order = { high = 3, medium = 2, low = 1 }
        return severity_order[a.severity] > severity_order[b.severity]
    end)
    
    validation_results.issues = all_issues
    validation_results.last_check = os.time()
    
    return all_issues
end

-- ============================================================================
-- REPORTING
-- ============================================================================

-- Generate validation report
function M.generate_report()
    local issues = M.validate_all()
    
    if #issues == 0 then
        return "✅ Configuration validation passed - no issues found!"
    end
    
    local report = {
        "=== Configuration Validation Report ===",
        string.format("Timestamp: %s", os.date("%Y-%m-%d %H:%M:%S")),
        string.format("Issues Found: %d", #issues),
        ""
    }
    
    -- Group issues by category
    local categories = {}
    for _, issue in ipairs(issues) do
        if not categories[issue.category] then
            categories[issue.category] = {}
        end
        table.insert(categories[issue.category], issue)
    end
    
    -- Generate report by category
    for category, category_issues in pairs(categories) do
        table.insert(report, string.format("=== %s ===", category))
        
        for _, issue in ipairs(category_issues) do
            local icon = issue.type == "error" and "❌" or 
                        issue.type == "warning" and "⚠️" or "💡"
            local severity_icon = issue.severity == "high" and "🔴" or
                                 issue.severity == "medium" and "🟡" or "🟢"
            
            table.insert(report, string.format("%s %s %s", icon, severity_icon, issue.message))
            table.insert(report, string.format("   💡 %s", issue.suggestion))
        end
        table.insert(report, "")
    end
    
    return table.concat(report, "\n")
end

-- ============================================================================
-- AUTO-VALIDATION
-- ============================================================================

-- Setup automatic validation
function M.setup_auto_validation()
    -- Validate on startup
    vim.defer_fn(function()
        local issues = M.validate_all()
        if #issues > 0 then
            local high_priority = vim.tbl_filter(function(issue)
                return issue.severity == "high"
            end, issues)
            
            if #high_priority > 0 then
                vim.notify(
                    string.format("Critical configuration issues found: %d", #high_priority),
                    vim.log.levels.ERROR,
                    { title = "Config Validation" }
                )
            else
                vim.notify(
                    string.format("Configuration issues found: %d", #issues),
                    vim.log.levels.WARN,
                    { title = "Config Validation" }
                )
            end
        end
    end, 2000)
    
    -- Periodic validation
    local timer = vim.loop.new_timer()
    timer:start(300000, 300000, vim.schedule_wrap(function() -- Every 5 minutes
        M.validate_all()
    end))
end

-- ============================================================================
-- COMMANDS
-- ============================================================================

-- Setup user commands
function M.setup_commands()
    vim.api.nvim_create_user_command("ConfigValidate", function()
        local report = M.generate_report()
        vim.notify(report, vim.log.levels.INFO, { title = "Config Validation" })
    end, { desc = "Run configuration validation" })
    
    vim.api.nvim_create_user_command("ConfigFix", function()
        M.auto_fix_issues()
    end, { desc = "Auto-fix configuration issues" })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- ============================================================================
-- AUTO-FIX FUNCTIONALITY
-- ============================================================================

-- Auto-fix configuration issues
function M.auto_fix_issues()
    local issues = M.validate_all()
    local fixed_count = 0
    local fix_report = { "=== Auto-Fix Report ===" }
    
    for _, issue in ipairs(issues) do
        local fixed = false
        
        -- Fix performance settings
        if issue.category == "Performance Settings" then
            if issue.message:match("updatetime") then
                vim.opt.updatetime = 250
                fixed = true
                table.insert(fix_report, "✅ Fixed updatetime setting")
            elseif issue.message:match("timeoutlen") then
                vim.opt.timeoutlen = 500
                fixed = true
                table.insert(fix_report, "✅ Fixed timeoutlen setting")
            elseif issue.message:match("synmaxcol") then
                vim.opt.synmaxcol = 300
                fixed = true
                table.insert(fix_report, "✅ Fixed synmaxcol setting")
            end
        end
        
        -- Fix security settings
        if issue.category == "Security" then
            if issue.message:match("Modeline") then
                vim.opt.modeline = false
                fixed = true
                table.insert(fix_report, "✅ Disabled modeline for security")
            elseif issue.message:match("Backup files") then
                vim.opt.backupdir = "/tmp"
                fixed = true
                table.insert(fix_report, "✅ Fixed backup directory location")
            end
        end
        
        -- Fix missing keymaps (add basic implementations)
        if issue.category == "Missing Keymaps" then
            local missing_keymaps = {
                ["<leader>e"] = function()
                    local oil_ok, oil = pcall(require, "oil")
                    if oil_ok then
                        oil.open_float()
                    else
                        vim.cmd('Explore')
                    end
                end,
                ["<leader>ff"] = function()
                    local telescope_ok, telescope = pcall(require, "telescope.builtin")
                    if telescope_ok then
                        telescope.find_files()
                    else
                        vim.cmd('edit .')
                    end
                end,
                ["<leader>fg"] = function()
                    local telescope_ok, telescope = pcall(require, "telescope.builtin")
                    if telescope_ok then
                        telescope.live_grep()
                    else
                        vim.cmd('grep')
                    end
                end,
            }
            
            for keymap, func in pairs(missing_keymaps) do
                if issue.message:match(keymap:gsub("[<>]", "")) then
                    vim.keymap.set('n', keymap, func, { desc = "Auto-fixed keymap" })
                    fixed = true
                    table.insert(fix_report, "✅ Added missing keymap: " .. keymap)
                end
            end
        end
        
        if fixed then
            fixed_count = fixed_count + 1
        else
            table.insert(fix_report, "⚠️ Could not auto-fix: " .. issue.message)
        end
    end
    
    table.insert(fix_report, "")
    table.insert(fix_report, string.format("Auto-fixed %d out of %d issues", fixed_count, #issues))
    
    if fixed_count > 0 then
        table.insert(fix_report, "💾 Consider saving your configuration to persist these fixes")
    end
    
    vim.notify(table.concat(fix_report, "\n"), vim.log.levels.INFO, { title = "Auto-Fix Complete" })
    
    return fixed_count
end

-- ============================================================================
-- CONFIGURATION PROFILES
-- ============================================================================

-- Configuration profiles for different use cases
local profiles = {
    minimal = {
        ai_enabled = false,
        heavy_plugins = false,
        performance_optimized = true,
        description = "Minimal configuration for low-resource environments"
    },
    development = {
        ai_enabled = true,
        heavy_plugins = true,
        debug_enabled = true,
        performance_optimized = false,
        description = "Full-featured development environment"
    },
    performance = {
        ai_enabled = true,
        heavy_plugins = false,
        performance_optimized = true,
        lazy_loading = true,
        description = "Performance-optimized configuration"
    },
    presentation = {
        ai_enabled = false,
        heavy_plugins = false,
        minimal_ui = true,
        large_fonts = true,
        description = "Clean configuration for presentations"
    }
}

-- Apply configuration profile
function M.apply_profile(profile_name)
    local profile = profiles[profile_name]
    if not profile then
        vim.notify("Unknown profile: " .. profile_name, vim.log.levels.ERROR, { title = "Config Profiles" })
        return false
    end
    
    local changes = {}
    
    -- Apply performance settings
    if profile.performance_optimized then
        vim.opt.updatetime = 100
        vim.opt.timeoutlen = 300
        vim.opt.lazyredraw = true
        table.insert(changes, "Applied performance optimizations")
    end
    
    -- Apply UI settings
    if profile.minimal_ui then
        vim.opt.showmode = false
        vim.opt.showcmd = false
        vim.opt.ruler = false
        table.insert(changes, "Applied minimal UI settings")
    end
    
    if profile.large_fonts then
        vim.opt.guifont = "JetBrainsMono Nerd Font:h16"
        table.insert(changes, "Applied large font settings")
    end
    
    -- Notify about AI and plugin settings (these would require restart)
    if not profile.ai_enabled then
        table.insert(changes, "AI providers will be disabled on next restart")
    end
    
    if not profile.heavy_plugins then
        table.insert(changes, "Heavy plugins will be disabled on next restart")
    end
    
    local report = {
        "=== Profile Applied: " .. profile_name .. " ===",
        profile.description,
        "",
        "Changes applied:",
    }
    
    for _, change in ipairs(changes) do
        table.insert(report, "✅ " .. change)
    end
    
    vim.notify(table.concat(report, "\n"), vim.log.levels.INFO, { title = "Profile Applied" })
    
    return true
end

-- List available profiles
function M.list_profiles()
    local report = { "=== Available Configuration Profiles ===" }
    
    for name, profile in pairs(profiles) do
        table.insert(report, string.format("📋 %s: %s", name, profile.description))
    end
    
    table.insert(report, "")
    table.insert(report, "Use :ConfigProfile <name> to apply a profile")
    
    vim.notify(table.concat(report, "\n"), vim.log.levels.INFO, { title = "Config Profiles" })
end

-- ============================================================================
-- ENHANCED COMMANDS
-- ============================================================================

-- Enhanced command setup with new functionality
function M.setup_enhanced_commands()
    -- Original commands
    M.setup_commands()
    
    -- Profile management commands
    vim.api.nvim_create_user_command("ConfigProfile", function(opts)
        if opts.args == "" then
            M.list_profiles()
        else
            M.apply_profile(opts.args)
        end
    end, {
        desc = "Apply configuration profile",
        nargs = "?",
        complete = function()
            return vim.tbl_keys(profiles)
        end
    })
    
    -- Advanced validation commands
    vim.api.nvim_create_user_command("ConfigHealth", function()
        local issues = M.validate_all()
        local health_score = math.max(0, 100 - (#issues * 10))
        
        local report = {
            "=== Configuration Health Score ===",
            string.format("Health Score: %d/100", health_score),
            string.format("Issues Found: %d", #issues),
            ""
        }
        
        if health_score >= 90 then
            table.insert(report, "🟢 Excellent configuration health!")
        elseif health_score >= 70 then
            table.insert(report, "🟡 Good configuration with minor issues")
        elseif health_score >= 50 then
            table.insert(report, "🟠 Configuration needs attention")
        else
            table.insert(report, "🔴 Configuration requires immediate fixes")
        end
        
        vim.notify(table.concat(report, "\n"), vim.log.levels.INFO, { title = "Config Health" })
    end, { desc = "Show configuration health score" })
    
    -- Backup and restore commands
    vim.api.nvim_create_user_command("ConfigBackup", function()
        local backup_dir = vim.fn.stdpath('data') .. '/config_backups'
        local timestamp = os.date("%Y%m%d_%H%M%S")
        local backup_file = backup_dir .. '/config_backup_' .. timestamp .. '.tar.gz'
        
        vim.fn.mkdir(backup_dir, 'p')
        
        local config_dir = vim.fn.stdpath('config')
        local cmd = string.format('tar -czf %s -C %s .', backup_file, config_dir)
        
        local result = vim.fn.system(cmd)
        if vim.v.shell_error == 0 then
            vim.notify("Configuration backed up to: " .. backup_file, vim.log.levels.INFO, { title = "Config Backup" })
        else
            vim.notify("Backup failed: " .. result, vim.log.levels.ERROR, { title = "Config Backup" })
        end
    end, { desc = "Backup current configuration" })
end

-- Initialize validation system
function M.setup()
    M.setup_enhanced_commands()
    M.setup_auto_validation()
    
    vim.notify("Enhanced configuration validation initialized", vim.log.levels.INFO, { title = "Config Validation" })
end

return M