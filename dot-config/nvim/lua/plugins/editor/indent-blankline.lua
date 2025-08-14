-- ============================================================================
-- INDENT-BLANKLINE.NVIM CONFIGURATION
-- ============================================================================
-- Adds indentation guides to all lines (including empty lines)

-- Ensure indent-blankline is available
local ok, ibl = pcall(require, "ibl")
if not ok then
    vim.notify("indent-blankline.nvim not found", vim.log.levels.WARN)
    return
end

-- ============================================================================
-- INDENT-BLANKLINE SETUP
-- ============================================================================

ibl.setup({
    -- Indentation configuration
    indent = {
        char = "│",
        tab_char = "│",
        highlight = "IblIndent",
        smart_indent_cap = true,
        priority = 200,
    },
    
    -- Whitespace configuration
    whitespace = {
        highlight = "IblWhitespace",
        remove_blankline_trail = true,
    },
    
    -- Scope configuration (current context highlighting)
    scope = {
        enabled = true,
        char = "│",
        highlight = "IblScope",
        priority = 1024,
        include = {
            node_type = {
                ["*"] = {
                    "class",
                    "return_statement",
                    "function",
                    "method",
                    "^if",
                    "^while",
                    "jsx_element",
                    "^for",
                    "^object",
                    "^table",
                    "block",
                    "arguments",
                    "if_statement",
                    "else_clause",
                    "jsx_element",
                    "jsx_self_closing_element",
                    "try_statement",
                    "catch_clause",
                    "import_statement",
                    "operation_type",
                },
            },
        },
        exclude = {
            language = {},
            node_type = {
                ["*"] = {
                    "source_file",
                    "program",
                },
                lua = {
                    "chunk",
                },
                python = {
                    "module",
                },
            },
        },
        show_start = true,
        show_end = false,
    },
    
    -- Excluded filetypes and buftypes
    exclude = {
        filetypes = {
            "lspinfo",
            "packer",
            "checkhealth",
            "help",
            "man",
            "gitcommit",
            "TelescopePrompt",
            "TelescopeResults",
            "mason",
            "nvdash",
            "nvcheatsheet",
            "dashboard",
            "snacks_dashboard",
            "alpha",
            "lazy",
            "neogitstatus",
            "trouble",
            "lspinfo",
            "Outline",
            "spectre_panel",
            "toggleterm",
            "DressingSelect",
            "tsplayground",
            "",
        },
        buftypes = {
            "terminal",
            "nofile",
            "quickfix",
            "prompt",
        },
    },
})

-- ============================================================================
-- CUSTOM HIGHLIGHT GROUPS
-- ============================================================================

-- Set up custom highlight groups for better visibility
local function setup_highlights()
    -- Get current colorscheme colors
    local normal_fg = vim.fn.synIDattr(vim.fn.hlID("Normal"), "fg")
    local comment_fg = vim.fn.synIDattr(vim.fn.hlID("Comment"), "fg")
    
    -- Set indent line colors
    vim.api.nvim_set_hl(0, "IblIndent", { fg = comment_fg or "#3C4048", nocombine = true })
    vim.api.nvim_set_hl(0, "IblWhitespace", { fg = comment_fg or "#3C4048", nocombine = true })
    vim.api.nvim_set_hl(0, "IblScope", { fg = "#61AFEF", bold = true, nocombine = true })
end

-- Setup highlights on colorscheme change
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = setup_highlights,
    desc = "Update indent-blankline highlights on colorscheme change",
})

-- Setup initial highlights
setup_highlights()

-- ============================================================================
-- TOGGLE FUNCTIONALITY
-- ============================================================================

-- Function to toggle indent-blankline
local function toggle_indent_blankline()
    local enabled = require("ibl.config").get_config(0).enabled
    if enabled then
        require("ibl").setup_buffer(0, { enabled = false })
        vim.notify("Indent guides disabled", vim.log.levels.INFO)
    else
        require("ibl").setup_buffer(0, { enabled = true })
        vim.notify("Indent guides enabled", vim.log.levels.INFO)
    end
end

-- ============================================================================
-- KEYMAPS
-- ============================================================================

local keymap = vim.keymap.set

-- Toggle indent guides
keymap("n", "<leader>ui", toggle_indent_blankline, { desc = "Toggle indent guides" })

-- ============================================================================
-- WHICH-KEY INTEGRATION
-- ============================================================================

local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
    wk.add({
        { "<leader>ui", desc = "📏 Toggle Indent Guides" },
    })
end

-- ============================================================================
-- SNACKS INTEGRATION DISABLED
-- ============================================================================

-- Snacks integration disabled to avoid conflicts
-- The manual toggle function above works reliably
-- vim.notify("Snacks integration disabled for indent guides", vim.log.levels.DEBUG)

vim.notify("indent-blankline.nvim configured successfully", vim.log.levels.INFO)