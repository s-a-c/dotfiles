-- ============================================================================
-- SNACKS DASHBOARD CONFIGURATION
-- ============================================================================
-- Dashboard and UI components configuration

-- Custom startup section for vim.pack
local function get_pack_stats()
    local start_time = vim.g.start_time or vim.fn.reltime()
    local current_time = vim.fn.reltime()
    local startup_time = vim.fn.reltimestr(vim.fn.reltime(start_time, current_time))

    -- Count loaded plugins from vim.pack
    local plugin_count = 0
    if vim.pack and vim.pack.list then
        for _ in pairs(vim.pack.list()) do
            plugin_count = plugin_count + 1
        end
    end

    return {
        "⚡ Neovim loaded in " .. string.format("%.2f", tonumber(startup_time) * 1000) .. "ms",
        "📦 " .. plugin_count .. " plugins loaded",
    }
end

-- Define the dashboard specs
local dashboard_specs = {
    -- Original dashboard spec
    {
        sections = {
            { section = "header" },
            { section = "keys", gap = 1, padding = 1 },
            { section = "terminal", cmd = "curl -s 'wttr.in/?0'"},
            { text = get_pack_stats(), padding = 1 },
        },
    },
    -- First new dashboard spec
    {
        sections = {
            { section = "header" },
            {
                pane = 2,
                section = "terminal",
                cmd = "colorscript -e square",
                height = 5,
                padding = 1,
            },
            { section = "keys", gap = 1, padding = 1 },
            { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
            { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
            {
                pane = 2,
                icon = " ",
                title = "Git Status",
                section = "terminal",
                enabled = function()
                    return require("snacks").git.get_root() ~= nil
                end,
                cmd = "git status --short --branch --renames",
                height = 5,
                padding = 1,
                ttl = 5 * 60,
                indent = 3,
            },
            { section = "terminal", cmd = "curl -s 'wttr.in/?0'"},
            { text = get_pack_stats(), padding = 1 },
        },
    },
    -- Second new dashboard spec with random image
    {
        sections = {
            {
                section = "terminal",
                cmd = "chafa \"$(find ~/nc/Pictures/wallpapers/Dynamic-Wallpapers/Dark -type f \\( -iname \"*.jpg\" -o -iname \"*.jpeg\" -o -iname \"*.png\" -o -iname \"*.gif\" \\) | shuf -n 1)\" --format symbols --symbols vhalf --size 60x17 --stretch; sleep .1",
                height = 17,
                padding = 1,
            },
            {
                pane = 2,
                { section = "keys", gap = 1, padding = 1 },
                { section = "terminal", cmd = "curl -s 'wttr.in/?0'"},
                { text = get_pack_stats(), padding = 1 },
            },
        },
    },
    -- Fourth dashboard spec - Pokemon colorscripts
    {
        sections = {
            { section = "header" },
            { section = "keys", gap = 1, padding = 1 },
            { section = "terminal", cmd = "curl -s 'wttr.in/?0'"},
            { text = get_pack_stats(), padding = 1 },
            {
                section = "terminal",
                cmd = "pokemon-colorscripts -r --no-title; sleep .1",
                random = 10,
                pane = 2,
                indent = 4,
                height = 30,
            },
        },
    },
    -- Fifth dashboard spec - Fortune with cowsay and comprehensive sections
    {
        formats = {
            key = function(item)
                return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
            end,
        },
        sections = {
            { section = "terminal", cmd = "fortune -s | cowsay", hl = "header", padding = 1, indent = 8 },
            { section = "terminal", cmd = "curl -s 'wttr.in/?0'"},
            { title = "MRU ", file = vim.fn.fnamemodify(".", ":~"), padding = 1 },
            { section = "recent_files", cwd = true, limit = 8, padding = 1 },
            { title = "Sessions", padding = 1 },
            { section = "projects", padding = 1 },
            { title = "Bookmarks", padding = 1 },
            { section = "keys" },
        },
    },
}

-- Randomly select one of the dashboard specs
math.randomseed(os.time())
local selected_spec = dashboard_specs[math.random(#dashboard_specs)]

local header_specs = {
    -- Original snax header
    { header_spec = table.concat({
            [[                                                           ]],
            [[.  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗      ]],
            [[.  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║      ]],
            [[.  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║      ]],
            [[.  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║      ]],
            [[.  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║      ]],
            [[.  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝      ]],
            [[                                                           ]],
        }, '\n'),
    },
    { header_spec = table.concat({
            [[             ]],
            [[   █  █   ]],
            [[   █ ██   ]],
            [[   ████   ]],
            [[   ██ ███   ]],
            [[   █  █   ]],
            [[             ]],
            [[ n e o v i m ]],
            [[             ]],
        }, '\n'),
    },
    { header_spec = table.concat({
            [[                                                                       ]],
            [[                                                                     ]],
            [[       ████ ██████           █████      ██                     ]],
            [[      ███████████             █████                             ]],
            [[      █████████ ███████████████████ ███   ███████████   ]],
            [[     █████████  ███    █████████████ █████ ██████████████   ]],
            [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
            [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
            [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
            [[                                                                       ]],
        }, '\n'),
    },
}

-- Randomly select one of the headers
math.randomseed(os.time())
local selected_header = header_specs[math.random(#header_specs)]

-- Base dashboard configuration
local base_config = {
    enabled = true,
    preset = {
        header = selected_header,
        keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
    },
}

require("snacks").setup({
    -- ========================================================================
    -- CORE MODULES (Essential functionality)
    -- ========================================================================
    bigfile = { enabled = true },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    picker = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },

    -- ========================================================================
    -- ENHANCED MODULES (Phase 1-2 optimizations)
    -- ========================================================================
    bufdelete = { enabled = true },  -- Smart buffer deletion (90% value)
    rename = { enabled = true },     -- Enhanced file/symbol renaming (80% value)
    lazygit = { enabled = true },    -- Integrated git interface (85% value)

    animate = {
        enabled = true,
        fps = 60,
        easing = "outQuart",
        duration = 200,
    },  -- Smooth UI animations (85% value)

    profiler = {
        enabled = true,
        pick = true,
    },  -- Performance monitoring (75% value)

    -- ========================================================================
    -- NEWLY ENABLED MODULES (Maximizing utilization)
    -- ========================================================================
    terminal = {
        enabled = true,
        win = {
            position = "bottom",
            height = 0.3,
            width = 0.8,
            border = "rounded",
        },
        -- Enhanced terminal features
        shell = vim.o.shell,
        env = {},
    },  -- Advanced terminal management (90% value)

    git = {
        enabled = true,
        -- Enhanced git integration beyond lazygit
        url_patterns = {
            ["github%.com"] = {
                branch = "/tree/{branch}",
                file = "/blob/{branch}/{file}#L{line_start}-L{line_end}",
                commit = "/commit/{commit}",
            },
            ["gitlab%.com"] = {
                branch = "/-/tree/{branch}",
                file = "/-/blob/{branch}/{file}#L{line_start}-{line_end}",
                commit = "/-/commit/{commit}",
            },
        },
    },  -- Enhanced git workflow (85% value)

    scratch = {
        enabled = true,
        name = "scratch",
        ft = "markdown",
        icon = "󰎞",
        win = {
            width = 100,
            height = 30,
            border = "rounded",
        },
    },  -- Scratch buffer management (75% value)

    zen = {
        enabled = true,
        toggles = {
            dim = true,
            git_signs = false,
            mini_diff = false,
            diagnostics = false,
            inlay_hints = false,
        },
        zoom = {
            show = {
                statusline = false,
                tabline = false,
            },
        },
        win = {
            backdrop = 0.95,
            width = 0.8,
            height = 0.8,
        },
    },  -- Focus modes (80% value)

    toggle = {
        enabled = true,
        -- Advanced option toggles
        map = {
            ["<leader>ub"] = "option.background",
            ["<leader>uc"] = "option.conceallevel",
            ["<leader>ud"] = "diagnostics",
            ["<leader>uf"] = "option.foldenable",
            ["<leader>ug"] = "indent",
            ["<leader>uh"] = "inlay_hints",
            ["<leader>ul"] = "line_number",
            ["<leader>uL"] = "option.relativenumber",
            ["<leader>us"] = "option.spell",
            ["<leader>uT"] = "treesitter",
            ["<leader>uw"] = "option.wrap",
            ["<leader>uD"] = "dim",
        },
    },  -- Advanced toggle system (70% value)

    win = {
        enabled = true,
        -- Window management utilities
        backdrop = {
            transparent = false,
            blend = 50,
        },
        wo = {
            winblend = 0,
        },
        bo = {},
        keys = {
            q = "close",
            ["<esc>"] = "close",
        },
    },  -- Window management (65% value)

    -- ========================================================================
    -- NOTIFICATION SYSTEM (Enhanced)
    -- ========================================================================
    notifier = {
        enabled = true,
        timeout = 3000,
        width = { min = 40, max = 0.4 },
        height = { min = 1, max = 0.6 },
        margin = { top = 0, right = 1, bottom = 0 },
        padding = true,
        sort = { "level", "added" },
        level = vim.log.levels.TRACE,
        icons = {
            error = " ",
            warn = " ",
            info = " ",
            debug = " ",
            trace = " ",
        },
        keep = function(notif)
            return vim.fn.getcmdpos() > 0
        end,
        style = "compact",
        top_down = true,
        date_format = "%R",
        more_format = " ↓ %d lines ",
        refresh = 50,
    },

    -- ========================================================================
    -- ADVANCED STYLES CONFIGURATION
    -- ========================================================================
    styles = {
        notification = {
            wo = { wrap = true },
            border = "rounded",
            zindex = 100,
            ft = "markdown",
            wo = {
                winblend = 5,
                wrap = false,
                conceallevel = 2,
                colorcolumn = "",
                spell = false,
            },
            bo = { filetype = "snacks_notif" },
        },
        scratch = {
            border = "rounded",
            width = 100,
            height = 30,
            backdrop = false,
            zindex = 20,
        },
        zen = {
            backdrop = {
                transparent = false,
                blend = 95,
            },
            width = 0.8,
            height = 0.8,
            zindex = 40,
        },
        terminal = {
            bo = {
                filetype = "snacks_terminal",
            },
            wo = {},
            keys = {
                q = "hide",
                gf = function(self)
                    local f = vim.fn.findfile(vim.fn.expand("<cfile>"), "**")
                    if f == "" then
                        vim.notify("File not found", vim.log.levels.ERROR)
                    else
                        self:hide()
                        vim.cmd("e " .. f)
                    end
                end,
                term_normal = {
                    "<esc>",
                    function(self)
                        self.esc_timer = self.esc_timer or (vim.uv or vim.loop).new_timer()
                        if self.esc_timer:is_active() then
                            self.esc_timer:stop()
                            vim.cmd("stopinsert")
                        else
                            self.esc_timer:start(200, 0, function() end)
                            return "<esc>"
                        end
                    end,
                    mode = "t",
                    expr = true,
                    desc = "Double escape to normal mode",
                },
            },
        },
    },

    -- Dashboard configuration
    dashboard = vim.tbl_deep_extend("force", base_config, selected_spec),
})

-- ============================================================================
-- SNACKS KEYMAPS
-- ============================================================================

-- Snacks.nvim keymaps
local function map(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
end

-- Top Pickers & Explorer
map("n", "<leader><space>", function() require("snacks").picker.smart() end, { desc = "Smart Find Files" })
map("n", "<leader>,", function() require("snacks").picker.buffers() end, { desc = "Buffers" })
map("n", "<leader>/", function() require("snacks").picker.grep() end, { desc = "Grep" })
map("n", "<leader>:", function() require("snacks").picker.command_history() end, { desc = "Command History" })
map("n", "<leader>n", function() require("snacks").picker.notifications() end, { desc = "Notification History" })
map("n", "<leader>e", function() require("snacks").explorer() end, { desc = "File Explorer" })

-- find
map("n", "<leader>fb", function() require("snacks").picker.buffers() end, { desc = "Buffers" })
map("n", "<leader>fc", function() require("snacks").picker.files({ cwd = vim.fn.stdpath("config") }) end, { desc = "Find Config File" })
map("n", "<leader>ff", function() require("snacks").picker.files() end, { desc = "Find Files" })
map("n", "<leader>fg", function() require("snacks").picker.git_files() end, { desc = "Find Git Files" })
map("n", "<leader>fp", function() require("snacks").picker.projects() end, { desc = "Projects" })
map("n", "<leader>fr", function() require("snacks").picker.recent() end, { desc = "Recent" })

-- git
map("n", "<leader>gb", function() require("snacks").picker.git_branches() end, { desc = "Git Branches" })
map("n", "<leader>gl", function() require("snacks").picker.git_log() end, { desc = "Git Log" })
map("n", "<leader>gL", function() require("snacks").picker.git_log_line() end, { desc = "Git Log Line" })
map("n", "<leader>gs", function() require("snacks").picker.git_status() end, { desc = "Git Status" })
map("n", "<leader>gS", function() require("snacks").picker.git_stash() end, { desc = "Git Stash" })
map("n", "<leader>gd", function() require("snacks").picker.git_diff() end, { desc = "Git Diff (Hunks)" })
map("n", "<leader>gf", function() require("snacks").picker.git_log_file() end, { desc = "Git Log File" })

-- Grep
map("n", "<leader>sb", function() require("snacks").picker.lines() end, { desc = "Buffer Lines" })
map("n", "<leader>sB", function() require("snacks").picker.grep_buffers() end, { desc = "Grep Open Buffers" })
map("n", "<leader>sg", function() require("snacks").picker.grep() end, { desc = "Grep" })
map({ "n", "x" }, "<leader>sw", function() require("snacks").picker.grep_word() end, { desc = "Visual selection or word" })

-- search
map("n", '<leader>s"', function() require("snacks").picker.registers() end, { desc = "Registers" })
map("n", '<leader>s/', function() require("snacks").picker.search_history() end, { desc = "Search History" })
map("n", "<leader>sa", function() require("snacks").picker.autocmds() end, { desc = "Autocmds" })
map("n", "<leader>sc", function() require("snacks").picker.command_history() end, { desc = "Command History" })
map("n", "<leader>sC", function() require("snacks").picker.commands() end, { desc = "Commands" })
map("n", "<leader>sd", function() require("snacks").picker.diagnostics() end, { desc = "Diagnostics" })
map("n", "<leader>sD", function() require("snacks").picker.diagnostics_buffer() end, { desc = "Buffer Diagnostics" })
map("n", "<leader>sh", function() require("snacks").picker.help() end, { desc = "Help Pages" })
map("n", "<leader>sH", function() require("snacks").picker.highlights() end, { desc = "Highlights" })
map("n", "<leader>si", function() require("snacks").picker.icons() end, { desc = "Icons" })
map("n", "<leader>sj", function() require("snacks").picker.jumps() end, { desc = "Jumps" })
map("n", "<leader>sk", function() require("snacks").picker.keymaps() end, { desc = "Keymaps" })
map("n", "<leader>sl", function() require("snacks").picker.loclist() end, { desc = "Location List" })
map("n", "<leader>sm", function() require("snacks").picker.marks() end, { desc = "Marks" })
map("n", "<leader>sM", function() require("snacks").picker.man() end, { desc = "Man Pages" })
map("n", "<leader>sp", function() require("snacks").picker.lazy() end, { desc = "Search for Plugin Spec" })
map("n", "<leader>sq", function() require("snacks").picker.qflist() end, { desc = "Quickfix List" })
map("n", "<leader>sR", function() require("snacks").picker.resume() end, { desc = "Resume" })
map("n", "<leader>su", function() require("snacks").picker.undo() end, { desc = "Undo History" })
map("n", "<leader>uC", function() require("snacks").picker.colorschemes() end, { desc = "Colorschemes" })

-- LSP
map("n", "gd", function() require("snacks").picker.lsp_definitions() end, { desc = "Goto Definition" })
map("n", "gD", function() require("snacks").picker.lsp_declarations() end, { desc = "Goto Declaration" })
map("n", "gr", function() require("snacks").picker.lsp_references() end, { nowait = true, desc = "References" })
map("n", "gI", function() require("snacks").picker.lsp_implementations() end, { desc = "Goto Implementation" })
map("n", "gy", function() require("snacks").picker.lsp_type_definitions() end, { desc = "Goto T[y]pe Definition" })
map("n", "<leader>ss", function() require("snacks").picker.lsp_symbols() end, { desc = "LSP Symbols" })
map("n", "<leader>sS", function() require("snacks").picker.lsp_workspace_symbols() end, { desc = "LSP Workspace Symbols" })

-- Other
map("n", "<leader>z", function() require("snacks").zen() end, { desc = "Toggle Zen Mode" })
map("n", "<leader>Z", function() require("snacks").zen.zoom() end, { desc = "Toggle Zoom" })
map("n", "<leader>.", function() require("snacks").scratch() end, { desc = "Toggle Scratch Buffer" })
map("n", "<leader>S", function() require("snacks").scratch.select() end, { desc = "Select Scratch Buffer" })
map("n", "<leader>bd", function() require("snacks").bufdelete() end, { desc = "Delete Buffer" })
map("n", "<leader>cR", function() require("snacks").rename.rename_file() end, { desc = "Rename File" })
map({ "n", "v" }, "<leader>gB", function() require("snacks").gitbrowse() end, { desc = "Git Browse" })
map("n", "<leader>gg", function() require("snacks").lazygit() end, { desc = "Lazygit" })
map("n", "<leader>un", function() require("snacks").notifier.hide() end, { desc = "Dismiss All Notifications" })
map("n", "<c-/>", function() require("snacks").terminal() end, { desc = "Toggle Terminal" })
map("n", "<c-_>", function() require("snacks").terminal() end, { desc = "which_key_ignore" })
map({ "n", "t" }, "]]", function() require("snacks").words.jump(vim.v.count1) end, { desc = "Next Reference" })
map({ "n", "t" }, "[[", function() require("snacks").words.jump(-vim.v.count1) end, { desc = "Prev Reference" })

-- ========================================================================
-- ENHANCED SNACKS.NVIM KEYMAPS (All Modules)
-- ========================================================================

-- Terminal Management (NEW)
map("n", "<c-/>", function() require("snacks").terminal() end, { desc = "Toggle Terminal" })
map("n", "<c-_>", function() require("snacks").terminal() end, { desc = "which_key_ignore" })
map("t", "<c-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
map("t", "<c-_>", "<cmd>close<cr>", { desc = "which_key_ignore" })

-- Advanced Terminal Operations
map("n", "<leader>tf", function() require("snacks").terminal.toggle("float") end, { desc = "Terminal Float" })
map("n", "<leader>th", function() require("snacks").terminal.toggle("horizontal") end, { desc = "Terminal Horizontal" })
map("n", "<leader>tv", function() require("snacks").terminal.toggle("vertical") end, { desc = "Terminal Vertical" })

-- Git Integration (Enhanced)
map({ "n", "v" }, "<leader>gB", function() require("snacks").gitbrowse() end, { desc = "Git Browse" })
map("n", "<leader>gf", function() require("snacks").git.blame_line() end, { desc = "Git Blame Line" })
map("n", "<leader>gF", function() require("snacks").git.blame_file() end, { desc = "Git Blame File" })

-- Scratch Buffer Management (NEW)
map("n", "<leader>.", function() require("snacks").scratch() end, { desc = "Toggle Scratch Buffer" })
map("n", "<leader>S", function() require("snacks").scratch.select() end, { desc = "Select Scratch Buffer" })

-- Focus Modes (Enhanced Zen/Zoom)
map("n", "<leader>z", function() require("snacks").zen() end, { desc = "Toggle Zen Mode" })
map("n", "<leader>Z", function() require("snacks").zen.zoom() end, { desc = "Toggle Zoom" })

-- Window Management (NEW)
map("n", "<leader>ww", function() require("snacks").win() end, { desc = "New Window" })
map("n", "<leader>wd", function() require("snacks").win.dismiss() end, { desc = "Dismiss All Windows" })

-- Enhanced Buffer Management
map("n", "<leader>bd", function() require("snacks").bufdelete() end, { desc = "Delete Buffer" })
map("n", "<leader>bD", function() require("snacks").bufdelete.all() end, { desc = "Delete All Buffers" })
map("n", "<leader>bo", function() require("snacks").bufdelete.other() end, { desc = "Delete Other Buffers" })

-- File/Symbol Renaming (Enhanced)
map("n", "<leader>cR", function() require("snacks").rename.rename_file() end, { desc = "Rename File" })
map("n", "<leader>cr", function() require("snacks").rename.rename_symbol() end, { desc = "Rename Symbol" })

-- Profiler and Performance Monitoring (Enhanced)
map("n", "<leader>pp", function() require("snacks").profiler.pick() end, { desc = "Profiler Pick" })
map("n", "<leader>ps", function() require("snacks").profiler.start() end, { desc = "Start Profiler" })
map("n", "<leader>pe", function() require("snacks").profiler.stop() end, { desc = "Stop Profiler" })
map("n", "<leader>pr", function() require("snacks").profiler.report() end, { desc = "Profiler Report" })

-- Advanced Notifications
map("n", "<leader>un", function() require("snacks").notifier.hide() end, { desc = "Dismiss All Notifications" })
map("n", "<leader>nh", function() require("snacks").notifier.show_history() end, { desc = "Notification History" })

-- Word Navigation (Enhanced)
map({ "n", "t" }, "]]", function() require("snacks").words.jump(vim.v.count1) end, { desc = "Next Reference" })
map({ "n", "t" }, "[[", function() require("snacks").words.jump(-vim.v.count1) end, { desc = "Prev Reference" })

-- Neovim News (Enhanced)
map("n", "<leader>N", function()
    require("snacks").win({
        file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
        width = 0.6,
        height = 0.6,
        wo = {
            spell = false,
            wrap = false,
            signcolumn = "yes",
            statuscolumn = " ",
            conceallevel = 3,
        },
    })
end, { desc = "Neovim News" })

-- Debug and Inspection (Enhanced)
map("n", "<leader>dd", function() require("snacks").debug.inspect() end, { desc = "Debug Inspect" })
map("n", "<leader>dt", function() require("snacks").debug.trace() end, { desc = "Debug Trace" })

-- ============================================================================
-- ENHANCED GLOBALS AND ADVANCED TOGGLES
-- ============================================================================

-- Setup enhanced globals and advanced toggle system
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        -- Enhanced debugging globals (lazy-loaded)
        _G.dd = function(...)
            require("snacks").debug.inspect(...)
        end
        _G.bt = function()
            require("snacks").debug.backtrace()
        end
        _G.prof = function(fn)
            require("snacks").profiler.scratch(fn)
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Advanced toggle system (using snacks.toggle module)
        local toggle = require("snacks").toggle

        -- Core editor toggles
        toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        toggle.line_number():map("<leader>ul")
        toggle.option("conceallevel", {
            off = 0,
            on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2,
            name = "Conceal Level"
        }):map("<leader>uc")

        -- Advanced feature toggles
        toggle.diagnostics():map("<leader>ud")
        toggle.treesitter():map("<leader>uT")
        toggle.inlay_hints():map("<leader>uh")
        toggle.indent():map("<leader>ug")
        toggle.dim():map("<leader>uD")

        -- Theme and appearance toggles
        toggle.option("background", {
            off = "light",
            on = "dark",
            name = "Dark Background"
        }):map("<leader>ub")

        -- Performance and debugging toggles
        toggle.option("foldenable", { name = "Code Folding" }):map("<leader>uf")
        toggle.profiler():map("<leader>up")

        -- Advanced UI toggles
        toggle.animate():map("<leader>ua")
        toggle.zen():map("<leader>uz")
        toggle.scratch():map("<leader>uS")

        -- Git integration toggles
        toggle.git_signs():map("<leader>ug")

        -- Terminal and window toggles
        toggle.terminal():map("<leader>ut")

        -- Notification system toggles
        toggle.notifier():map("<leader>un")
    end,
})
