-- ============================================================================
-- CONFIGURATION MIGRATION AND UPGRADE SYSTEM
-- ============================================================================
-- Handles configuration migrations, upgrades, and compatibility management

local M = {}

-- Migration state and configuration
local migration_state = {
    current_version = "2025.01.10",
    last_migration = nil,
    migration_history = {},
    pending_migrations = {},
    backup_created = false,
}

-- Migration registry
local migrations = {}

-- Compatibility matrix
local compatibility = {
    neovim_versions = {
        minimum = "0.9.0",
        recommended = "0.10.0",
        tested = {"0.9.0", "0.9.1", "0.10.0", "0.11.0"},
    },
    plugin_versions = {},
    breaking_changes = {},
}

-- ============================================================================
-- VERSION MANAGEMENT
-- ============================================================================

-- Parse version string
local function parse_version(version_str)
    if not version_str then return nil end
    
    local year, month, day = version_str:match("(%d+)%.(%d+)%.(%d+)")
    if year and month and day then
        return {
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            string = version_str,
        }
    end
    
    -- Fallback for semantic versioning
    local major, minor, patch = version_str:match("(%d+)%.(%d+)%.(%d+)")
    if major and minor and patch then
        return {
            major = tonumber(major),
            minor = tonumber(minor),
            patch = tonumber(patch),
            string = version_str,
        }
    end
    
    return nil
end

-- Compare versions
local function compare_versions(v1, v2)
    local version1 = parse_version(v1)
    local version2 = parse_version(v2)
    
    if not version1 or not version2 then
        return 0 -- Equal if can't parse
    end
    
    -- Date-based comparison
    if version1.year and version2.year then
        if version1.year ~= version2.year then
            return version1.year < version2.year and -1 or 1
        end
        if version1.month ~= version2.month then
            return version1.month < version2.month and -1 or 1
        end
        if version1.day ~= version2.day then
            return version1.day < version2.day and -1 or 1
        end
        return 0
    end
    
    -- Semantic version comparison
    if version1.major and version2.major then
        if version1.major ~= version2.major then
            return version1.major < version2.major and -1 or 1
        end
        if version1.minor ~= version2.minor then
            return version1.minor < version2.minor and -1 or 1
        end
        if version1.patch ~= version2.patch then
            return version1.patch < version2.patch and -1 or 1
        end
        return 0
    end
    
    return 0
end

-- Get current configuration version
local function get_current_version()
    local version_file = vim.fn.stdpath('config') .. '/.nvim_version'
    
    if vim.fn.filereadable(version_file) == 1 then
        local content = vim.fn.readfile(version_file)
        if #content > 0 then
            return content[1]
        end
    end
    
    return nil
end

-- Set configuration version
local function set_current_version(version)
    local version_file = vim.fn.stdpath('config') .. '/.nvim_version'
    vim.fn.writefile({version}, version_file)
end

-- ============================================================================
-- MIGRATION REGISTRY
-- ============================================================================

-- Register migration
function M.register_migration(version, migration_func, description)
    migrations[version] = {
        version = version,
        func = migration_func,
        description = description or "Configuration migration",
        timestamp = os.time(),
    }
end

-- Get pending migrations
local function get_pending_migrations(from_version)
    local pending = {}
    
    for version, migration in pairs(migrations) do
        if not from_version or compare_versions(from_version, version) < 0 then
            table.insert(pending, migration)
        end
    end
    
    -- Sort by version
    table.sort(pending, function(a, b)
        return compare_versions(a.version, b.version) < 0
    end)
    
    return pending
end

-- ============================================================================
-- BACKUP MANAGEMENT
-- ============================================================================

-- Create migration backup
local function create_migration_backup()
    if migration_state.backup_created then
        return true
    end
    
    local backup_dir = vim.fn.stdpath('data') .. '/migration_backups'
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local backup_file = backup_dir .. '/config_backup_' .. timestamp .. '.tar.gz'
    
    vim.fn.mkdir(backup_dir, 'p')
    
    local config_dir = vim.fn.stdpath('config')
    local cmd = string.format('tar -czf %s -C %s .', backup_file, config_dir)
    
    local result = vim.fn.system(cmd)
    if vim.v.shell_error == 0 then
        migration_state.backup_created = true
        vim.notify("Migration backup created: " .. backup_file, vim.log.levels.INFO, { title = "Migration" })
        return true
    else
        vim.notify("Failed to create migration backup: " .. result, vim.log.levels.ERROR, { title = "Migration" })
        return false
    end
end

-- ============================================================================
-- COMPATIBILITY CHECKING
-- ============================================================================

-- Check Neovim version compatibility
local function check_neovim_compatibility()
    local current_version = vim.version()
    local version_str = string.format("%d.%d.%d", current_version.major, current_version.minor, current_version.patch)
    
    local issues = {}
    
    -- Check minimum version
    if compare_versions(version_str, compatibility.neovim_versions.minimum) < 0 then
        table.insert(issues, {
            type = "error",
            message = string.format("Neovim version %s is below minimum required %s", 
                version_str, compatibility.neovim_versions.minimum),
            action = "Please upgrade Neovim to continue"
        })
    end
    
    -- Check if version is tested
    local is_tested = false
    for _, tested_version in ipairs(compatibility.neovim_versions.tested) do
        if version_str == tested_version then
            is_tested = true
            break
        end
    end
    
    if not is_tested then
        table.insert(issues, {
            type = "warning",
            message = string.format("Neovim version %s is not explicitly tested", version_str),
            action = "Configuration may work but hasn't been tested with this version"
        })
    end
    
    return issues
end

-- Check plugin compatibility
local function check_plugin_compatibility()
    local issues = {}
    
    -- Check for known incompatible plugins
    local incompatible_plugins = {
        ["old-plugin"] = "Use new-plugin instead",
        ["deprecated-plugin"] = "This plugin is no longer maintained",
    }
    
    for plugin, message in pairs(incompatible_plugins) do
        local ok, _ = pcall(require, plugin)
        if ok then
            table.insert(issues, {
                type = "warning",
                message = string.format("Incompatible plugin detected: %s", plugin),
                action = message
            })
        end
    end
    
    return issues
end

-- ============================================================================
-- MIGRATION EXECUTION
-- ============================================================================

-- Execute single migration
local function execute_migration(migration)
    vim.notify(string.format("Running migration: %s", migration.description), 
        vim.log.levels.INFO, { title = "Migration" })
    
    local success, result = pcall(migration.func)
    
    if success then
        table.insert(migration_state.migration_history, {
            version = migration.version,
            description = migration.description,
            timestamp = os.time(),
            success = true,
        })
        
        vim.notify(string.format("Migration completed: %s", migration.version), 
            vim.log.levels.INFO, { title = "Migration" })
        return true
    else
        table.insert(migration_state.migration_history, {
            version = migration.version,
            description = migration.description,
            timestamp = os.time(),
            success = false,
            error = tostring(result),
        })
        
        vim.notify(string.format("Migration failed: %s - %s", migration.version, result), 
            vim.log.levels.ERROR, { title = "Migration" })
        return false
    end
end

-- Run all pending migrations
function M.run_migrations(from_version)
    local pending = get_pending_migrations(from_version)
    
    if #pending == 0 then
        vim.notify("No pending migrations", vim.log.levels.INFO, { title = "Migration" })
        return true
    end
    
    vim.notify(string.format("Found %d pending migrations", #pending), 
        vim.log.levels.INFO, { title = "Migration" })
    
    -- Create backup before migrations
    if not create_migration_backup() then
        vim.notify("Migration aborted - backup failed", vim.log.levels.ERROR, { title = "Migration" })
        return false
    end
    
    local success_count = 0
    local total_count = #pending
    
    for _, migration in ipairs(pending) do
        if execute_migration(migration) then
            success_count = success_count + 1
        else
            -- Stop on first failure
            break
        end
    end
    
    local success = success_count == total_count
    
    if success then
        set_current_version(migration_state.current_version)
        vim.notify(string.format("All migrations completed successfully (%d/%d)", 
            success_count, total_count), vim.log.levels.INFO, { title = "Migration" })
    else
        vim.notify(string.format("Migration incomplete (%d/%d successful)", 
            success_count, total_count), vim.log.levels.WARN, { title = "Migration" })
    end
    
    return success
end

-- ============================================================================
-- AUTOMATIC MIGRATION DETECTION
-- ============================================================================

-- Check if migration is needed
function M.check_migration_needed()
    local current_version = get_current_version()
    local target_version = migration_state.current_version
    
    if not current_version then
        -- First time setup
        vim.notify("First time setup detected", vim.log.levels.INFO, { title = "Migration" })
        return true, nil
    end
    
    if compare_versions(current_version, target_version) < 0 then
        vim.notify(string.format("Configuration upgrade available: %s → %s", 
            current_version, target_version), vim.log.levels.INFO, { title = "Migration" })
        return true, current_version
    end
    
    return false, current_version
end

-- ============================================================================
-- PREDEFINED MIGRATIONS
-- ============================================================================

-- Register built-in migrations
local function register_builtin_migrations()
    -- Migration for AI provider consolidation
    M.register_migration("2025.01.10", function()
        -- Check if old AI configurations exist and disable them
        local ai_configs = {
            "lua/plugins/ai/codeium.lua",
            "lua/plugins/ai/mcphub.lua",
        }
        
        for _, config_file in ipairs(ai_configs) do
            local full_path = vim.fn.stdpath('config') .. '/' .. config_file
            if vim.fn.filereadable(full_path) == 1 then
                -- Add disable comment at the top
                local content = vim.fn.readfile(full_path)
                table.insert(content, 1, "-- DISABLED BY MIGRATION: Use unified AI stack instead")
                vim.fn.writefile(content, full_path)
            end
        end
        
        return true
    end, "Consolidate AI provider configurations")
    
    -- Migration for new monitoring systems
    M.register_migration("2025.01.10.1", function()
        -- Ensure new monitoring modules are properly initialized
        local monitoring_modules = {
            "config.performance",
            "config.validation", 
            "config.analytics",
            "config.debug-tools",
        }
        
        for _, module in ipairs(monitoring_modules) do
            local ok, mod = pcall(require, module)
            if ok and mod.setup then
                mod.setup()
            end
        end
        
        return true
    end, "Initialize new monitoring systems")
    
    -- Migration for keymap updates
    M.register_migration("2025.01.10.2", function()
        -- Update which-key configuration with new plugins
        local which_key_ok, which_key = pcall(require, "which-key")
        if which_key_ok then
            -- Add new plugin groups
            which_key.add({
                { "<leader>e", group = "󰙅 Explorer", icon = "󰙅" },
            })
        end
        
        return true
    end, "Update keymap configurations")
end

-- ============================================================================
-- UPGRADE SYSTEM
-- ============================================================================

-- Check for configuration updates
function M.check_for_updates()
    local update_info = {
        current_version = get_current_version() or "unknown",
        latest_version = migration_state.current_version,
        update_available = false,
        breaking_changes = {},
        new_features = {},
    }
    
    local migration_needed, from_version = M.check_migration_needed()
    update_info.update_available = migration_needed
    
    if migration_needed then
        local pending = get_pending_migrations(from_version)
        
        for _, migration in ipairs(pending) do
            table.insert(update_info.new_features, migration.description)
        end
    end
    
    return update_info
end

-- Perform configuration upgrade
function M.upgrade_configuration()
    local migration_needed, from_version = M.check_migration_needed()
    
    if not migration_needed then
        vim.notify("Configuration is already up to date", vim.log.levels.INFO, { title = "Upgrade" })
        return true
    end
    
    -- Check compatibility first
    local compat_issues = {}
    vim.list_extend(compat_issues, check_neovim_compatibility())
    vim.list_extend(compat_issues, check_plugin_compatibility())
    
    -- Show compatibility issues
    if #compat_issues > 0 then
        local error_count = 0
        for _, issue in ipairs(compat_issues) do
            if issue.type == "error" then
                error_count = error_count + 1
            end
            vim.notify(issue.message .. " - " .. issue.action, 
                issue.type == "error" and vim.log.levels.ERROR or vim.log.levels.WARN,
                { title = "Compatibility Check" })
        end
        
        if error_count > 0 then
            vim.notify("Cannot proceed with upgrade due to compatibility issues", 
                vim.log.levels.ERROR, { title = "Upgrade" })
            return false
        end
    end
    
    -- Run migrations
    return M.run_migrations(from_version)
end

-- ============================================================================
-- COMMANDS
-- ============================================================================

-- Setup migration commands
function M.setup_commands()
    vim.api.nvim_create_user_command("MigrationStatus", function()
        local current_version = get_current_version() or "unknown"
        local migration_needed, from_version = M.check_migration_needed()
        
        local report = {
            "=== Migration Status ===",
            string.format("Current Version: %s", current_version),
            string.format("Latest Version: %s", migration_state.current_version),
            string.format("Migration Needed: %s", migration_needed and "Yes" or "No"),
        }
        
        if migration_needed then
            local pending = get_pending_migrations(from_version)
            table.insert(report, string.format("Pending Migrations: %d", #pending))
            
            if #pending > 0 then
                table.insert(report, "")
                table.insert(report, "=== Pending Migrations ===")
                for _, migration in ipairs(pending) do
                    table.insert(report, string.format("• %s: %s", migration.version, migration.description))
                end
            end
        end
        
        vim.notify(table.concat(report, "\n"), vim.log.levels.INFO, { title = "Migration Status" })
    end, { desc = "Show migration status" })
    
    vim.api.nvim_create_user_command("MigrationRun", function()
        M.upgrade_configuration()
    end, { desc = "Run configuration migrations" })
    
    vim.api.nvim_create_user_command("MigrationHistory", function()
        if #migration_state.migration_history == 0 then
            vim.notify("No migration history", vim.log.levels.INFO, { title = "Migration History" })
            return
        end
        
        local report = { "=== Migration History ===" }
        for _, entry in ipairs(migration_state.migration_history) do
            local status = entry.success and "✅" or "❌"
            local timestamp = os.date("%Y-%m-%d %H:%M:%S", entry.timestamp)
            table.insert(report, string.format("%s %s [%s] %s", 
                status, entry.version, timestamp, entry.description))
            
            if not entry.success and entry.error then
                table.insert(report, string.format("   Error: %s", entry.error))
            end
        end
        
        vim.notify(table.concat(report, "\n"), vim.log.levels.INFO, { title = "Migration History" })
    end, { desc = "Show migration history" })
    
    vim.api.nvim_create_user_command("MigrationCheck", function()
        local update_info = M.check_for_updates()
        
        local report = {
            "=== Update Check ===",
            string.format("Current: %s", update_info.current_version),
            string.format("Latest: %s", update_info.latest_version),
            string.format("Update Available: %s", update_info.update_available and "Yes" or "No"),
        }
        
        if #update_info.new_features > 0 then
            table.insert(report, "")
            table.insert(report, "=== New Features ===")
            for _, feature in ipairs(update_info.new_features) do
                table.insert(report, "• " .. feature)
            end
        end
        
        vim.notify(table.concat(report, "\n"), vim.log.levels.INFO, { title = "Update Check" })
    end, { desc = "Check for configuration updates" })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize migration system
function M.setup()
    register_builtin_migrations()
    M.setup_commands()
    
    -- Check for migrations on startup
    vim.defer_fn(function()
        local migration_needed, from_version = M.check_migration_needed()
        
        if migration_needed then
            if from_version then
                vim.notify(string.format("Configuration update available: %s → %s\nRun :MigrationRun to upgrade", 
                    from_version, migration_state.current_version), 
                    vim.log.levels.INFO, { title = "Migration Available" })
            else
                vim.notify("First time setup detected\nRun :MigrationRun to initialize", 
                    vim.log.levels.INFO, { title = "First Time Setup" })
            end
        end
    end, 2000)
    
    vim.notify("Configuration migration system initialized", vim.log.levels.INFO, { title = "Migration" })
end

return M