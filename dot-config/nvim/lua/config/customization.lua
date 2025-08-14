-- ============================================================================
-- ADVANCED CUSTOMIZATION FRAMEWORK
-- ============================================================================
-- Extensible customization system for user-specific configurations

local M = {}

-- Customization state
local customization_state = {
    user_config_loaded = false,
    custom_modules = {},
    hooks = {},
    overrides = {},
    extensions = {},
    themes = {},
}

-- Hook types
local hook_types = {
    "before_init",
    "after_init", 
    "before_plugin_load",
    "after_plugin_load",
    "before_lsp_attach",
    "after_lsp_attach",
    "on_file_open",
    "on_buffer_enter",
    "on_colorscheme_change",
}

-- ============================================================================
-- HOOK SYSTEM
-- ============================================================================

-- Register hook
function M.register_hook(hook_type, callback, priority)
    if not vim.tbl_contains(hook_types, hook_type) then
        vim.notify("Invalid hook type: " .. hook_type, vim.log.levels.ERROR, { title = "Customization" })
        return false
    end
    
    if not customization_state.hooks[hook_type] then
        customization_state.hooks[hook_type] = {}
    end
    
    table.insert(customization_state.hooks[hook_type], {
        callback = callback,
        priority = priority or 50,
        id = #customization_state.hooks[hook_type] + 1,
    })
    
    -- Sort by priority
    table.sort(customization_state.hooks[hook_type], function(a, b)
        return a.priority < b.priority
    end)
    
    return true
end

-- Execute hooks
function M.execute_hooks(hook_type, ...)
    local hooks = customization_state.hooks[hook_type] or {}
    local results = {}
    
    for _, hook in ipairs(hooks) do
        local success, result = pcall(hook.callback, ...)
        if success then
            table.insert(results, result)
        else
            vim.notify(string.format("Hook execution failed (%s): %s", hook_type, result), 
                vim.log.levels.ERROR, { title = "Customization" })
        end
    end
    
    return results
end

-- ============================================================================
-- CONFIGURATION OVERRIDES
-- ============================================================================

-- Register configuration override
function M.register_override(path, value, merge_strategy)
    merge_strategy = merge_strategy or "replace"
    
    customization_state.overrides[path] = {
        value = value,
        merge_strategy = merge_strategy,
        timestamp = os.time(),
    }
end

-- Apply configuration overrides
function M.apply_overrides()
    for path, override in pairs(customization_state.overrides) do
        local success, current_value = pcall(function()
            local keys = vim.split(path, ".", { plain = true })
            local obj = vim.g
            
            for i = 1, #keys - 1 do
                obj = obj[keys[i]]
                if not obj then return nil end
            end
            
            return obj[keys[#keys]]
        end)
        
        if success then
            local new_value = override.value
            
            if override.merge_strategy == "merge" and type(current_value) == "table" and type(new_value) == "table" then
                new_value = vim.tbl_deep_extend("force", current_value, new_value)
            elseif override.merge_strategy == "append" and type(current_value) == "table" and type(new_value) == "table" then
                new_value = vim.list_extend(vim.deepcopy(current_value), new_value)
            end
            
            -- Apply the override
            local keys = vim.split(path, ".", { plain = true })
            local obj = vim.g
            
            for i = 1, #keys - 1 do
                if not obj[keys[i]] then
                    obj[keys[i]] = {}
                end
                obj = obj[keys[i]]
            end
            
            obj[keys[#keys]] = new_value
        end
    end
end

-- ============================================================================
-- CUSTOM MODULES
-- ============================================================================

-- Register custom module
function M.register_module(name, module_config)
    customization_state.custom_modules[name] = {
        config = module_config,
        loaded = false,
        load_time = nil,
        error = nil,
    }
end

-- Load custom module
function M.load_module(name)
    local module_info = customization_state.custom_modules[name]
    if not module_info then
        vim.notify("Custom module not found: " .. name, vim.log.levels.ERROR, { title = "Customization" })
        return false
    end
    
    if module_info.loaded then
        return true
    end
    
    local start_time = vim.loop.hrtime()
    
    local success, result = pcall(function()
        local config = module_info.config
        
        if type(config) == "function" then
            return config()
        elseif type(config) == "string" then
            return require(config)
        elseif type(config) == "table" and config.setup then
            return config.setup()
        else
            return config
        end
    end)
    
    local load_time = (vim.loop.hrtime() - start_time) / 1e6
    
    if success then
        module_info.loaded = true
        module_info.load_time = load_time
        vim.notify(string.format("Custom module loaded: %s (%.2fms)", name, load_time), 
            vim.log.levels.INFO, { title = "Customization" })
        return true
    else
        module_info.error = tostring(result)
        vim.notify(string.format("Failed to load custom module: %s - %s", name, result), 
            vim.log.levels.ERROR, { title = "Customization" })
        return false
    end
end

-- Load all custom modules
function M.load_all_modules()
    local loaded_count = 0
    local total_count = vim.tbl_count(customization_state.custom_modules)
    
    for name, _ in pairs(customization_state.custom_modules) do
        if M.load_module(name) then
            loaded_count = loaded_count + 1
        end
    end
    
    vim.notify(string.format("Custom modules loaded: %d/%d", loaded_count, total_count), 
        vim.log.levels.INFO, { title = "Customization" })
    
    return loaded_count == total_count
end

-- ============================================================================
-- THEME SYSTEM
-- ============================================================================

-- Register custom theme
function M.register_theme(name, theme_config)
    customization_state.themes[name] = {
        name = name,
        config = theme_config,
        applied = false,
    }
end

-- Apply custom theme
function M.apply_theme(name)
    local theme = customization_state.themes[name]
    if not theme then
        vim.notify("Custom theme not found: " .. name, vim.log.levels.ERROR, { title = "Customization" })
        return false
    end
    
    local success, result = pcall(function()
        local config = theme.config
        
        -- Apply colorscheme
        if config.colorscheme then
            vim.cmd.colorscheme(config.colorscheme)
        end
        
        -- Apply highlight groups
        if config.highlights then
            for group, settings in pairs(config.highlights) do
                vim.api.nvim_set_hl(0, group, settings)
            end
        end
        
        -- Apply custom settings
        if config.settings then
            for setting, value in pairs(config.settings) do
                vim.opt[setting] = value
            end
        end
        
        -- Execute custom setup function
        if config.setup and type(config.setup) == "function" then
            config.setup()
        end
        
        return true
    end)
    
    if success then
        -- Mark all themes as not applied
        for _, t in pairs(customization_state.themes) do
            t.applied = false
        end
        
        theme.applied = true
        vim.notify("Custom theme applied: " .. name, vim.log.levels.INFO, { title = "Customization" })
        
        -- Execute theme change hooks
        M.execute_hooks("on_colorscheme_change", name)
        
        return true
    else
        vim.notify(string.format("Failed to apply theme: %s - %s", name, result), 
            vim.log.levels.ERROR, { title = "Customization" })
        return false
    end
end

-- ============================================================================
-- EXTENSION SYSTEM
-- ============================================================================

-- Register extension
function M.register_extension(name, extension_config)
    customization_state.extensions[name] = {
        name = name,
        config = extension_config,
        enabled = false,
        commands = {},
        keymaps = {},
    }
end

-- Enable extension
function M.enable_extension(name)
    local extension = customization_state.extensions[name]
    if not extension then
        vim.notify("Extension not found: " .. name, vim.log.levels.ERROR, { title = "Customization" })
        return false
    end
    
    if extension.enabled then
        return true
    end
    
    local success, result = pcall(function()
        local config = extension.config
        
        -- Setup extension
        if config.setup and type(config.setup) == "function" then
            config.setup()
        end
        
        -- Register commands
        if config.commands then
            for cmd_name, cmd_config in pairs(config.commands) do
                vim.api.nvim_create_user_command(cmd_name, cmd_config.callback, cmd_config.opts or {})
                extension.commands[cmd_name] = cmd_config
            end
        end
        
        -- Register keymaps
        if config.keymaps then
            for _, keymap in ipairs(config.keymaps) do
                vim.keymap.set(keymap.mode or 'n', keymap.lhs, keymap.rhs, keymap.opts or {})
                table.insert(extension.keymaps, keymap)
            end
        end
        
        -- Register autocommands
        if config.autocommands then
            for _, autocmd in ipairs(config.autocommands) do
                vim.api.nvim_create_autocmd(autocmd.event, autocmd.opts)
            end
        end
        
        return true
    end)
    
    if success then
        extension.enabled = true
        vim.notify("Extension enabled: " .. name, vim.log.levels.INFO, { title = "Customization" })
        return true
    else
        vim.notify(string.format("Failed to enable extension: %s - %s", name, result), 
            vim.log.levels.ERROR, { title = "Customization" })
        return false
    end
end

-- Disable extension
function M.disable_extension(name)
    local extension = customization_state.extensions[name]
    if not extension then
        vim.notify("Extension not found: " .. name, vim.log.levels.ERROR, { title = "Customization" })
        return false
    end
    
    if not extension.enabled then
        return true
    end
    
    -- Remove commands
    for cmd_name, _ in pairs(extension.commands) do
        pcall(vim.api.nvim_del_user_command, cmd_name)
    end
    extension.commands = {}
    
    -- Remove keymaps
    for _, keymap in ipairs(extension.keymaps) do
        pcall(vim.keymap.del, keymap.mode or 'n', keymap.lhs)
    end
    extension.keymaps = {}
    
    extension.enabled = false
    vim.notify("Extension disabled: " .. name, vim.log.levels.INFO, { title = "Customization" })
    
    return true
end

-- ============================================================================
-- USER CONFIGURATION LOADING
-- ============================================================================

-- Load user configuration
function M.load_user_config()
    if customization_state.user_config_loaded then
        return true
    end
    
    local user_config_paths = {
        vim.fn.stdpath('config') .. '/lua/user/init.lua',
        vim.fn.stdpath('config') .. '/user.lua',
        vim.fn.expand('~/.config/nvim/user.lua'),
    }
    
    for _, config_path in ipairs(user_config_paths) do
        if vim.fn.filereadable(config_path) == 1 then
            local success, result = pcall(function()
                dofile(config_path)
                return true
            end)
            
            if success then
                customization_state.user_config_loaded = true
                vim.notify("User configuration loaded: " .. config_path, 
                    vim.log.levels.INFO, { title = "Customization" })
                return true
            else
                vim.notify(string.format("Failed to load user config: %s - %s", config_path, result), 
                    vim.log.levels.ERROR, { title = "Customization" })
            end
        end
    end
    
    -- No user config found - create template
    M.create_user_config_template()
    
    return false
end

-- Create user configuration template
function M.create_user_config_template()
    local template_path = vim.fn.stdpath('config') .. '/user.lua'
    
    if vim.fn.filereadable(template_path) == 1 then
        return -- Template already exists
    end
    
    local template_content = {
        "-- ============================================================================",
        "-- USER CONFIGURATION",
        "-- ============================================================================",
        "-- This file is for your personal customizations",
        "-- It will be loaded automatically and is ignored by git",
        "",
        "local customization = require('config.customization')",
        "",
        "-- ============================================================================",
        "-- EXAMPLE CUSTOMIZATIONS",
        "-- ============================================================================",
        "",
        "-- Register a custom hook",
        "-- customization.register_hook('after_init', function()",
        "--     vim.notify('Custom initialization complete!', vim.log.levels.INFO)",
        "-- end)",
        "",
        "-- Register a configuration override",
        "-- customization.register_override('opt.number', true)",
        "-- customization.register_override('opt.relativenumber', true)",
        "",
        "-- Register a custom module",
        "-- customization.register_module('my_module', {",
        "--     setup = function()",
        "--         -- Your custom setup code here",
        "--     end",
        "-- })",
        "",
        "-- Register a custom theme",
        "-- customization.register_theme('my_theme', {",
        "--     colorscheme = 'default',",
        "--     highlights = {",
        "--         Normal = { bg = '#1e1e1e', fg = '#d4d4d4' },",
        "--     },",
        "-- })",
        "",
        "-- Register a custom extension",
        "-- customization.register_extension('my_extension', {",
        "--     setup = function()",
        "--         -- Extension setup code",
        "--     end,",
        "--     commands = {",
        "--         MyCommand = {",
        "--             callback = function()",
        "--                 vim.notify('Hello from custom command!')",
        "--             end,",
        "--             opts = { desc = 'My custom command' }",
        "--         }",
        "--     },",
        "--     keymaps = {",
        "--         { lhs = '<leader>mc', rhs = ':MyCommand<CR>', opts = { desc = 'My custom keymap' } }",
        "--     }",
        "-- })",
        "",
        "-- ============================================================================",
        "-- YOUR CUSTOMIZATIONS",
        "-- ============================================================================",
        "",
        "-- Add your customizations below this line",
        "",
    }
    
    vim.fn.writefile(template_content, template_path)
    vim.notify("User configuration template created: " .. template_path, 
        vim.log.levels.INFO, { title = "Customization" })
end

-- ============================================================================
-- CUSTOMIZATION COMMANDS
-- ============================================================================

-- Setup customization commands
function M.setup_commands()
    vim.api.nvim_create_user_command("CustomizationStatus", function()
        local report = {
            "=== Customization Status ===",
            string.format("User Config Loaded: %s", customization_state.user_config_loaded and "Yes" or "No"),
            string.format("Custom Modules: %d", vim.tbl_count(customization_state.custom_modules)),
            string.format("Registered Hooks: %d", vim.tbl_count(customization_state.hooks)),
            string.format("Configuration Overrides: %d", vim.tbl_count(customization_state.overrides)),
            string.format("Custom Themes: %d", vim.tbl_count(customization_state.themes)),
            string.format("Extensions: %d", vim.tbl_count(customization_state.extensions)),
            "",
        }
        
        -- Show loaded modules
        if vim.tbl_count(customization_state.custom_modules) > 0 then
            table.insert(report, "=== Custom Modules ===")
            for name, module in pairs(customization_state.custom_modules) do
                local status = module.loaded and "✅" or "❌"
                local time = module.load_time and string.format(" (%.2fms)", module.load_time) or ""
                table.insert(report, string.format("%s %s%s", status, name, time))
            end
            table.insert(report, "")
        end
        
        -- Show enabled extensions
        if vim.tbl_count(customization_state.extensions) > 0 then
            table.insert(report, "=== Extensions ===")
            for name, extension in pairs(customization_state.extensions) do
                local status = extension.enabled and "✅" or "❌"
                table.insert(report, string.format("%s %s", status, name))
            end
        end
        
        vim.notify(table.concat(report, "\n"), vim.log.levels.INFO, { title = "Customization Status" })
    end, { desc = "Show customization status" })
    
    vim.api.nvim_create_user_command("CustomizationReload", function()
        customization_state.user_config_loaded = false
        M.load_user_config()
        M.apply_overrides()
        M.load_all_modules()
    end, { desc = "Reload user customizations" })
    
    vim.api.nvim_create_user_command("CustomizationTemplate", function()
        M.create_user_config_template()
    end, { desc = "Create user configuration template" })
    
    vim.api.nvim_create_user_command("CustomizationTheme", function(opts)
        if opts.args == "" then
            local themes = vim.tbl_keys(customization_state.themes)
            if #themes == 0 then
                vim.notify("No custom themes registered", vim.log.levels.INFO, { title = "Customization" })
            else
                vim.notify("Available themes: " .. table.concat(themes, ", "),
                    vim.log.levels.INFO, { title = "Customization" })
            end
        else
            M.apply_theme(opts.args)
        end
    end, {
        nargs = "?",
        desc = "Apply custom theme",
        complete = function()
            return vim.tbl_keys(customization_state.themes)
        end
    })
    
    vim.api.nvim_create_user_command("CustomizationExtension", function(opts)
        local args = vim.split(opts.args, " ", { trimempty = true })
        local action = args[1]
        local name = args[2]
        
        if action == "enable" and name then
            M.enable_extension(name)
        elseif action == "disable" and name then
            M.disable_extension(name)
        elseif action == "list" or not action then
            local extensions = vim.tbl_keys(customization_state.extensions)
            if #extensions == 0 then
                vim.notify("No extensions registered", vim.log.levels.INFO, { title = "Customization" })
            else
                vim.notify("Available extensions: " .. table.concat(extensions, ", "),
                    vim.log.levels.INFO, { title = "Customization" })
            end
        else
            vim.notify("Usage: CustomizationExtension [enable|disable|list] [name]",
                vim.log.levels.INFO, { title = "Customization" })
        end
    end, {
        nargs = "*",
        desc = "Manage custom extensions",
        complete = function(arg_lead, cmd_line, cursor_pos)
            local args = vim.split(cmd_line, " ", { trimempty = true })
            if #args <= 2 then
                return {"enable", "disable", "list"}
            elseif #args == 3 and (args[2] == "enable" or args[2] == "disable") then
                return vim.tbl_keys(customization_state.extensions)
            end
            return {}
        end
    })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize customization system
function M.setup()
    -- Execute before_init hooks
    M.execute_hooks("before_init")
    
    -- Load user configuration
    M.load_user_config()
    
    -- Apply configuration overrides
    M.apply_overrides()
    
    -- Load custom modules
    M.load_all_modules()
    
    -- Setup commands
    M.setup_commands()
    
    -- Execute after_init hooks
    M.execute_hooks("after_init")
    
    vim.notify("Advanced customization framework initialized", vim.log.levels.INFO, { title = "Customization" })
end

-- Public API for user configurations
M.hook = M.register_hook
M.override = M.register_override
M.module = M.register_module
M.theme = M.register_theme
M.extension = M.register_extension

return M