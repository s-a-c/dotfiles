-- ============================================================================
-- HARDTIME.NVIM CONFIGURATION
-- ============================================================================
-- Break bad Vim habits and build muscle memory for efficient editing
-- Plugin: https://github.com/m4xshen/hardtime.nvim

local M = {}

function M.setup()
    local ok, hardtime = pcall(require, "hardtime")
    if not ok then
        vim.notify("hardtime.nvim not available", vim.log.levels.WARN, { title = "Plugin Loading" })
        return
    end

    hardtime.setup({
        -- ========================================================================
        -- CORE CONFIGURATION
        -- ========================================================================

        -- Maximum number of repetitive key presses allowed before restriction
        max_time = 1000, -- ms
        max_count = 2,   -- Maximum consecutive repetitive keys

        -- Disable the plugin in certain modes for specific workflows
        disabled_modes = { "n", "v" }, -- Can be enabled selectively
        disabled_filetypes = {
            "qf",
            "netrw",
            "NvimTree",
            "lazy",
            "mason",
            "oil",
            "telescope"
        },

        -- ========================================================================
        -- RESTRICTED KEYS - Keys that will be limited
        -- ========================================================================
        restriction_mode = "block", -- "block" or "hint"

        restricted_keys = {
            -- Directional keys that encourage bad habits
            ["h"] = { "n", "x" },
            ["j"] = { "n", "x" },
            ["k"] = { "n", "x" },
            ["l"] = { "n", "x" },
            ["-"] = { "n", "x" },
            ["+"] = { "n", "x" },
            ["gj"] = { "n", "x" },
            ["gk"] = { "n", "x" },
            ["<CR>"] = { "n", "x" },
            ["<C-M>"] = { "n", "x" },
            ["<C-N>"] = { "n", "x" },
            ["<C-P>"] = { "n", "x" },
        },

        -- Keys that should be discouraged
        disabled_keys = {
            -- Arrow keys (encourage hjkl usage)
            ["<Up>"] = { "n", "x" },
            ["<Down>"] = { "n", "x" },
            ["<Left>"] = { "n", "x" },
            ["<Right>"] = { "n", "x" },
        },

        -- ========================================================================
        -- HINTS AND SUGGESTIONS - What to do instead
        -- ========================================================================
        hints = {
            -- Suggest better movement patterns
            ["[kj][kj]+"] = {
                message = function() return "Use " ..
                    vim.fn['repeat']("j", vim.v.count1) .. " or " .. vim.fn['repeat']("k", vim.v.count1) end,
                length = 2,
            },
            ["[hl][hl]+"] = {
                message = function() return "Use " ..
                    vim.fn['repeat']("l", vim.v.count1) .. " or " .. vim.fn['repeat']("h", vim.v.count1) end,
                length = 2,
            },
            -- Suggest word-wise movement
            ["[hl]+"] = {
                message = "Use w, b, e, ge for word movement",
                length = 4,
            },
            -- Suggest line-wise movement
            ["[jk]+"] = {
                message = "Use /, ?, *, #, or relative line numbers",
                length = 4,
            },
        },

        -- ========================================================================
        -- NOTIFICATIONS AND FEEDBACK
        -- ========================================================================
        notification = true,
        allow_different_key = true, -- Allow breaking sequence with different key

        -- Callback function when restriction is triggered
        callback = function(keys, count)
            vim.notify(
                string.format("Hardtime: '%s' pressed %d times. Consider better movement!", keys, count),
                vim.log.levels.WARN,
                {
                    title = "Break the habit!",
                    timeout = 2000,
                }
            )
        end,

        -- ========================================================================
        -- CUSTOMIZATION OPTIONS
        -- ========================================================================
        resetting_keys = {
            ["1"] = { "n" },
            ["2"] = { "n" },
            ["3"] = { "n" },
            ["4"] = { "n" },
            ["5"] = { "n" },
            ["6"] = { "n" },
            ["7"] = { "n" },
            ["8"] = { "n" },
            ["9"] = { "n" },
            -- Reset on various navigation keys
            ["w"] = { "n", "x" },
            ["b"] = { "n", "x" },
            ["e"] = { "n", "x" },
            ["ge"] = { "n", "x" },
            ["f"] = { "n", "x" },
            ["F"] = { "n", "x" },
            ["t"] = { "n", "x" },
            ["T"] = { "n", "x" },
            ["%"] = { "n", "x" },
            ["^"] = { "n", "x" },
            ["$"] = { "n", "x" },
            ["0"] = { "n", "x" },
        },
    })

    -- ========================================================================
    -- PROGRESSIVE DIFFICULTY - Gradually increase restrictions
    -- ========================================================================

    -- Start with gentle restrictions and increase over time
    local function adjust_difficulty()
        local session_count = vim.g.hardtime_sessions or 0
        vim.g.hardtime_sessions = session_count + 1

        -- Beginner: First 5 sessions - more lenient
        if session_count < 5 then
            hardtime.config.max_count = 4
            hardtime.config.restriction_mode = "hint"
            -- Intermediate: Sessions 5-15 - moderate restrictions
        elseif session_count < 15 then
            hardtime.config.max_count = 3
            hardtime.config.restriction_mode = "block"
            -- Advanced: Session 15+ - strict restrictions
        else
            hardtime.config.max_count = 2
            hardtime.config.restriction_mode = "block"
        end
    end

    -- Run adjustment on startup
    adjust_difficulty()

    -- ========================================================================
    -- KEYMAPS FOR PLUGIN CONTROL
    -- ========================================================================

    local function setup_keymaps()
        -- Toggle hardtime on/off
        vim.keymap.set("n", "<leader>ht", function()
            if hardtime.is_enabled() then
                hardtime.disable()
                vim.notify("Hardtime disabled", vim.log.levels.INFO)
            else
                hardtime.enable()
                vim.notify("Hardtime enabled", vim.log.levels.INFO)
            end
        end, { desc = "Toggle Hardtime" })

        -- Show current hardtime status
        vim.keymap.set("n", "<leader>hs", function()
            local status = hardtime.is_enabled() and "enabled" or "disabled"
            local sessions = vim.g.hardtime_sessions or 0
            vim.notify(
                string.format("Hardtime: %s | Sessions: %d", status, sessions),
                vim.log.levels.INFO,
                { title = "Hardtime Status" }
            )
        end, { desc = "Show Hardtime Status" })

        -- Reset session counter (for testing different difficulty levels)
        vim.keymap.set("n", "<leader>hr", function()
            vim.g.hardtime_sessions = 0
            vim.notify("Hardtime session counter reset", vim.log.levels.INFO)
            adjust_difficulty()
        end, { desc = "Reset Hardtime Sessions" })
    end

    setup_keymaps()

    -- ========================================================================
    -- INTEGRATION WITH OTHER PLUGINS
    -- ========================================================================

    -- Disable hardtime during specific activities
    local function setup_integrations()
        -- Disable during macro recording/playback
        vim.api.nvim_create_autocmd("RecordingEnter", {
            callback = function()
                if hardtime.is_enabled() then
                    hardtime.disable()
                    vim.g.hardtime_was_enabled = true
                end
            end
        })

        vim.api.nvim_create_autocmd("RecordingLeave", {
            callback = function()
                if vim.g.hardtime_was_enabled then
                    vim.defer_fn(function()
                        hardtime.enable()
                        vim.g.hardtime_was_enabled = false
                    end, 100)
                end
            end
        })

        -- Disable during telescope usage
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "TelescopePrompt",
            callback = function()
                vim.g.hardtime_telescope_disabled = hardtime.is_enabled()
                if vim.g.hardtime_telescope_disabled then
                    hardtime.disable()
                end
            end
        })

        vim.api.nvim_create_autocmd("FileType", {
            pattern = "*",
            callback = function()
                if vim.g.hardtime_telescope_disabled and vim.bo.filetype ~= "TelescopePrompt" then
                    vim.defer_fn(function()
                        hardtime.enable()
                        vim.g.hardtime_telescope_disabled = false
                    end, 100)
                end
            end
        })
    end

    setup_integrations()
end

-- Initialize the plugin
M.setup()

return M
