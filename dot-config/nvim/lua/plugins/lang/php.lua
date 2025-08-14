-- ============================================================================
-- PHP & LARAVEL LANGUAGE CONFIGURATION
-- ============================================================================
-- PHP language server and Laravel-specific tooling
-- Blade-nav conditionally loads only in Laravel projects

-- ============================================================================
-- LARAVEL PROJECT DETECTION FUNCTIONS
-- ============================================================================

--- Check if current directory is a Laravel project
--- @return boolean
local function is_laravel_project()
    local indicators = {
        "artisan",                     -- Laravel artisan command
        "composer.json",         -- Composer file (check content for Laravel)
        "config/app.php",        -- Laravel config directory
        "routes/web.php",        -- Laravel routes
        "app/Http/Kernel.php", -- Laravel HTTP kernel
        "bootstrap/app.php", -- Laravel bootstrap
        "resources/views",     -- Blade views directory
    }

    local cwd = vim.fn.getcwd()

    -- Check for direct Laravel indicators
    for _, indicator in ipairs(indicators) do
        local path = cwd .. "/" .. indicator
        if vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1 then
            -- Additional check for composer.json to ensure it's actually Laravel
            if indicator == "composer.json" then
                local composer_file = vim.fn.readfile(path)
                local composer_content = table.concat(composer_file, "\n")
                if string.match(composer_content, "laravel/framework") then
                    return true
                end
            else
                return true
            end
        end
    end

    return false
end

--- Check if file is Laravel/Blade related
--- @param filepath string
--- @return boolean
local function is_laravel_file(filepath)
    if not filepath then
        return false
    end

    -- Check file extensions
    local laravel_extensions = {
        "%.blade%.php$",
        "%.php$",
    }

    for _, pattern in ipairs(laravel_extensions) do
        if string.match(filepath, pattern) then
            return true
        end
    end

    -- Check if file is in Laravel-specific directories
    local laravel_directories = {
        "/app/",
        "/resources/views/",
        "/routes/",
        "/config/",
        "/database/",
        "/tests/",
        "/bootstrap/",
        "/public/",
    }

    for _, dir in ipairs(laravel_directories) do
        if string.match(filepath, dir) then
            return true
        end
    end

    return false
end

--- Determine if blade-nav should be enabled
--- @return boolean
local function should_enable_blade_nav()
    -- Check if we're in a Laravel project
    if is_laravel_project() then
        return true
    end

    -- Check if current buffer is a Laravel file
    local current_file = vim.fn.expand("%:p")
    if current_file and current_file ~= "" then
        if is_laravel_file(current_file) then
            return true
        end
    end

    return false
end

-- ============================================================================
-- CONDITIONAL BLADE-NAV LOADING
-- ============================================================================

local function setup_blade_nav()
    -- Only set up if we should enable blade-nav
    if not should_enable_blade_nav() then
        vim.notify("Blade-nav: Not in Laravel project, skipping setup", vim.log.levels.DEBUG)
        return false
    end

    -- Try to load blade-nav plugin
    local blade_nav_ok = pcall(vim.cmd, 'packadd blade-nav.nvim')
    if not blade_nav_ok then
        vim.notify("blade-nav.nvim package not found", vim.log.levels.WARN)
        return false
    end

    -- Try to require and setup blade-nav
    local ok, blade_nav = pcall(require, "blade-nav")
    if not ok then
        vim.notify("blade-nav.nvim not properly installed", vim.log.levels.ERROR)
        return false
    end

    -- ========================================================================
    -- BLADE-NAV SETUP
    -- ========================================================================
    blade_nav.setup({
        -- ======================================================================
        -- CLOSE TAG ON COMPLETION
        -- ======================================================================
        close_tag_on_complete = true,
    })

    -- ========================================================================
    -- BLADE-NAV KEYMAPS (Laravel Projects Only)
    -- ========================================================================
    local keymap = vim.keymap.set

    -- Navigation keymaps
    keymap('n', '<leader>lv', '<cmd>BladeNavViewsFromConfig<cr>', { desc = 'Blade Views from Config' })
    keymap('n', '<leader>lc', '<cmd>BladeNavComponents<cr>', { desc = 'Blade Components' })
    keymap('n', '<leader>la', '<cmd>BladeNavActions<cr>', { desc = 'Laravel Actions' })
    keymap('n', '<leader>lm', '<cmd>BladeNavModels<cr>', { desc = 'Laravel Models' })
    keymap('n', '<leader>lr', '<cmd>BladeNavRoutes<cr>', { desc = 'Laravel Routes' })

    -- Quick navigation
    keymap('n', 'gbc', '<cmd>BladeNavToComponent<cr>', { desc = 'Go to Blade Component' })
    keymap('n', 'gbb', '<cmd>BladeNavBack<cr>', { desc = 'Blade Nav Back' })

    -- ========================================================================
    -- WHICH-KEY INTEGRATION (Laravel Projects Only)
    -- ========================================================================
    local ok_wk, wk = pcall(require, "which-key")
    if ok_wk then
        wk.add({
            { "<leader>l",    group = "Laravel" },
            { "<leader>lv", desc = "Views from Config" },
            { "<leader>lc", desc = "Components" },
            { "<leader>la", desc = "Actions" },
            { "<leader>lm", desc = "Models" },
            { "<leader>lr", desc = "Routes" },
            { "gb",                 group = "Blade Navigation" },
            { "gbc",                desc = "Go to Component" },
            { "gbb",                desc = "Navigate Back" },
        })
    end

    vim.notify("Blade-nav configured for Laravel project", vim.log.levels.INFO)
    vim.g.blade_nav_loaded = true
    return true
end

-- ============================================================================
-- PHP LANGUAGE SERVER SETUP
-- ============================================================================

local function setup_php_lsp()
    -- PHP LSP configuration is typically handled in your LSP config
    -- This is just a placeholder for PHP-specific LSP settings
    vim.notify("PHP language support loaded", vim.log.levels.DEBUG)
end

-- ============================================================================
-- AUTOCOMMANDS FOR CONDITIONAL LOADING
-- ============================================================================

local augroup = vim.api.nvim_create_augroup("PHPLaravelSupport", { clear = true })

-- Auto-detect Laravel projects and files
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = augroup,
    pattern = { "*.blade.php", "*.php" },
    callback = function()
        local current_file = vim.fn.expand("%:p")

        -- Set appropriate filetype
        if vim.fn.expand("%:e") == "php" then
            if string.match(current_file, "%.blade%.php$") then
                vim.bo.filetype = "blade"
            else
                vim.bo.filetype = "php"
            end
        end

        -- Check if this is a Laravel file and blade-nav should be loaded
        if is_laravel_file(current_file) or is_laravel_project() then
            vim.b.is_laravel_file = true

            -- Load blade-nav if not already loaded
            if not vim.g.blade_nav_loaded then
                local success = setup_blade_nav()
                if success then
                    -- Show notification for first Laravel file in session
                    if not vim.g.laravel_session_notified then
                        vim.notify("Laravel environment detected - Blade-nav activated", vim.log.levels.INFO)
                        vim.g.laravel_session_notified = true
                    end
                end
            end
        end
    end,
})

-- Detect Laravel projects when changing directories
vim.api.nvim_create_autocmd({ "DirChanged", "VimEnter" }, {
    group = augroup,
    callback = function()
        if is_laravel_project() then
            vim.g.is_laravel_project = true

            -- Load blade-nav if not already loaded
            if not vim.g.blade_nav_loaded then
                setup_blade_nav()
            end
        else
            vim.g.is_laravel_project = false
        end
    end,
})

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Always set up PHP language support
setup_php_lsp()

-- Check if we're already in a Laravel project on startup
if should_enable_blade_nav() then
    vim.defer_fn(function()
        setup_blade_nav()
    end, 100) -- Small delay to ensure everything is loaded
end

-- ============================================================================
-- USER COMMANDS FOR MANUAL CONTROL
-- ============================================================================

-- Command to manually enable/disable blade-nav
vim.api.nvim_create_user_command('BladeNavToggle', function()
    if vim.g.blade_nav_loaded then
        vim.notify("Blade-nav is already loaded", vim.log.levels.INFO)
    else
        local success = setup_blade_nav()
        if success then
            vim.notify("Blade-nav loaded manually", vim.log.levels.INFO)
        else
            vim.notify("Failed to load Blade-nav", vim.log.levels.ERROR)
        end
    end
end, { desc = 'Toggle Blade-nav loading' })

-- Command to check Laravel project status
vim.api.nvim_create_user_command('LaravelStatus', function()
    local is_laravel = is_laravel_project()
    local current_file = vim.fn.expand("%:p")
    local is_laravel_file_current = is_laravel_file(current_file)

    vim.notify(string.format(
        "Laravel Project: %s\nCurrent file is Laravel file: %s\nBlade-nav loaded: %s",
        is_laravel and "Yes" or "No",
        is_laravel_file_current and "Yes" or "No",
        vim.g.blade_nav_loaded and "Yes" or "No"
    ), vim.log.levels.INFO)
end, { desc = 'Check Laravel project status' })

vim.notify("PHP/Laravel configuration loaded (blade-nav conditional)", vim.log.levels.DEBUG)
