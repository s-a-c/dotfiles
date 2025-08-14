
-- ============================================================================
-- AVANTE.NVIM CONFIGURATION
-- ============================================================================
-- Cursor AI-like experience in Neovim with copilot.lua integration
-- Compatible with blink-copilot setup

return {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false, -- set this if you want to always pull the latest change
    opts = {
        -- ========================================================================
        -- PROVIDER CONFIGURATION
        -- ========================================================================
        provider = "copilot", -- Use copilot as the primary provider
        auto_suggestions = true,
        copilot = {
            endpoint = "https://api.githubcopilot.com",
            model = "gpt-4o-2024-05-13",
            proxy = nil, -- [protocol://]host[:port] Use this proxy
            allow_insecure = false, -- Allow insecure server connections
            timeout = 30000, -- Timeout in milliseconds
            temperature = 0,
            max_tokens = 4096,
        },

        -- ========================================================================
        -- MAPPINGS CONFIGURATION
        -- ========================================================================
        mappings = {
            --- @class AvanteConflictMappings
            diff = {
                ours = "co",
                theirs = "ct",
                all_theirs = "ca",
                both = "cb",
                cursor = "cc",
                next = "]x",
                prev = "[x",
            },
            suggestion = {
                accept = "<M-l>",
                next = "<M-]>",
                prev = "<M-[>",
                dismiss = "<C-]>",
            },
            jump = {
                next = "]]",
                prev = "[[",
            },
            submit = {
                normal = "<CR>",
                insert = "<C-s>",
            },
            sidebar = {
                apply_all = "A",
                apply_cursor = "a",
                switch_windows = "<Tab>",
                reverse_switch_windows = "<S-Tab>",
            },
        },

        -- ========================================================================
        -- HINTS CONFIGURATION
        -- ========================================================================
        hints = { enabled = true },

        -- ========================================================================
        -- WINDOWS CONFIGURATION
        -- ========================================================================
        windows = {
            ---@type "right" | "left" | "top" | "bottom"
            position = "right", -- the position of the sidebar
            wrap = true, -- similar to vim.o.wrap
            width = 30, -- default % based on available width
            sidebar_header = {
                align = "center", -- left, center, right for title
                rounded = true,
            },
        },

        -- ========================================================================
        -- HIGHLIGHTS CONFIGURATION
        -- ========================================================================
        highlights = {
            ---@type AvanteConflictHighlights
            diff = {
                current = "DiffText",
                incoming = "DiffAdd",
            },
        },

        -- ========================================================================
        -- DIFF CONFIGURATION
        -- ========================================================================
        --- @class AvanteConflictUserConfig
        diff = {
            autojump = true,
            ---@type string | fun(): string
            list_opener = "copen",
        },
    },

    -- ========================================================================
    -- DEPENDENCIES
    -- ========================================================================
    dependencies = {
        "stevearc/dressing.nvim",
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        --- The below dependencies are optional,
        "hrsh7th/nvim-cmp", -- autocompletion for avante commands and variables
        "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
        "zbirenbaum/copilot.lua", -- for providers='copilot'
        {
            -- support for image pasting
            "HakonHarnes/img-clip.nvim",
            event = "VeryLazy",
            opts = {
                -- recommended settings
                default = {
                    embed_image_as_base64 = false,
                    prompt_for_file_name = false,
                    drag_and_drop = {
                        insert_mode = true,
                    },
                    -- required for Windows users
                    use_absolute_path = true,
                },
            },
        },
        {
            -- Make sure to set this up properly if you have lazy=true
            'MeanderingProgrammer/render-markdown.nvim',
            opts = {
                file_types = { "markdown", "Avante" },
            },
            ft = { "markdown", "Avante" },
        },
    },

    -- ========================================================================
    -- PLUGIN CONFIGURATION
    -- ========================================================================
    config = function(_, opts)
        require("avante").setup(opts)

        -- ========================================================================
        -- AVANTE KEYMAPS
        -- ========================================================================
        local keymap = vim.keymap.set

        -- Main Avante functionality
        keymap('n', '<leader>aa', '<cmd>AvanteAsk<CR>', { desc = 'Avante Ask' })
        keymap('v', '<leader>aa', '<cmd>AvanteAsk<CR>', { desc = 'Avante Ask Selection' })
        keymap('n', '<leader>ac', '<cmd>AvanteChat<CR>', { desc = 'Avante Chat' })
        keymap('n', '<leader>at', '<cmd>AvanteToggle<CR>', { desc = 'Avante Toggle' })
        keymap('n', '<leader>ar', '<cmd>AvanteRefresh<CR>', { desc = 'Avante Refresh' })

        -- Avante edit modes
        keymap('v', '<leader>ae', '<cmd>AvanteEdit<CR>', { desc = 'Avante Edit Selection' })
        keymap('n', '<leader>af', '<cmd>AvanteFocus<CR>', { desc = 'Avante Focus' })

        -- Avante configuration
        keymap('n', '<leader>as', '<cmd>AvanteShowRepos<CR>', { desc = 'Avante Show Repos' })

        -- ========================================================================
        -- AUTOCOMMANDS
        -- ========================================================================
        local augroup = vim.api.nvim_create_augroup("AvanteConfig", { clear = true })

        -- Ensure Avante works properly with Copilot
        vim.api.nvim_create_autocmd("User", {
            pattern = "AvanteInit",
            group = augroup,
            callback = function()
                -- Ensure copilot is available for Avante
                local copilot_ok, _ = pcall(require, "copilot")
                if not copilot_ok then
                    vim.notify("Copilot.lua not available for Avante", vim.log.levels.WARN)
                else
                    vim.notify("Avante initialized with Copilot support", vim.log.levels.INFO)
                end
            end,
        })

        -- ========================================================================
        -- WHICH-KEY INTEGRATION
        -- ========================================================================
        local ok_wk, wk = pcall(require, "which-key")
        if ok_wk then
            wk.add({
                { "<leader>a",    group = "Avante" },
                { "<leader>aa", desc = "Ask Avante" },
                { "<leader>ac", desc = "Chat" },
                { "<leader>at", desc = "Toggle" },
                { "<leader>ar", desc = "Refresh" },
                { "<leader>ae", desc = "Edit Selection", mode = "v" },
                { "<leader>af", desc = "Focus" },
                { "<leader>as", desc = "Show Repos" },
            })
        end

        vim.notify("Avante configured with Copilot integration", vim.log.levels.INFO)
    end,
}
