-- ============================================================================
-- VIM-BE-GOOD CONFIGURATION
-- ============================================================================
-- A Neovim plugin designed to make you better at vim by practicing movements
-- Plugin: https://github.com/ThePrimeagen/vim-be-good

local M = {}

function M.setup()
    -- Check if the plugin is available
    local ok, _ = pcall(require, "vim-be-good")
    if not ok then
        vim.notify("vim-be-good not available", vim.log.levels.WARN, { title = "Plugin Loading" })
        return
    end

    -- ========================================================================
    -- SETUP AND CONFIGURATION
    -- ========================================================================

    -- vim-be-good doesn't require setup() but we can configure game preferences
    local function setup_game_preferences()
        -- Set default preferences for game modes
        vim.g.vimbegood_difficulty = "medium"        -- easy, medium, hard, nightmare
        vim.g.vimbegood_find_the_char_timeout = 3000 -- 3 seconds for find char games
        vim.g.vimbegood_ci_timeout = 5000            -- 5 seconds for ci games
    end

    setup_game_preferences()

    -- ========================================================================
    -- KEYMAPS FOR EASY ACCESS
    -- ========================================================================

    local function setup_keymaps()
        -- Main vim-be-good launcher
        vim.keymap.set("n", "<leader>vbg", ":VimBeGood<CR>", {
            desc = "Launch Vim Be Good",
            silent = true
        })

        -- Quick access to specific games
        vim.keymap.set("n", "<leader>vbr", ":VimBeGood relative<CR>", {
            desc = "VBG: Relative number jumping",
            silent = true
        })

        vim.keymap.set("n", "<leader>vbw", ":VimBeGood word<CR>", {
            desc = "VBG: Word navigation",
            silent = true
        })

        vim.keymap.set("n", "<leader>vbc", ":VimBeGood ci<CR>", {
            desc = "VBG: Change inside (ci)",
            silent = true
        })

        vim.keymap.set("n", "<leader>vbf", ":VimBeGood find<CR>", {
            desc = "VBG: Find character (f/F)",
            silent = true
        })

        vim.keymap.set("n", "<leader>vbs", ":VimBeGood substitute<CR>", {
            desc = "VBG: Substitute practice",
            silent = true
        })

        vim.keymap.set("n", "<leader>vbj", ":VimBeGood hjkl<CR>", {
            desc = "VBG: HJKL movement",
            silent = true
        })

        vim.keymap.set("n", "<leader>vbd", ":VimBeGood delete<CR>", {
            desc = "VBG: Delete operations",
            silent = true
        })

        vim.keymap.set("n", "<leader>vby", ":VimBeGood whackamole<CR>", {
            desc = "VBG: Whack-a-mole style",
            silent = true
        })

        -- Custom training session launcher
        vim.keymap.set("n", "<leader>vbt", function()
            local games = {
                "relative",
                "word",
                "ci",
                "find",
                "substitute",
                "hjkl",
                "delete"
            }

            vim.ui.select(games, {
                prompt = "Choose your training:",
                format_item = function(item)
                    local descriptions = {
                        relative = "🎯 Relative Number Jumping - Practice with line numbers",
                        word = "📝 Word Navigation - Master w, b, e movements",
                        ci = "🔄 Change Inside - Practice ci commands",
                        find = "🔍 Find Character - Improve f/F/t/T skills",
                        substitute = "✏️  Substitute - Master search & replace",
                        hjkl = "⬅️➡️⬆️⬇️ HJKL Movement - Basic directional practice",
                        delete = "🗑️  Delete Operations - Practice deletion commands"
                    }
                    return descriptions[item] or item
                end
            }, function(choice)
                if choice then
                    vim.cmd("VimBeGood " .. choice)
                end
            end)
        end, { desc = "VBG: Training Menu" })
    end

    setup_keymaps()

    -- ========================================================================
    -- TRAINING SCHEDULES AND HABITS
    -- ========================================================================

    local function setup_training_schedule()
        -- Track training sessions
        local function log_training_session(game_type)
            local today = os.date("%Y-%m-%d")
            local sessions = vim.g.vbg_sessions or {}
            sessions[today] = (sessions[today] or 0) + 1
            vim.g.vbg_sessions = sessions

            vim.notify(
                string.format("Training session completed! Today's sessions: %d", sessions[today]),
                vim.log.levels.INFO,
                { title = "Vim Be Good Progress" }
            )
        end

        -- Create training reminder
        local function setup_training_reminder()
            local sessions_today = vim.g.vbg_sessions and vim.g.vbg_sessions[os.date("%Y-%m-%d")] or 0

            -- Remind if no training today and it's been 30 minutes since startup
            if sessions_today == 0 then
                vim.defer_fn(function()
                    vim.notify(
                        "💪 Time for some Vim training? Try <leader>vbt for quick practice!",
                        vim.log.levels.INFO,
                        {
                            title = "Vim Be Good Reminder",
                            timeout = 5000,
                        }
                    )
                end, 30 * 60 * 1000) -- 30 minutes
            end
        end

        setup_training_reminder()

        -- Weekly progress report
        vim.keymap.set("n", "<leader>vbp", function()
            local sessions = vim.g.vbg_sessions or {}
            local today = os.date("%Y-%m-%d")
            local week_total = 0

            -- Calculate last 7 days
            for i = 0, 6 do
                local date = os.date("%Y-%m-%d", os.time() - i * 24 * 60 * 60)
                week_total = week_total + (sessions[date] or 0)
            end

            vim.notify(
                string.format(
                    "📊 Vim Training Progress\nToday: %d sessions\nThis week: %d sessions\nKeep practicing! 💪",
                    sessions[today] or 0,
                    week_total
                ),
                vim.log.levels.INFO,
                { title = "Training Progress" }
            )
        end, { desc = "VBG: Show Progress" })
    end

    setup_training_schedule()

    -- ========================================================================
    -- INTEGRATION WITH OTHER LEARNING TOOLS
    -- ========================================================================

    local function setup_integrations()
        -- Integration with precognition.nvim
        vim.keymap.set("n", "<leader>vl", function()
            -- Check if precognition is available
            local precog_ok, precognition = pcall(require, "precognition")
            local hardtime_ok, hardtime = pcall(require, "hardtime")

            local actions = {}

            if precog_ok then
                table.insert(actions, {
                    name = "🔮 Toggle Precognition",
                    action = function()
                        precognition.toggle()
                    end
                })
            end

            if hardtime_ok then
                table.insert(actions, {
                    name = "💪 Toggle Hardtime",
                    action = function()
                        if hardtime.is_enabled() then
                            hardtime.disable()
                        else
                            hardtime.enable()
                        end
                    end
                })
            end

            table.insert(actions, {
                name = "🎮 Launch Vim Be Good",
                action = function()
                    vim.cmd("VimBeGood")
                end
            })

            vim.ui.select(actions, {
                prompt = "Learning Tools:",
                format_item = function(item)
                    return item.name
                end
            }, function(choice)
                if choice then
                    choice.action()
                end
            end)
        end, { desc = "Learning Tools Menu" })

        -- Quick learning session
        vim.keymap.set("n", "<leader>vls", function()
            -- Start a comprehensive learning session
            vim.notify("🚀 Starting intensive Vim training session!", vim.log.levels.INFO)

            -- Enable precognition if available
            local precog_ok, precognition = pcall(require, "precognition")
            if precog_ok then
                precognition.show()
                vim.notify("✨ Precognition enabled", vim.log.levels.INFO)
            end

            -- Suggest starting with a warm-up game
            vim.defer_fn(function()
                vim.ui.select({
                    "hjkl - Basic movement warm-up",
                    "relative - Number jumping",
                    "word - Word navigation"
                }, {
                    prompt = "Choose warm-up exercise:",
                }, function(choice)
                    if choice then
                        local game = choice:match("^(%w+)")
                        vim.cmd("VimBeGood " .. game)
                    end
                end)
            end, 1000)
        end, { desc = "Start Learning Session" })
    end

    setup_integrations()
end

-- ========================================================================
-- AUTO COMMANDS FOR ENHANCED EXPERIENCE
-- ========================================================================

local function setup_autocommands()
    local augroup = vim.api.nvim_create_augroup("VimBeGoodEnhancements", { clear = true })

    -- Enhance vim-be-good buffer experience
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "vim-be-good",
        group = augroup,
        callback = function()
            -- Set local options for better game experience
            vim.opt_local.number = true
            vim.opt_local.relativenumber = true
            vim.opt_local.cursorline = true
            vim.opt_local.signcolumn = "no"

            -- Disable other plugins that might interfere
            vim.b.miniindentscope_disable = true

            -- Game-specific keymaps
            vim.keymap.set("n", "q", "<cmd>q<CR>", {
                buffer = true,
                desc = "Quick quit game"
            })

            vim.keymap.set("n", "r", "<cmd>VimBeGood<CR>", {
                buffer = true,
                desc = "Restart game selection"
            })
        end
    })

    -- Track when vim-be-good games are completed
    vim.api.nvim_create_autocmd("BufDelete", {
        pattern = "*",
        group = augroup,
        callback = function(args)
            local bufname = vim.api.nvim_buf_get_name(args.buf)
            if bufname:match("vim%-be%-good") then
                -- Game session ended, potentially log this
                vim.defer_fn(function()
                    if vim.fn.input("Rate this session (1-5): ") then
                        vim.notify("Thanks for training! Keep practicing! 💪", vim.log.levels.INFO)
                    end
                end, 100)
            end
        end
    })
end

-- Initialize the plugin
M.setup()
setup_autocommands()

return M
