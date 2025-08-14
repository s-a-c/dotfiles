-- ============================================================================
-- GITHUB COPILOT.LUA CONFIGURATION (MINIMAL FOR BLINK-COPILOT)
-- ============================================================================
-- Minimal copilot.lua setup required for blink-copilot and avante integration
-- This provides the core Copilot service while letting blink-copilot handle completions
--
-- IMPORTANT: suggestion and panel are disabled to prevent conflicts with blink-copilot
-- All completion functionality is handled through lua/plugins/ai/blink-copilot.lua

return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "InsertEnter",
    config = function()
        require("copilot").setup({
            -- ========================================================================
            -- SUGGESTION CONFIGURATION (DISABLED FOR BLINK-COPILOT)
            -- ========================================================================
            suggestion = {
                enabled = false,            -- Critical: Must be false for blink-copilot integration
                auto_trigger = false,
                debounce = 75,
                keymap = {
                    accept = false,         -- Disabled - handled by blink-copilot
                    accept_word = false,    -- Disabled - handled by blink-copilot
                    accept_line = false,    -- Disabled - handled by blink-copilot
                    next = false,           -- Disabled - handled by blink-copilot
                    prev = false,           -- Disabled - handled by blink-copilot
                    dismiss = false,        -- Disabled - handled by blink-copilot
                },
            },

            -- ========================================================================
            -- PANEL CONFIGURATION (DISABLED FOR BLINK-COPILOT)
            -- ========================================================================
            panel = {
                enabled = false,            -- Critical: Must be false for blink-copilot integration
                auto_refresh = false,
                keymap = {
                    jump_prev = false,
                    jump_next = false,
                    accept = false,
                    refresh = false,
                    open = false,
                },
                layout = {
                    position = "bottom",
                    ratio = 0.4,
                },
            },

            -- ========================================================================
            -- FILETYPE RESTRICTIONS
            -- ========================================================================
            filetypes = {
                yaml = false,
                markdown = false,
                help = false,
                gitcommit = false,
                gitrebase = false,
                hgcommit = false,
                svn = false,
                cvs = false,
                ["."] = false,
            },

            -- ========================================================================
            -- SERVER CONFIGURATION
            -- ========================================================================
            copilot_node_command = 'node', -- Requires Node.js version > 18.x
            server_opts_overrides = {},
        })

        -- ========================================================================
        -- STATUS NOTIFICATION
        -- ========================================================================
        vim.notify("Copilot.lua initialized (minimal mode for blink-copilot)", vim.log.levels.INFO)
    end,
}
