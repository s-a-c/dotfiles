-- ============================================================================
-- CONFORM.NVIM CONFIGURATION
-- ============================================================================
-- Code formatting configuration using conform.nvim

local conform = require("conform")

-- ============================================================================
-- CONFORM SETUP
-- ============================================================================

conform.setup({
    -- Map of filetype to formatters
    formatters_by_ft = {
        -- Lua
        lua = { "stylua" },
        
        -- JavaScript/TypeScript
        javascript = { "biome", "prettier" },
        typescript = { "biome", "prettier" },
        javascriptreact = { "biome", "prettier" },
        typescriptreact = { "biome", "prettier" },
        
        -- Web technologies
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        sass = { "prettier" },
        less = { "prettier" },
        json = { "biome", "prettier" },
        jsonc = { "biome", "prettier" },
        yaml = { "prettier" },
        yml = { "prettier" },
        
        -- Markdown
        markdown = { "prettier" },
        
        -- PHP
        php = { "php_cs_fixer", "pint" },
        
        -- Python
        python = { "isort", "black" },
        
        -- Rust
        rust = { "rustfmt" },
        
        -- Go
        go = { "gofmt", "goimports" },
        
        -- Shell
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        
        -- XML
        xml = { "xmlformatter" },
        
        -- SQL
        sql = { "sqlformat" },
        
        -- Dockerfile
        dockerfile = { "dockerfilelint" },
        
        -- TOML
        toml = { "taplo" },
        
        -- C/C++
        c = { "clang_format" },
        cpp = { "clang_format" },
        
        -- Java
        java = { "google_java_format" },
        
        -- Swift
        swift = { "swift_format" },
        
        -- Kotlin
        kotlin = { "ktlint" },
        
        -- Dart
        dart = { "dart_format" },
        
        -- Ruby
        ruby = { "rubocop" },
        
        -- Elixir
        elixir = { "mix" },
        
        -- Haskell
        haskell = { "ormolu" },
        
        -- Nix
        nix = { "nixfmt" },
        
        -- Terraform
        terraform = { "terraform_fmt" },
        hcl = { "terraform_fmt" },
        
        -- Protocol Buffers
        proto = { "buf" },
        
        -- GraphQL
        graphql = { "prettier" },
        
        -- Vue
        vue = { "prettier" },
        
        -- Svelte
        svelte = { "prettier" },
        
        -- Astro
        astro = { "prettier" },
        
        -- Blade (Laravel)
        blade = { "blade-formatter" },
    },
    
    -- Formatters configuration
    formatters = {
        -- Stylua configuration
        stylua = {
            prepend_args = {
                "--column-width", "120",
                "--line-endings", "Unix",
                "--indent-type", "Spaces",
                "--indent-width", "4",
                "--quote-style", "AutoPreferDouble",
            },
        },
        
        -- Prettier configuration
        prettier = {
            prepend_args = {
                "--tab-width", "4",
                "--single-quote", "false",
                "--trailing-comma", "es5",
                "--semi", "true",
                "--print-width", "120",
            },
        },
        
        -- Biome configuration (faster alternative to prettier)
        biome = {
            prepend_args = {
                "format",
                "--indent-style", "space",
                "--indent-width", "4",
                "--line-width", "120",
            },
        },
        
        -- PHP CS Fixer configuration
        php_cs_fixer = {
            prepend_args = {
                "--rules=@PSR12,@Symfony",
                "--using-cache=no",
            },
        },
        
        -- Laravel Pint configuration
        pint = {
            prepend_args = {
                "--preset", "laravel",
            },
        },
        
        -- Black configuration for Python
        black = {
            prepend_args = {
                "--line-length", "120",
                "--target-version", "py38",
            },
        },
        
        -- isort configuration for Python imports
        isort = {
            prepend_args = {
                "--profile", "black",
                "--line-length", "120",
            },
        },
        
        -- shfmt configuration for shell scripts
        shfmt = {
            prepend_args = {
                "-i", "4", -- 4 spaces indentation
                "-bn",     -- binary ops like && and | may start a line
                "-ci",     -- switch cases will be indented
                "-sr",     -- redirect operators will be followed by a space
            },
        },
        
        -- clang-format configuration
        clang_format = {
            prepend_args = {
                "--style={IndentWidth: 4, TabWidth: 4, UseTab: Never, ColumnLimit: 120}",
            },
        },
    },
    
    -- Format on save configuration
    format_on_save = function(bufnr)
        -- Disable format on save for specific filetypes
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
            return
        end
        
        -- Check if LSP formatting is available and prefer it for certain filetypes
        local lsp_format_filetypes = { "go", "rust" }
        if vim.tbl_contains(lsp_format_filetypes, vim.bo[bufnr].filetype) then
            -- Try LSP formatting first
            local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
            for _, client in ipairs(clients) do
                if client.supports_method("textDocument/formatting") then
                    return -- Let LSP handle formatting
                end
            end
        end
        
        return {
            timeout_ms = 500,
            lsp_fallback = true,
        }
    end,
    
    -- Format after save for slower formatters
    format_after_save = {
        lsp_fallback = true,
    },
    
    -- Logging level
    log_level = vim.log.levels.ERROR,
    
    -- Notification configuration
    notify_on_error = true,
})

-- ============================================================================
-- CONFORM UTILITIES
-- ============================================================================

-- Function to check if conform can format the current buffer
local function can_format()
    local bufnr = vim.api.nvim_get_current_buf()
    local formatters = conform.list_formatters(bufnr)
    return #formatters > 0
end

-- Function to get available formatters for current buffer
local function get_formatters()
    local bufnr = vim.api.nvim_get_current_buf()
    local formatters = conform.list_formatters(bufnr)
    local names = {}
    for _, formatter in ipairs(formatters) do
        table.insert(names, formatter.name)
    end
    return names
end

-- Function to format with specific formatter
local function format_with(formatter_name)
    local bufnr = vim.api.nvim_get_current_buf()
    conform.format({
        bufnr = bufnr,
        formatters = { formatter_name },
        timeout_ms = 2000,
    })
end

-- Add utilities to global vim object
vim.conform = {
    can_format = can_format,
    get_formatters = get_formatters,
    format_with = format_with,
}

-- ============================================================================
-- CONFORM KEYMAPS
-- ============================================================================

-- Format current buffer
vim.keymap.set('n', '<leader>cf', function()
    conform.format({
        async = true,
        lsp_fallback = true,
        timeout_ms = 2000,
    })
end, { desc = 'Format buffer' })

-- Format selection in visual mode
vim.keymap.set('v', '<leader>cf', function()
    conform.format({
        async = true,
        lsp_fallback = true,
        timeout_ms = 2000,
    })
end, { desc = 'Format selection' })

-- Format with specific formatter (shows picker)
vim.keymap.set('n', '<leader>cF', function()
    local formatters = get_formatters()
    if #formatters == 0 then
        vim.notify("No formatters available for this filetype", vim.log.levels.WARN)
        return
    end
    
    vim.ui.select(formatters, {
        prompt = "Select formatter:",
    }, function(choice)
        if choice then
            format_with(choice)
            vim.notify("Formatted with " .. choice, vim.log.levels.INFO)
        end
    end)
end, { desc = 'Format with specific formatter' })

-- Toggle format on save
vim.keymap.set('n', '<leader>ct', function()
    local current_setting = conform.format_on_save
    if current_setting then
        conform.format_on_save = nil
        vim.notify("Format on save disabled", vim.log.levels.INFO)
    else
        conform.format_on_save = {
            timeout_ms = 500,
            lsp_fallback = true,
        }
        vim.notify("Format on save enabled", vim.log.levels.INFO)
    end
end, { desc = 'Toggle format on save' })

-- Show available formatters
vim.keymap.set('n', '<leader>ci', function()
    local formatters = get_formatters()
    if #formatters == 0 then
        vim.notify("No formatters available for this filetype", vim.log.levels.WARN)
    else
        vim.notify("Available formatters: " .. table.concat(formatters, ", "), vim.log.levels.INFO)
    end
end, { desc = 'Show available formatters' })

-- ============================================================================
-- AUTOCOMMANDS
-- ============================================================================

-- Create autocommand group for conform
local conform_group = vim.api.nvim_create_augroup("ConformFormatting", { clear = true })

-- Show formatter info when entering buffer
vim.api.nvim_create_autocmd("BufEnter", {
    group = conform_group,
    callback = function()
        local formatters = get_formatters()
        if #formatters > 0 then
            vim.b.conform_formatters = formatters
        end
    end,
    desc = "Set buffer formatters info"
})

-- Update statusline when formatters change
vim.api.nvim_create_autocmd("FileType", {
    group = conform_group,
    callback = function()
        local formatters = get_formatters()
        if #formatters > 0 then
            vim.b.conform_formatters = formatters
        end
    end,
    desc = "Update formatters on filetype change"
})

vim.notify("conform.nvim configured successfully", vim.log.levels.INFO)