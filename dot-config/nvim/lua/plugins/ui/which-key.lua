-- ============================================================================
-- WHICH-KEY CONFIGURATION
-- ============================================================================
-- Key mapping helper and organization

local wk = require("which-key")

-- Which-key setup with enhanced configuration
wk.setup({
    preset = "modern",
    delay = function(ctx)
        return ctx.plugin and 0 or 200
    end,
    filter = function(mapping)
        -- example to exclude mappings without a description
        return mapping.desc and mapping.desc ~= ""
    end,
    spec = {
        mode = { "n", "v" },
        { "<leader>b", group = "󰓩 Buffer", icon = "󰓩" },
        { "<leader>c", group = "󰘦 Code", icon = "󰘦" },
        { "<leader>cp", group = "🤖 Copilot", icon = "🤖" },
        { "<leader>d", group = "󰃤 Debug", icon = "󰃤" },
        { "<leader>f", group = "󰈞 Find", icon = "󰈞" },
        { "<leader>g", group = "󰊢 Git", icon = "󰊢" },
        { "<leader>h", group = "󰛕 Harpoon", icon = "󰛕" },
        { "<leader>l", group = "󰿘 LSP", icon = "󰿘" },
        { "<leader>n", group = "󱞁 Neorg", icon = "󱞁" },
        { "<leader>r", group = "󰑕 Render", icon = "󰑕" },
        { "<leader>p", group = "󰙅 Precognition", icon = "󰙅" },
        { "<leader>y", group = "󰙇 Typr", icon = "󰙇" },
        { "<leader>s", group = "󰆍 Search", icon = "󰆍" },
        { "<leader>t", group = "󰙨 Terminal", icon = "󰙨" },
        { "<leader>u", group = "󰕌 UI/Undo", icon = "󰕌" },
        { "<leader>w", group = "󰖲 Window", icon = "󰖲" },
        { "<leader>x", group = "󰒡 Trouble", icon = "󰒡" },
        { "<leader>z", group = "󰘖 Fold", icon = "󰘖" },
        { "<leader>e", group = "󰙅 Explorer", icon = "󰙅" },

        -- Git submenu organization
        { "<leader>gb", group = "󰘬 Branch", icon = "󰘬" },
        { "<leader>gc", group = "󰜘 Commit", icon = "󰜘" },
        { "<leader>gd", group = "󰦓 Diff", icon = "󰦓" },
        { "<leader>gh", group = "󰊢 GitHub", icon = "󰊢" },
        { "<leader>gs", group = "󰓦 Stash", icon = "󰓦" },

        -- LSP submenu organization
        { "<leader>lw", group = "󰖲 Workspace", icon = "󰖲" },

        -- Telescope submenu organization
        { "<leader>ft", group = "󰔱 Telescope", icon = "󰔱" },
        { "<leader>fg", group = "󰊢 Git", icon = "󰊢" },
        { "<leader>fl", group = "󰿘 LSP", icon = "󰿘" },

        -- Snacks submenu organization
        { "<leader>sn", group = "🍿 Snacks", icon = "🍿" },
    },
    icons = {
        breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
        separator = "➜", -- symbol used between a key and it's label
        group = "+", -- symbol prepended to a group
        ellipsis = "…",
        -- set to false to disable all mapping icons,
        -- both those explicitly added in a mapping
        -- and those from rules
        mappings = true,
        -- use the highlights from mini.icons
        -- When `false`, it will use `WhichKeyIcon` instead
        colors = true,
        -- used by key format
        keys = {
            Up = " ",
            Down = " ",
            Left = " ",
            Right = " ",
            C = "󰘴 ",
            M = "󰘵 ",
            D = "󰘳 ",
            S = "󰘶 ",
            CR = "󰌑 ",
            Esc = "󱊷 ",
            ScrollWheelDown = "󱕐 ",
            ScrollWheelUp = "󱕑 ",
            NL = "󰌑 ",
            BS = "󰁮",
            Space = "󱁐 ",
            Tab = "󰌒 ",
            F1 = "󱊫",
            F2 = "󱊬",
            F3 = "󱊭",
            F4 = "󱊮",
            F5 = "󱊯",
            F6 = "󱊰",
            F7 = "󱊱",
            F8 = "󱊲",
            F9 = "󱊳",
            F10 = "󱊴",
            F11 = "󱊵",
            F12 = "󱊶",
        },
    },
    win = {
        -- don't allow the popup to overlap with the cursor
        no_overlap = true,
        -- width = 1,
        -- height = { min = 4, max = 25 },
        -- col = 0,
        -- row = math.huge,
        border = "rounded",
        padding = { 1, 2 }, -- extra window padding [top/bottom, right/left]
        title = true,
        title_pos = "center",
        zindex = 1000,
        -- Additional vim.wo and vim.bo options
        bo = {},
        wo = {
            winblend = 10, -- value between 0-100 0 for fully opaque and 100 for fully transparent
        },
    },
    layout = {
        width = { min = 20 }, -- min and max width of the columns
        spacing = 3,          -- spacing between columns
    },
    keys = {
        scroll_down = "<c-d>", -- binding to scroll down inside the popup
        scroll_up = "<c-u>",   -- binding to scroll up inside the popup
    },
    ---@type false | "classic" | "modern" | "helix"
    sort = { "local", "order", "group", "alphanum", "mod" },
    ---@type number|fun(node: wk.Node):boolean?
    expand = 0, -- expand groups when <= n mappings
    -- expand = function(node)
    --   return not node.desc -- expand all nodes without a description
    -- end,
    -- Functions/Lua Patterns for formatting the labels
    ---@type table<string, ({[1]:string, [2]:string}|fun(str:string):string)[]>
    replace = {
        key = {
            function(key)
                return require("which-key.view").format(key)
            end,
            -- { "<Space>", "SPC" },
        },
        desc = {
            { "<Plug>%(?(.*)%)?", "%1" },
            { "^%+",              "" },
            { "<[cC]md>",         "" },
            { "<[cC][rR]>",       "" },
            { "<[sS]ilent>",      "" },
            { "^lua%s+",          "" },
            { "^call%s+",         "" },
            { "^:%s*",            "" },
        },
    },
})

-- ============================================================================
-- WHICH-KEY MAPPINGS
-- ============================================================================

-- Register comprehensive key mappings with which-key

-- Buffer management
wk.add({
    { "<leader>bb", "<cmd>Telescope buffers<cr>", desc = "󰓩 List buffers", mode = "n" },
    { "<leader>bd", "<cmd>bdelete<cr>", desc = "󰅖 Delete buffer", mode = "n" },
    { "<leader>bD", "<cmd>bdelete!<cr>", desc = "󰅙 Force delete buffer", mode = "n" },
    { "<leader>bn", "<cmd>bnext<cr>", desc = "󰒭 Next buffer", mode = "n" },
    { "<leader>bp", "<cmd>bprevious<cr>", desc = "󰒮 Previous buffer", mode = "n" },
    { "<leader>bf", "<cmd>bfirst<cr>", desc = "󰒫 First buffer", mode = "n" },
    { "<leader>bl", "<cmd>blast<cr>", desc = "󰒬 Last buffer", mode = "n" },
    { "<leader>bs", "<cmd>w<cr>", desc = "󰆓 Save buffer", mode = "n" },
    { "<leader>bS", "<cmd>wa<cr>", desc = "󰆔 Save all buffers", mode = "n" },
    { "<leader>br", "<cmd>e!<cr>", desc = "󰑐 Reload buffer", mode = "n" },
    { "<leader>bw", "<cmd>set wrap!<cr>", desc = "󰖶 Toggle wrap", mode = "n" },
    { "<leader>bh", "<cmd>nohlsearch<cr>", desc = "󰸱 Clear highlights", mode = "n" },
})

-- Find/Search with Telescope
wk.add({
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "󰈞 Find files", mode = "n" },
    { "<leader>fs", "<cmd>Telescope grep_string<cr>", desc = "󰱽 Grep string", mode = "n" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "󰓩 Find buffers", mode = "n" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "󰋖 Help tags", mode = "n" },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "󰋚 Recent files", mode = "n" },
    { "<leader>fc", "<cmd>Telescope colorscheme<cr>", desc = "󰏘 Colorschemes", mode = "n" },
    { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "󰌌 Keymaps", mode = "n" },
    { "<leader>fm", "<cmd>Telescope marks<cr>", desc = "󰃀 Marks", mode = "n" },
    { "<leader>fj", "<cmd>Telescope jumplist<cr>", desc = "󰕇 Jump list", mode = "n" },
    { "<leader>fq", "<cmd>Telescope quickfix<cr>", desc = "󰁨 Quickfix", mode = "n" },
    { "<leader>fw", "<cmd>Telescope grep_string<cr>", desc = "󰱽 Grep word under cursor", mode = "n" },
    { "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "󰱼 Fuzzy find in buffer", mode = "n" },
    { "<leader>f/", "<cmd>Telescope search_history<cr>", desc = "󰋚 Search history", mode = "n" },
    { "<leader>f:", "<cmd>Telescope command_history<cr>", desc = "󰘳 Command history", mode = "n" },
})

-- Telescope Git integration
wk.add({
    { "<leader>fgg", "<cmd>Telescope git_files<cr>", desc = "󰊢 Git files", mode = "n" },
    { "<leader>fgs", "<cmd>Telescope git_status<cr>", desc = "󰊢 Git status", mode = "n" },
    { "<leader>fgc", "<cmd>Telescope git_commits<cr>", desc = "󰜘 Git commits", mode = "n" },
    { "<leader>fgb", "<cmd>Telescope git_branches<cr>", desc = "󰘬 Git branches", mode = "n" },
    { "<leader>fgh", "<cmd>Telescope git_stash<cr>", desc = "󰓦 Git stash", mode = "n" },
})

-- Telescope LSP integration
wk.add({
    { "<leader>flr", "<cmd>Telescope lsp_references<cr>", desc = "󰈇 LSP references", mode = "n" },
    { "<leader>fld", "<cmd>Telescope lsp_definitions<cr>", desc = "󰈮 LSP definitions", mode = "n" },
    { "<leader>fli", "<cmd>Telescope lsp_implementations<cr>", desc = "󰡱 LSP implementations", mode = "n" },
    { "<leader>flt", "<cmd>Telescope lsp_type_definitions<cr>", desc = "󰜁 LSP type definitions", mode = "n" },
    { "<leader>fll", "<cmd>Telescope loclist<cr>", desc = "󰁩 Location list", mode = "n" },
})

wk.add({
    { "<leader>xx", "<cmd>TroubleToggle<cr>",                       desc = "Toggle Trouble",        mode = "n" },
    { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics", mode = "n" },
    { "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>",  desc = "Document Diagnostics",  mode = "n" },
    { "<leader>xl", "<cmd>TroubleToggle loclist<cr>",               desc = "Location List",         mode = "n" },
    { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>",              desc = "Quickfix List",         mode = "n" },
    { "<leader>xr", "<cmd>TroubleToggle lsp_references<cr>",        desc = "LSP References",        mode = "n" },
})

wk.add({
    { "<leader>uT", "<cmd>Twilight<cr>", desc = "Toggle Twilight", mode = "n" },
})

wk.add({
    { "<leader>bt", "<cmd>BiscuitsToggle<cr>", desc = "Toggle Biscuits", mode = "n" },
})

wk.add({
    { "<leader>rm", "<cmd>RenderMarkdownToggle<cr>", desc = "Toggle Markdown", mode = "n" },
})

wk.add({
    { "<leader>uS", "<cmd>SmearCursorToggle<cr>", desc = "Toggle Smear Cursor", mode = "n" },
})

wk.add({
    { "<leader>aa", "<cmd>Avante<cr>", desc = "Avante", mode = "n" },
})

-- ============================================================================
-- NEW ESSENTIAL PLUGIN MAPPINGS
-- ============================================================================

-- File Explorer (Oil.nvim)
wk.add({
    { "<leader>e", "<cmd>lua require('oil').open_float()<cr>", desc = "󰙅 Open file explorer", mode = "n" },
    { "<leader>E", "<cmd>lua require('oil').open()<cr>", desc = "󰙅 Open file explorer (buffer)", mode = "n" },
})

-- Search and Replace (Spectre)
wk.add({
    { "<leader>ss", "<cmd>lua require('spectre').toggle()<cr>", desc = "󰛔 Toggle Spectre", mode = "n" },
    { "<leader>sw", "<cmd>lua require('spectre').open_visual({select_word=true})<cr>", desc = "󰛔 Search current word", mode = "n" },
    { "<leader>sp", "<cmd>lua require('spectre').open_file_search({select_word=true})<cr>", desc = "󰛔 Search on current file", mode = "n" },
    { "<leader>sw", "<cmd>lua require('spectre').open_visual()<cr>", desc = "󰛔 Search current word", mode = "v" },
})

-- Enhanced Navigation (Flash.nvim)
wk.add({
    { "s", "<cmd>lua require('flash').jump()<cr>", desc = "󰉁 Flash", mode = { "n", "x", "o" } },
    { "S", "<cmd>lua require('flash').treesitter()<cr>", desc = "󰉁 Flash Treesitter", mode = { "n", "x", "o" } },
    { "r", "<cmd>lua require('flash').remote()<cr>", desc = "󰉁 Remote Flash", mode = "o" },
    { "R", "<cmd>lua require('flash').treesitter_search()<cr>", desc = "󰉁 Treesitter Search", mode = { "o", "x" } },
    { "<c-s>", "<cmd>lua require('flash').toggle()<cr>", desc = "󰉁 Toggle Flash Search", mode = "c" },
})

-- Terminal Management
wk.add({
    { "<leader>tt", "<cmd>lua require('snacks').terminal()<cr>", desc = "󰙨 Toggle terminal", mode = "n" },
    { "<leader>tf", "<cmd>lua require('snacks').terminal.open(nil, {cwd = vim.fn.expand('%:p:h')})<cr>", desc = "󰙨 Terminal in file dir", mode = "n" },
    { "<leader>tg", "<cmd>lua require('snacks').lazygit()<cr>", desc = "󰊢 LazyGit", mode = "n" },
})

-- Indentation Guides
wk.add({
    { "<leader>ui", "<cmd>IBLToggle<cr>", desc = "󰉶 Toggle indent guides", mode = "n" },
    { "<leader>us", "<cmd>IBLToggleScope<cr>", desc = "󰉶 Toggle scope guides", mode = "n" },
})

-- Note: This is a partial extraction of the Which-key mappings.
-- The original configuration contains many more mappings for:
-- - LSP operations
-- - Git operations
-- - Debug operations
-- - UI toggles
-- - Terminal operations
-- - Harpoon navigation
-- - Neorg operations
-- - And many more...
--
-- To complete the extraction, continue adding the remaining wk.add() blocks
-- from the original init.lua file (lines ~2100-2323)
