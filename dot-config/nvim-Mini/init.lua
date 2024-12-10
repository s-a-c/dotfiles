-- DONE is sound working and is zoom 220%?
-- DONE mini.statusline
-- DONE mini.diff
-- DONE my own little function: markdown strikethrough,
-- TODO my own little function: list TODOs

-- Key-Mapping  -- {{{
-- mapleader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Escape to leave insert mode or to leave visual mode
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("v", "jk", "<Esc>")

vim.keymap.set("n", "<Leader>k", ":bd<CR>", { desc = "kill buffer" })

vim.keymap.set("n", "<Leader>dl", ":lua vim.diagnostic.setloclist()<CR>", { desc = "list LSP messages" })
vim.keymap.set("n", "<Leader>dn", ":lua vim.diagnostic.goto_next()<CR>", { desc = "next LSP message" })
vim.keymap.set("n", "<Leader>dp", ":lua vim.diagnostic.goto_prev()<CR>", { desc = "previous LSP message" })

vim.keymap.set("n", "<Leader>ff", ":Pick files<CR>", { desc = "Find Files" })
vim.keymap.set("n", "<Leader>fb", ":Pick buffers<CR>", { desc = "Find Buffer" })

vim.keymap.set("n", "U", "<C-r>")

-- Unfold current  area
vim.keymap.set("n", "<Tab>", "za")

-- lua/ejiqpep/core/keymaps.lua -->
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Keymaps for better default experience
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Space + s saves the file
vim.keymap.set("n", "<Leader>s", ":w<CR>:so %<CR>", { desc = "source this file" })
vim.keymap.set("n", "<Leader>w", ":w<CR>", { desc = "save", silent = true })

-- Move normally between wrapped lines
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Move to first symbol on the line
vim.keymap.set("n", "H", "^")

-- Move to last symbol of the line
vim.keymap.set("n", "L", "$")

-- Shift + q - Quit
vim.keymap.set("n", "Q", "<C-W>q")
vim.keymap.set("n", "<Leader>q", ":q<CR>", { desc = "quit" })

-- vv - Makes vertical split
vim.keymap.set("n", "vv", "<C-W>v")
-- ss - Makes horizontal split
vim.keymap.set("n", "ss", "<C-W>s")

-- Quick jumping between splits
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Indenting in visual mode (tab/shift+tab)
vim.keymap.set("v", "<Tab>", ">gv")
vim.keymap.set("v", "<S-Tab>", "<gv")

-- Move to the end of yanked text after yank and paste
vim.cmd("vnoremap <silent> y y`]")
vim.cmd("vnoremap <silent> p p`]")
vim.cmd("nnoremap <silent> p p`]")

-- Space + Space to clean search highlight
vim.keymap.set("n", "<Leader>h", ":noh<CR>", { silent = true })

-- Delete and paste
vim.keymap.set("n", "-", "ddp")
vim.keymap.set("n", "_", "ddkP")
-- Fixes pasting after visual selection.
vim.keymap.set("v", "p", '"_dP')

vim.keymap.set("n", "<Leader>ms", ":lua My_strikethrough()<CR>", { desc = "strikethrough" })
-- Key-Mapping -- }}}

-- Settings -- {{{
-- lua/ejiqpep/core/settings.lua
-- Set <space> as the leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set highlight on search
vim.o.hlsearch = true

-- Make line numbers default
vim.wo.number = true
vim.wo.relativenumber = true

-- Enable mouse mode
vim.o.mouse = "ar"

-- Sync clipboard between OS and Neovim.
vim.o.clipboard = "unnamedplus"

-- Enable break indent
vim.o.breakindent = true

-- No swap files
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
-- Save undo history
vim.o.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- Don't show modes (insert/visual)
vim.opt.showmode = false

-- " Open splits on the right and below
vim.opt.splitbelow = true
vim.opt.splitright = true

-- " update vim after file update from outside
vim.opt.autoread = true

-- " Indentation
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2

-- " Always use spaces insted of tabs
vim.opt.expandtab = true

-- " Don't wrap lines
vim.opt.wrap = true
-- " Wrap lines at convenient points
vim.opt.linebreak = true
-- " Show line breaks
vim.opt.showbreak = "↳"

-- " Start scrolling when we'are 8 lines aways from borders
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 15
vim.opt.sidescroll = 5

-- " This makes vim act like all other editors, buffers can
-- " exist in the background without being in a window.
vim.opt.hidden = true

-- " Add the g flag to search/replace by default
vim.opt.gdefault = true

-- Lazy redraw
vim.o.lazyredraw = true

-- Syntax highlighting
vim.cmd("syntax on")

-- Folding
vim.o.foldclose = "all"
vim.o.foldcolumn = "auto"
vim.o.foldenable = true
vim.o.foldignore = "#"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldmarker = "{{{,}}}"
vim.o.foldmethod = "marker"
vim.o.foldminlines = 5
vim.o.foldnestmax = 20
vim.o.foldopen = "block,hor,mark,percent,quickfix,search,tag,undo"
-- }}}

-- mini.nvim Put this at the top of 'init.lua' -- {{{
-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath("data") .. "/site/"
local mini_path = path_package .. "pack/deps/start/mini.nvim"
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local clone_cmd = { "git", "clone", "--filter=blob:none", "https://github.com/echasnovski/mini.nvim", mini_path }
  vim.fn.system(clone_cmd)
  vim.cmd("packadd mini.nvim | helptags ALL")
  vim.cmd('echo "Installed `mini.nvim`" | redraw')
end
-- }}}

-- mini.deps. Use 'mini.deps'. `now()` and `later()` are helpers for a safe two-stage -- {{{
-- Set up 'mini.deps' (customize to your liking)
require("mini.deps").setup({ path = { package = path_package } })

-- startup and are optional.
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later
-- }}}

-- Now. Safely execute immediately -- {{{
-- colorscheme -- {{{
now(function()
  -- modus-themes -- {{{
  add({
    source = "miikanissi/modus-themes.nvim",
  })
  require("modus-themes").load({ style = "modus_vivendi" })
  vim.cmd("colorscheme modus_vivendi")
  -- }}}
  -- -- mini.base16 -- {{{
  -- require("mini.base16").setup({
  --   palette = require('mini.base16').mini_palette('#112641', '#e2e98f', 75),
  --   plugins = {
  --     default = false,
  --     ['echasnovski/mini.nvim'] = true,
  --   }
  -- vim.cmd("colorscheme minischeme")
  --  vim.cmd("silent! colorscheme mini")
  -- })
  -- -- }}}
end)
-- }}}

now(function() require("mini.diff").setup() end)
now(function() require("mini.icons").setup() end)

-- mini.notify -- {{{
now(function()
  require("mini.notify").setup()
  vim.notify = require("mini.notify").make_notify()
end)
-- }}}

now(function() require("mini.sessions").setup() end)
now(function() require("mini.statusline").setup() end)

-- mini.tabline -- {{{
now(function()
  require("mini.tabline").setup({
    tabpage_section = "left",
    show_tab_close = true,
    format = function(buf_id, label)
      local suffix = vim.bo[buf_id].modified and "+ " or ""
      return MiniTabline.default_format(buf_id, label) .. suffix
    end,
  })
end)
-- }}}

-- LSP -- {{{
now(function()
  add({
    source = "williamboman/mason.nvim",
  })
  add({
    source = "neovim/nvim-lspconfig",
    -- Supply dependencies near target plugin
    depends = { "williamboman/mason.nvim" },
  })
  require("mason").setup()
  require("lspconfig").lua_ls.setup({
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = {
          globals = { "vim", "MiniDeps" },
        },
      },
    },
  })
end)
-- }}}
-- }}}

-- Later. Safely execute later -- {{{
later(function() require("mini.ai").setup() end)
later(function() require("mini.align").setup() end)
later(function() require("mini.animate").setup() end)

-- mini.basics -- {{{
later(function()
  require("mini.basics").setup(
  -- No need to copy this inside `setup()`. Will be used automatically.
    {
      -- Options. Set to `false` to disable.
      options = {
        -- Basic options ('number', 'ignorecase', and many more)
        basic = true,
        -- Extra UI features ('winblend', 'cmdheight=0', ...)
        extra_ui = true,
        -- Presets for window borders ('single', 'double', ...)
        win_borders = "default",
      },
      -- Mappings. Set to `false` to disable.
      mappings = {
        -- Basic mappings (better 'jk', save with Ctrl+S, ...)
        basic = true,
        -- Prefix for mappings that toggle common options ('wrap', 'spell', ...).
        -- Supply empty string to not create these mappings.
        option_toggle_prefix = [[\]],
        -- Window navigation with <C-hjkl>, resize with <C-arrow>
        windows = true,
        -- Move cursor in Insert, Command, and Terminal mode with <M-hjkl>
        move_with_alt = false,
      },
      -- Autocommands. Set to `false` to disable
      autocommands = {
        -- Basic autocommands (highlight on yank, start Insert in terminal, ...)
        basic = true,
        -- Set 'relativenumber' only in linewise and blockwise Visual mode
        relnum_in_visual_mode = false,
      },
      -- Whether to disable showing non-error feedback
      silent = false,
    }
  )
end)
-- }}}

later(function() require("mini.bracketed").setup() end)
later(function() require("mini.bufremove").setup() end)

-- mini.clue -- {{{
later(function()
  local miniclue = require("mini.clue")
  miniclue.setup({
    triggers = {
      -- Leader triggers
      { mode = "n", keys = "<Leader>" },
      { mode = "x", keys = "<Leader>" },
      -- Built-in completion
      { mode = "i", keys = "<C-x>" },
      -- `g` key
      { mode = "n", keys = "g" },
      { mode = "x", keys = "g" },
      -- Marks
      { mode = "n", keys = "'" },
      { mode = "n", keys = "`" },
      { mode = "x", keys = "'" },
      { mode = "x", keys = "`" },
      -- Registers
      { mode = "n", keys = '"' },
      { mode = "x", keys = '"' },
      { mode = "i", keys = "<C-r>" },
      { mode = "c", keys = "<C-r>" },
      -- Window commands
      { mode = "n", keys = "<C-w>" },
      -- `z` key
      { mode = "n", keys = "z" },
      { mode = "x", keys = "z" },
    },
    clues = {
      -- Enhance this by adding descriptions for <Leader> mapping groups
      miniclue.gen_clues.g(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      miniclue.gen_clues.windows(),
      miniclue.gen_clues.z(),
      miniclue.gen_clues.builtin_completion(),
      { mode = "n", keys = "<Leader>f", desc = "+ Find" },
      { mode = "n", keys = "<Leader>d", desc = "+ Diagnostic" },
    },
    -- Clue window settings
    window = {
      -- Floating window config
      config = { anchor = "SW", row = "auto", col = "auto" },
      -- Delay before showing clue window
      delay = 1000,
      -- Keys to scroll inside the clue window
      scroll_down = "<C-d>",
      scroll_up = "<C-u>",
    },
  })
end)
-- }}}

later(function() require("mini.colors").setup() end)

-- {{{
later(function()
  require("mini.comment").setup({
    -- Options which control module behavior
    options = {
      -- Function to compute custom 'commentstring' (optional)
      custom_commentstring = nil,
      -- Whether to ignore blank lines when commenting
      ignore_blank_line = true,
      -- Whether to recognize as comment only lines without indent
      start_of_line = false,
      -- Whether to force single space inner padding for comment parts
      pad_comment_parts = true,
    },
    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
      -- Toggle comment (like `gcip` - comment inner paragraph) for both
      -- Normal and Visual modes
      comment = "gc",
      -- Toggle comment on current line
      comment_line = "gcc",
      -- Toggle comment on visual selection
      comment_visual = "gc",
      -- Define 'comment' textobject (like `dgc` - delete whole comment block)
      -- Works also in Visual mode if mapping differs from `comment_visual`
      textobject = "gc",
    },
    -- Hook functions to be executed at certain stage of commenting
    hooks = {
      -- Before successful commenting. Does nothing by default.
      pre = function() end,
      -- After successful commenting. Does nothing by default.
      post = function() end,
    },
  })
end)
-- }}}

later(function() require("mini.completion").setup() end)
later(function() require("mini.doc").setup() end)
later(function() require("mini.extra").setup() end)

-- mini.files -- {{{
later(function()
  require("mini.files").setup({
    -- Customization of shown content
    content = {
      -- Predicate for which file system entries to show
      filter = nil,
      -- What prefix to show to the left of file system entry
      prefix = nil,
      -- In which order to show file system entries
      sort = nil,
    },
    -- Module mappings created only inside explorer.
    -- Use `''` (empty string) to not create one.
    mappings = {
      close = "q",
      go_in = "l",
      go_in_plus = "L",
      go_out = "h",
      go_out_plus = "H",
      mark_goto = "'",
      mark_set = "m",
      reset = "<BS>",
      reveal_cwd = "@",
      show_help = "g?",
      synchronize = "=",
      trim_left = "<",
      trim_right = ">",
    },
    -- General options
    options = {
      -- Whether to delete permanently or move into module-specific trash
      permanent_delete = false,
      -- Whether to use for editing directories
      use_as_default_explorer = true,
    },
    -- Customization of explorer windows
    windows = {
      -- Maximum number of windows to show side by side
      max_number = math.huge,
      -- Whether to show preview of file/directory under cursor
      preview = true,
      -- Width of focused window
      width_focus = 50,
      -- Width of non-focused window
      width_nofocus = 15,
      -- Width of preview window
      width_preview = 25,
    },
  })
end)
-- }}}

later(function() require("mini.fuzzy").setup() end)
later(function() require("mini.git").setup() end)

-- mini.hipatterns -- {{{
later(function()
  local hipatterns = require('mini.hipatterns')
  hipatterns.setup({
    highlighters = {
      -- Highlight standalone 'DONE', FIXME', 'HACK', 'TODO', 'NOTE'
      done      = { pattern = '%f[%w]()DONE()%f[%W]', group = 'MiniHipatternsDone' },
      fixme     = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
      hack      = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
      note      = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
      todo      = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },

      -- Highlight hex color strings (`#rrggbb`) using that color
      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })
  vim.cmd([[highlight MiniHipatternsDone   gui=italic,strikethrough,underdouble guifg=#00AA00]])
  vim.cmd([[highlight MiniHipatternsFixme  gui=bold,italic,underdouble guifg=#ffffff guibg=#FF0000 ]])
  vim.cmd([[highlight MiniHipatternsHack   gui=italic,reverse guifg=yellow]])
  vim.cmd([[highlight MiniHipatternsNote   gui=reverse guifg=teal guibg=white]])
  vim.cmd([[highlight MiniHipatternsTodo   gui=bold              guibg=#00FFFF guifg=#000000]])
end)
-- }}}

-- later(function() require("mini.hues").setup() end)
later(function() require("mini.indentscope").setup() end)
later(function() require("mini.jump").setup() end)
later(function() require("mini.jump2d").setup() end)
later(function() require("mini.map").setup() end)

-- mini.misc -- {{{
later(function()
  require("mini.misc").setup({
    -- Array of fields to make global (to be used as independent variables)
    make_global = { "put", "put_text", "setup_restore_cursor" },
  })
end)
-- }}}

later(function() require("mini.move").setup() end)
later(function() require("mini.operators").setup() end)

-- mini.pairs -- {{{
later(function()
  require("mini.pairs").setup({
    -- In which modes mappings from this `config` should be created
    modes = { insert = true, command = false, terminal = false },

    -- Global mappings. Each right hand side should be a pair information, a
    -- table with at least these fields (see more in |MiniPairs.map|):
    -- - <action> - one of 'open', 'close', 'closeopen'.
    -- - <pair> - two character string for pair to be used.
    -- By default pair is not inserted after `\`, quotes are not recognized by
    -- `<CR>`, `'` does not insert pair after a letter.
    -- Only parts of tables can be tweaked (others will use these defaults).
    mappings = {
      ["¡"] = { action = "open", pair = "¡!", neigh_pattern = "[^\\]." },
      ["¿"] = { action = "open", pair = "¿?", neigh_pattern = "[^\\]." },
      ["("] = { action = "open", pair = "()", neigh_pattern = "[^\\]." },
      ["["] = { action = "open", pair = "[]", neigh_pattern = "[^\\]." },
      ["{"] = { action = "open", pair = "{}", neigh_pattern = "[^\\]." },
      ["<"] = { action = "open", pair = "<>", neigh_pattern = "[^\\]." },

      [")"] = { action = "close", pair = "()", neigh_pattern = "[^\\]." },
      ["]"] = { action = "close", pair = "[]", neigh_pattern = "[^\\]." },
      ["}"] = { action = "close", pair = "{}", neigh_pattern = "[^\\]." },
      [">"] = { action = "close", pair = "{}", neigh_pattern = "[^\\]." },

      ['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^\\].", register = { cr = false } },
      ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%a\\].", register = { cr = false } },
      ["`"] = { action = "closeopen", pair = "``", neigh_pattern = "[^\\].", register = { cr = false } },
    },
  })
end)
-- }}}

-- mini.pick -- {{{
later(function()
  local win_config = function()
    local height = math.floor(0.9 * vim.o.lines)
    local width = math.floor(0.9 * vim.o.columns)
    local row = math.floor(0.1 * (vim.o.lines - height))
    local col = math.floor(0.1 * (vim.o.columns - width))
    return {
      height = height,
      width = width,
      border = "single",
    }
  end
  require("mini.pick").setup({
    options = {
      content_from_bottom = true,
      use_cache = true,
    },
    window = {
      config = win_config,
    },
    -- remove icons from mini.pick
    -- source = { show = require('mini.pick').default_show },
  })
end)
-- }}}

later(function() require("mini.splitjoin").setup() end)

-- mini.starter -- {{{
--- Configuration similar to 'mhinz/vim-startify': >lua
---
---   local starter = require('mini.starter')
---   starter.setup({
---     evaluate_single = true,
---     items = {
---       starter.sections.builtin_actions(),
---       starter.sections.recent_files(10, false),
---       starter.sections.recent_files(10, true),
---       -- Use this if you set up 'mini.sessions'
---       starter.sections.sessions(5, true)
---     },
---     content_hooks = {
---       starter.gen_hook.adding_bullet(),
---       starter.gen_hook.indexing('all', { 'Builtin actions' }),
---       starter.gen_hook.padding(3, 2),
---     },
---   })
--- <
--- Configuration similar to 'glepnir/dashboard-nvim': >lua
---
---   local starter = require('mini.starter')
---   starter.setup({
---     items = {
---       starter.sections.telescope(),
---     },
---     content_hooks = {
---       starter.gen_hook.adding_bullet(),
---       starter.gen_hook.aligning('center', 'center'),
---     },
---   })
--- <
later(function()
  local starter = require("mini.starter")
  starter.setup({
    -- Options which control module behavior
    options = {
      -- Whether to use 'mini.starter' as a module
      use_mini_starter = true,
    },
    -- Module mappings created only inside starter.
    -- Use `''` (empty string) to not create one.
    mappings = {
      -- Open 'mini.starter' window
      starter = "<Leader>ss",
      -- Open 'mini.starter' window in a new tab
      starter_tab = "<Leader>st",
    },
    items = {
      starter.sections.builtin_actions(),
      starter.sections.recent_files(10, false),
      starter.sections.recent_files(10, true),
      starter.sections.telescope(),
      -- Use this if you set up 'mini.sessions'
      starter.sections.sessions(5, true),
    },
    content_hooks = {
      starter.gen_hook.adding_bullet(),
      starter.gen_hook.aligning("center", "center"),
      starter.gen_hook.indexing("all", { "Builtin actions" }),
      starter.gen_hook.padding(3, 2),
    },
  })
end)
-- }}}

later(function() require("mini.surround").setup() end)
later(function() require("mini.test").setup() end)
later(function() require("mini.trailspace").setup() end)
later(function() require("mini.visits").setup() end)

-- conform -- {{{
later(function()
  add({
    source = "stevearc/conform.nvim",
  })
  require("conform").setup({
    formatters_by_ft = {
      lua = { "stylua" },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
  })
end)
-- }}}

-- indent-blankline -- {{{
-- later(function()
--   add({
--     source = "lukas-reineke/indent-blankline.nvim",
--     name = "indent-blankline",
--     main = "ibl",
--     ---@module "ibl"
--     ---@type ibl.config
--     opts = {},
--   })
--   local highlight = { "CursorColumn", "Whitespace", }
--   local ibl = require("ibl")
--   ibl.setup() {
--     indent = { highlight = highlight, char = "" },
--     whitespace = {
--       highlight = highlight,
--       remove_blankline_trail = true,
--     },
--     scope = { enabled = false },
--   }
-- end)
-- }}}

-- treesitter -- {{{
later(function()
  add({
    source = "nvim-treesitter/nvim-treesitter",
    -- Use 'master' while monitoring updates in 'main'
    checkout = "master",
    monitor = "main",
    -- Perform action after every checkout
    hooks = {
      post_checkout = function()
        vim.cmd("TSUpdate")
      end,
    },
  })
  -- Possible to immediately execute code which depends on the added plugin
  require("nvim-treesitter.configs").setup({
    -- A list of parser names, or "all" (the listed parsers MUST always be installed)
    ensure_installed = {
      "c",
      "lua",
      "vim",
      "vimdoc",
      "query",
      "markdown",
      "markdown_inline",
    },
    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,
    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
    auto_install = true,
    -- List of parsers to ignore installing (or "all")
    ignore_install = {},
    ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
    -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!
    highlight = {
      enable = true,
      -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
      -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
      -- the name of the parser)
      -- list of language that will be disabled
      -- disable = { "c", "rust" },
      -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
      disable = function(lang, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
          return true
        end
      end,
      -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
      -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
      -- Using this option may slow down your editor, and you may see some duplicate highlights.
      -- Instead of true it can also be a list of languages
      additional_vim_regex_highlighting = true,
    },
  })
end)
-- }}}

-- 900.My little functions -- {{{
function My_strikethrough()
  vim.cmd("normal ^i~~")
  vim.cmd("normal $a~~")
end

function My_list_todos()
  vim.cmd("vimgrep TODO %")
  vim.cmd("copen")
end

-- }}}
