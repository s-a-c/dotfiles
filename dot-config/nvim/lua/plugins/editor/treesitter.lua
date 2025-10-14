-- ============================================================================
-- TREESITTER CONFIGURATION
-- ============================================================================
-- Syntax highlighting and parsing configuration

require "nvim-treesitter.configs".setup({
    ensure_installed = {
        "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline",
        "javascript", "typescript", "tsx", "html", "css", "json", "yaml",
        "python", "rust", "go", "bash", "dockerfile", "gitignore",
        "svelte", "vue", "astro", "norg"
    },
    sync_install = false,
    auto_install = true,
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },
    indent = {
        enable = true
    },
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
        },
    },
    textobjects = {
        select = {
            enable = true,
            lookahead = true,
            keymaps = {
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["ic"] = "@class.inner",
            },
        },
    },
})
