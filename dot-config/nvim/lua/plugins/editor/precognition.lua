-- ============================================================================
-- PRECOGNITION.NVIM CONFIGURATION
-- ============================================================================
-- Show hints for Vim motions as you type to help build muscle memory
-- Plugin: https://github.com/tris203/precognition.nvim

local M = {}

function M.setup()
    local ok, precognition = pcall(require, "precognition")
    if not ok then
        vim.notify("precognition.nvim not available", vim.log.levels.WARN, { title = "Plugin Loading" })
        return
    end

    precognition.setup({
        -- ========================================================================
        -- CORE CONFIGURATION
        -- ========================================================================

        -- Start with the plugin disabled to avoid overwhelming new users
        startVisible = false,

        -- Show hints in these modes
        showBlankVirtLine = true,

        -- Highlight groups for different hint types
        highlightColor = {
            keyword = "Function",
            builtin = "Keyword",
            parameter = "Identifier",
        },

        -- ========================================================================
        -- HINT CUSTOMIZATION
        -- ========================================================================

        -- Configure which hints to show
        hints = {
            -- Motion hints
            ["w"] = { prio = 10, color = "Function" },
            ["b"] = { prio = 9, color = "Function" },
            ["e"] = { prio = 8, color = "Function" },
            ["ge"] = { prio = 7, color = "Function" },

            -- Line-wise motions
            ["^"] = { prio = 6, color = "Keyword" },
            ["$"] = { prio = 6, color = "Keyword" },
            ["0"] = { prio = 5, color = "Keyword" },

            -- Search motions
            ["f"] = { prio = 4, color = "String" },
            ["F"] = { prio = 4, color = "String" },
            ["t"] = { prio = 3, color = "String" },
            ["T"] = { prio = 3, color = "String" },

            -- Bracket matching
            ["%"] = { prio = 2, color = "MatchParen" },

            -- Marks and jumps
            ["'"] = { prio = 1, color = "Special" },
            ["`"] = { prio = 1, color = "Special" },
        },

        -- ========================================================================
        -- DISPLAY SETTINGS
        -- ========================================================================

        -- Gutters to display hints in
        gutterHints = {
            -- Cursor line hints
            G = { prio = 10, color = "NonText" },
            gg = { prio = 9, color = "NonText" },
            PrevParagraph = { prio = 8, color = "NonText" },
            NextParagraph = { prio = 8, color = "NonText" },
        },

        -- Disabled file types
        disabledFiletypes = {
            "NvimTree",
            "neo-tree",
            "dashboard",
            "alpha",
            "startuptime",
            "oil",
            "telescope",
            "lazy",
            "mason",
            "help",
            "checkhealth",
            "lspinfo",
            "TelescopePrompt",
            "TelescopeResults",
            "vim-be-good"
        },

        -- Disabled in certain buffer types
        disabledBuftypes = {
            "terminal",
            "nofile",
            "quickfix",
            "prompt"
        },
    })

    -- ========================================================================
    -- KEYMAPS FOR CONTROL
    -- ========================================================================

    local function setup_keymaps()
        -- Toggle precognition
        vim.keymap.set("n", "<leader>cp", function()
            precognition.toggle()
        end, { desc = "Toggle Precognition hints" })

        -- Show precognition temporarily
        vim.keymap.set("n", "<leader>cs", function()
            precognition.show()
            vim.notify("Precognition enabled", vim.log.levels.INFO)
        end, { desc = "Show Precognition hints" })

        -- Hide precognition
        vim.keymap.set("n", "<leader>ch", function()
            precognition.hide()
            vim.notify("Precognition disabled", vim.log.levels.INFO)
        end, { desc = "Hide Precognition hints" })

        -- Enable precognition for learning session
        vim.keymap.set("n", "<leader>cl", function()
            precognition.show()
            vim.notify("💡 Learning mode activated! Precognition will guide your movements.", vim.log.levels.INFO, {
                title = "Precognition Learning",
                timeout = 3000,
            })

            -- Auto-disable after 10 minutes to avoid dependency
            vim.defer_fn(function()
                precognition.hide()
                vim.notify("Learning session ended. Try to practice without hints now!", vim.log.levels.INFO)
            end, 10 * 60 * 1000) -- 10 minutes
        end, { desc = "Start Precognition learning session" })
    end

    setup_keymaps()

    -- ========================================================================
    -- SMART ACTIVATION BASED ON USER BEHAVIOR
    -- ========================================================================

    local function setup_smart_activation()
        -- Track inefficient movements to suggest precognition
        local movement_tracker = {
            hjkl_count = 0,
            efficient_count = 0,
            start_time = vim.fn.localtime(),
        }

        -- Monitor key presses to detect learning opportunities
        local function track_movement()
            vim.api.nvim_create_autocmd("CursorMoved", {
                callback = function()
                    -- Simple heuristic: if user moves cursor a lot with hjkl, suggest precognition
                    local key = vim.fn.getcharstr()
                    if key:match("[hjkl]") then
                        movement_tracker.hjkl_count = movement_tracker.hjkl_count + 1
                    elseif key:match("[wbeWBE%^%$0fFtT]") then
                        movement_tracker.efficient_count = movement_tracker.efficient_count + 1
                    end

                    -- Suggest precognition if inefficient movement detected
                    local total_moves = movement_tracker.hjkl_count + movement_tracker.efficient_count
                    if total_moves > 20 and movement_tracker.hjkl_count / total_moves > 0.7 then
                        vim.notify(
                            "💡 Detected repetitive hjkl usage. Try <leader>cl to enable movement hints!",
                            vim.log.levels.INFO,
                            { title = "Precognition Suggestion" }
                        )
                        -- Reset counter to avoid spam
                        movement_tracker.hjkl_count = 0
                        movement_tracker.efficient_count = 0
                    end
                end
            })
        end

        -- Only track in normal mode for files, not special buffers
        vim.api.nvim_create_autocmd("BufEnter", {
            callback = function()
                local buftype = vim.bo.buftype
                local filetype = vim.bo.filetype

                if buftype == "" and not vim.tbl_contains({
                        "help", "terminal", "quickfix", "oil", "telescope", "NvimTree"
                    }, filetype) then
                    track_movement()
                end
            end
        })
    end

    -- Enable smart activation only if user hasn't explicitly set preferences
    if vim.g.precognition_smart_activation ~= false then
        setup_smart_activation()
    end

    -- ========================================================================
    -- INTEGRATION WITH OTHER LEARNING TOOLS
    -- ========================================================================

    local function setup_integrations()
        -- Auto-enable during vim-be-good sessions
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "vim-be-good",
            callback = function()
                precognition.show()
                vim.notify("🎮 Precognition enabled for training!", vim.log.levels.INFO)
            end
        })

        -- Auto-disable when leaving training
        vim.api.nvim_create_autocmd("BufLeave", {
            callback = function()
                local bufname = vim.api.nvim_buf_get_name(0)
                if bufname:match("vim%-be%-good") then
                    -- Optionally keep enabled for practice
                    if vim.g.keep_precognition_after_training then
                        vim.notify("Precognition still active - practice what you learned!", vim.log.levels.INFO)
                    else
                        precognition.hide()
                    end
                end
            end
        })

        -- Integration with hardtime.nvim
        vim.keymap.set("n", "<leader>clt", function()
            -- Enable both precognition and hardtime for intensive training
            precognition.show()

            local hardtime_ok, hardtime = pcall(require, "hardtime")
            if hardtime_ok then
                hardtime.enable()
                vim.notify("🔥 Intensive training mode: Precognition + Hardtime enabled!", vim.log.levels.WARN, {
                    title = "Training Mode",
                    timeout = 5000,
                })
            else
                vim.notify("💡 Precognition training mode activated!", vim.log.levels.INFO)
            end
        end, { desc = "Enable intensive training mode" })
    end

    setup_integrations()

    -- ========================================================================
    -- USER ONBOARDING
    -- ========================================================================

    local function setup_onboarding()
        -- Show introduction on first load
        if not vim.g.precognition_intro_shown then
            vim.defer_fn(function()
                vim.notify(
                    "👋 Precognition is available! Use <leader>cl to start learning efficient Vim movements.",
                    vim.log.levels.INFO,
                    {
                        title = "Welcome to Precognition",
                        timeout = 8000,
                    }
                )
                vim.g.precognition_intro_shown = true
            end, 3000) -- Wait 3 seconds after startup
        end
    end

    setup_onboarding()
end

-- Initialize the plugin
M.setup()

return M
