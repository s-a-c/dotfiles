-- ============================================================================
-- PERSISTENCE.NVIM CONFIGURATION
-- ============================================================================
-- Session management configuration

require("persistence").setup({
    -- Directory where session files are saved
    dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
    
    -- Session options to save
    options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" },
    
    -- Pre-save hook to clean up before saving session
    pre_save = function()
        -- Close any floating windows
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local config = vim.api.nvim_win_get_config(win)
            if config.relative ~= "" then
                vim.api.nvim_win_close(win, false)
            end
        end
        
        -- Close trouble, oil, and other special buffers
        vim.cmd("silent! TroubleClose")
        vim.cmd("silent! Oil --close")
    end,
})

-- ============================================================================
-- PERSISTENCE KEYMAPS
-- ============================================================================

local function map(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
end

-- Session management keymaps
map("n", "<leader>qs", function() require("persistence").save() end, { desc = "Save Session" })
map("n", "<leader>qr", function() require("persistence").load() end, { desc = "Restore Session" })
map("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "Restore Last Session" })
map("n", "<leader>qd", function() require("persistence").stop() end, { desc = "Don't Save Current Session" })

-- ============================================================================
-- PERSISTENCE AUTOCOMMANDS
-- ============================================================================

-- Auto-save session on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("PersistenceAutoSave", { clear = true }),
    callback = function()
        -- Only save if we're in a real directory (not temp files)
        local cwd = vim.fn.getcwd()
        if cwd and cwd ~= "/" and not cwd:match("^/tmp") and not cwd:match("^/var/tmp") then
            require("persistence").save()
        end
    end,
})

-- Auto-restore session on startup if no arguments provided
vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("PersistenceAutoRestore", { clear = true }),
    nested = true,
    callback = function()
        -- Only restore if:
        -- 1. No arguments were passed to nvim
        -- 2. We're not in a git commit or similar
        -- 3. We're in a real directory
        if vim.fn.argc() == 0 and not vim.env.GIT_INDEX_FILE then
            local cwd = vim.fn.getcwd()
            if cwd and cwd ~= "/" and not cwd:match("^/tmp") and not cwd:match("^/var/tmp") then
                require("persistence").load()
            end
        end
    end,
})

-- ============================================================================
-- TELESCOPE INTEGRATION
-- ============================================================================

-- Add session picker to telescope if available
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        -- Check if telescope is available
        local ok, telescope = pcall(require, "telescope")
        if ok then
            -- Register session picker
            telescope.load_extension("sessions")
        end
        
        -- Add session picker keymap
        map("n", "<leader>fs", function()
            local persistence = require("persistence")
            local sessions_dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/")
            
            -- Use snacks picker if available, otherwise fallback to simple selection
            local ok_snacks, snacks = pcall(require, "snacks")
            if ok_snacks and snacks.picker then
                snacks.picker.pick("files", {
                    cwd = sessions_dir,
                    prompt = "Sessions",
                    format = function(item)
                        -- Format session names nicely
                        local name = item.filename:gsub("%%", "/"):gsub("%.vim$", "")
                        return name
                    end,
                    actions = {
                        ["default"] = function(item)
                            -- Load the selected session
                            persistence.load({ session = item.filename })
                        end,
                    },
                })
            else
                -- Fallback to simple file selection
                vim.cmd("edit " .. sessions_dir)
            end
        end, { desc = "Find Sessions" })
    end,
})