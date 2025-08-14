-- ============================================================================
-- NEORG CONFIGURATION
-- ============================================================================
-- Note-taking and organization plugin for Neovim
-- Using vim.pack installation (rocks.nvim has Lua 5.4 compatibility issues)

-- Minimal neorg setup without rocks.nvim dependencies
require("neorg").setup({
    load = {
        ["core.defaults"] = {},  -- Loads default behaviour
        ["core.concealer"] = {}, -- Adds pretty icons to your documents
        ["core.dirman"] = {      -- Manages Neorg workspaces
            config = {
                workspaces = {
                    notes = "~/notes",
                    work = "~/work-notes",
                    personal = "~/personal-notes",
                },
                default_workspace = "notes",
            },
        },
        -- Note: Removed advanced features that may have dependency issues
        -- ["core.completion"] = {}, -- May cause issues without proper setup
        -- ["core.export"] = {}, -- Advanced feature, can be added later
        -- ["core.ui.calendar"] = {}, -- Advanced feature, can be added later
    },
})

-- Keymaps for Neorg
vim.api.nvim_create_autocmd("FileType", {
    pattern = "norg",
    callback = function()
        local opts = { buffer = true, silent = true }

        -- Navigation
        vim.keymap.set("n", "<leader>nw", "<cmd>Neorg workspace<cr>",
            vim.tbl_extend("force", opts, { desc = "Neorg Workspace" }))
        vim.keymap.set("n", "<leader>nr", "<cmd>Neorg return<cr>",
            vim.tbl_extend("force", opts, { desc = "Return to Previous Buffer" }))

        -- Journal
        vim.keymap.set("n", "<leader>njt", "<cmd>Neorg journal today<cr>",
            vim.tbl_extend("force", opts, { desc = "Today's Journal" }))
        vim.keymap.set("n", "<leader>njy", "<cmd>Neorg journal yesterday<cr>",
            vim.tbl_extend("force", opts, { desc = "Yesterday's Journal" }))
        vim.keymap.set("n", "<leader>njm", "<cmd>Neorg journal tomorrow<cr>",
            vim.tbl_extend("force", opts, { desc = "Tomorrow's Journal" }))

        -- Export (if available)
        vim.keymap.set("n", "<leader>ne", "<cmd>Neorg export<cr>",
            vim.tbl_extend("force", opts, { desc = "Export Document" }))

        -- Table of Contents
        vim.keymap.set("n", "<leader>nt", "<cmd>Neorg toc<cr>",
            vim.tbl_extend("force", opts, { desc = "Table of Contents" }))
    end,
})

-- Create notes directory if it doesn't exist
local notes_dir = vim.fn.expand("~/notes")
if vim.fn.isdirectory(notes_dir) == 0 then
    vim.fn.mkdir(notes_dir, "p")
end
