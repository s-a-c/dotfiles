-- ============================================================================
-- BLINK-COPILOT CONFIGURATION
-- ============================================================================
-- GitHub Copilot integration for blink.cmp completion engine
-- Compatible with avante.nvim and minimal copilot.lua setup

return {
    "giuxtaposition/blink-cmp-copilot",
    dependencies = {
        "zbirenbaum/copilot.lua",
        "saghen/blink.cmp",
    },
    config = function()
        -- ========================================================================
        -- ENSURE COPILOT.LUA MINIMAL SETUP
        -- ========================================================================
        local copilot_ok, copilot = pcall(require, "copilot")
        if not copilot_ok then
            vim.notify("Copilot.lua not found - required for blink-copilot", vim.log.levels.ERROR)
            return
        end

        -- ========================================================================
        -- BLINK-CMP-COPILOT SETUP
        -- ========================================================================
        local blink_copilot_ok, blink_copilot = pcall(require, "blink-cmp-copilot")
        if not blink_copilot_ok then
            vim.notify("blink-cmp-copilot not found", vim.log.levels.WARN)
            return
        end

        blink_copilot.setup({
            -- ======================================================================
            -- COPILOT SOURCE CONFIGURATION
            -- ======================================================================
            copilot = {
                -- Enable/disable Copilot completions
                enabled = true,

                -- API configuration
                api = {
                    -- Request timeout in milliseconds
                    timeout = 5000,
                    -- Maximum number of completions to request
                    max_completions = 3,
                },

                -- Completion behavior
                completion = {
                    -- Minimum trigger length before showing Copilot suggestions
                    min_trigger_length = 1,
                    -- Debounce delay in milliseconds before requesting completions
                    debounce_delay = 150,
                    -- Maximum number of lines to include as context
                    max_context_lines = 100,
                    -- Include file extension in context
                    include_file_extension = true,
                    -- Include surrounding context
                    include_surrounding_context = true,
                },

                -- Filtering and ranking
                filtering = {
                    -- Enable intelligent filtering of Copilot suggestions
                    enabled = true,
                    -- Minimum similarity score for suggestions (0.0 to 1.0)
                    min_similarity = 0.1,
                    -- Filter out suggestions that are too similar to existing text
                    filter_duplicates = true,
                    -- Filter out suggestions that are just whitespace
                    filter_whitespace = true,
                },

                -- Performance settings
                performance = {
                    -- Cache completions for better performance
                    cache_enabled = true,
                    -- Cache size (number of cached responses)
                    cache_size = 100,
                    -- Cache TTL in seconds
                    cache_ttl = 300,
                    -- Async completion requests
                    async = true,
                },
            },

            -- ======================================================================
            -- BLINK.CMP INTEGRATION SETTINGS
            -- ======================================================================
            blink = {
                -- Priority of Copilot source (lower than LSP but higher than buffer)
                priority = 85,
                -- Source name for blink.cmp
                name = "Copilot",
                -- Source module path
                module = "blink-cmp-copilot",
                -- Enable the source by default
                enabled = true,
                -- Trigger characters for Copilot completions
                trigger_characters = {},
                -- Keyword pattern for triggering completions
                keyword_pattern = [[\\k\\+]],
                -- Score offset for Copilot completions
                score_offset = 0,
            },

            -- ======================================================================
            -- UI CUSTOMIZATION
            -- ======================================================================
            ui = {
                -- Show Copilot status in completion menu
                show_status = true,
                -- Copilot icon for completion items
                icon = "󰚩",
                -- Highlight group for Copilot completions
                highlight_group = "BlinkCmpCopilot",
                -- Show source name in completion menu
                show_source = true,
                -- Custom formatting for Copilot items
                format = function(item)
                    return {
                        abbr = item.label,
                        kind = "󰚩 Copilot",
                        menu = "[AI]",
                        info = item.documentation or "",
                    }
                end,
            },

            -- ======================================================================
            -- LOGGING AND DEBUGGING
            -- ======================================================================
            debug = {
                -- Enable debug logging
                enabled = false,
                -- Log level (1 = error, 2 = warn, 3 = info, 4 = debug)
                level = 2,
                -- Log file path (nil = use default)
                log_file = nil,
            },
        })

        -- ========================================================================
        -- COPILOT STATUS FUNCTIONS
        -- ========================================================================
        local function get_copilot_status()
            local copilot_api = require("copilot.api")
            if copilot_api and copilot_api.status then
                local status = copilot_api.status.data
                return status and status.status or "unknown"
            end
            return "unknown"
        end

        local function toggle_copilot()
            local current_status = get_copilot_status()
            if current_status == "InProgress" or current_status == "Normal" then
                vim.cmd("Copilot disable")
                vim.notify("Copilot disabled", vim.log.levels.INFO)
            else
                vim.cmd("Copilot enable")
                vim.notify("Copilot enabled", vim.log.levels.INFO)
            end
        end

        -- ========================================================================
        -- BLINK-COPILOT KEYMAPS
        -- ========================================================================
        local keymap = vim.keymap.set

        -- Copilot control keymaps
        keymap('n', '<leader>cpt', toggle_copilot, { desc = 'Toggle Copilot' })
        keymap('n', '<leader>cps', function()
            local status = get_copilot_status()
            vim.notify("Copilot status: " .. status, vim.log.levels.INFO)
        end, { desc = 'Show Copilot status' })

        -- Copilot authentication and setup
        keymap('n', '<leader>cpa', '<cmd>Copilot auth<CR>', { desc = 'Authenticate Copilot' })
        keymap('n', '<leader>cpu', '<cmd>Copilot setup<CR>', { desc = 'Setup Copilot' })

        -- Blink-copilot specific commands
        keymap('n', '<leader>cpr', function()
            blink_copilot.refresh()
            vim.notify("Copilot cache refreshed", vim.log.levels.INFO)
        end, { desc = 'Refresh Copilot cache' })

        keymap('n', '<leader>cpd', function()
            local debug_enabled = blink_copilot.toggle_debug()
            vim.notify("Copilot debug " .. (debug_enabled and "enabled" or "disabled"), vim.log.levels.INFO)
        end, { desc = 'Toggle Copilot debug' })

        -- ========================================================================
        -- AUTOCOMMANDS
        -- ========================================================================
        local augroup = vim.api.nvim_create_augroup("BlinkCopilot", { clear = true })

        -- Auto-refresh Copilot cache when entering insert mode
        vim.api.nvim_create_autocmd("InsertEnter", {
            group = augroup,
            callback = function()
                -- Refresh cache if it's been a while
                local last_refresh = vim.g.blink_copilot_last_refresh or 0
                local current_time = vim.fn.localtime()
                if current_time - last_refresh > 300 then -- 5 minutes
                    blink_copilot.refresh()
                    vim.g.blink_copilot_last_refresh = current_time
                end
            end,
        })

        -- Show Copilot status on startup
        vim.api.nvim_create_autocmd("VimEnter", {
            group = augroup,
            callback = function()
                vim.defer_fn(function()
                    local status = get_copilot_status()
                    vim.notify("Copilot status: " .. status, vim.log.levels.INFO)
                end, 2000)
            end,
        })

        -- ========================================================================
        -- HIGHLIGHT GROUPS
        -- ========================================================================
        -- Define custom highlight group for Copilot completions
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = augroup,
            callback = function()
                vim.api.nvim_set_hl(0, "BlinkCmpCopilot", {
                    fg = "#6CC644", -- GitHub green
                    italic = true,
                })
            end,
        })

        -- Set initial highlight
        vim.api.nvim_set_hl(0, "BlinkCmpCopilot", {
            fg = "#6CC644", -- GitHub green
            italic = true,
        })

        -- ========================================================================
        -- WHICH-KEY INTEGRATION
        -- ========================================================================
        local ok_wk, wk = pcall(require, "which-key")
        if ok_wk then
            wk.add({
                { "<leader>cp",    group = "Copilot" },
                { "<leader>cpt", desc = "Toggle Copilot" },
                { "<leader>cps", desc = "Show Status" },
                { "<leader>cpa", desc = "Authenticate" },
                { "<leader>cpu", desc = "Setup" },
                { "<leader>cpr", desc = "Refresh Cache" },
                { "<leader>cpd", desc = "Toggle Debug" },
            })
        end

        -- ========================================================================
        -- SUCCESS NOTIFICATION
        -- ========================================================================
        vim.notify("blink-copilot configured successfully", vim.log.levels.INFO)
    end,
}
