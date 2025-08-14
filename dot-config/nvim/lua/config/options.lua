-- ============================================================================
-- NEOVIM OPTIONS AND SETTINGS
-- ============================================================================
-- Editor options and settings extracted from the main configuration

-- Leader keys (must be set before plugins are loaded)
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- Editor Options
local options = {
    -- Display
    number = true,                    -- Show line numbers
    relativenumber = true,            -- Show relative line numbers
    signcolumn = "yes",              -- Always show sign column
    termguicolors = true,            -- Enable 24-bit RGB colors
    winborder = "rounded",           -- Rounded window borders
    wrap = true,                     -- Enable line wrapping

    -- Indentation
    expandtab = true,                -- Use spaces instead of tabs
    smartindent = true,              -- Smart indentation
    softtabstop = 4,                 -- Number of spaces for tab in insert mode
    tabstop = 4,                     -- Number of spaces for tab character

    -- Files and backups
    swapfile = false,                -- Disable swap files

    -- Clipboard
    clipboard = "unnamedplus",       -- Use system clipboard

    -- Folding (for UFO)
    foldcolumn = '1',                -- Show fold column
    foldlevel = 99,                  -- High fold level for UFO
    foldlevelstart = 99,             -- Start with all folds open
    foldenable = true,               -- Enable folding
}

-- Apply all options
for option, value in pairs(options) do
    vim.o[option] = value
end

-- Additional vim.opt settings that need special handling
vim.opt.fillchars = {
    eob = " ",                       -- Remove ~ from end of buffer
    fold = " ",                      -- Fold character
    foldopen = "-",                  -- Fold open character
    foldsep = " ",                   -- Fold separator
    foldclose = "+",                 -- Fold close character
}

-- Disable some built-in plugins we don't need
local disabled_built_ins = {
    "netrw",
    "netrwPlugin",
    "netrwSettings",
    "netrwFileHandlers",
    "gzip",
    "zip",
    "zipPlugin",
    "tar",
    "tarPlugin",
    "getscript",
    "getscriptPlugin",
    "vimball",
    "vimballPlugin",
    "2html_plugin",
    "logipat",
    "rrhelper",
    "spellfile_plugin",
    "matchit"
}

for _, plugin in pairs(disabled_built_ins) do
    vim.g["loaded_" .. plugin] = 1
end
