-- ============================================================================
-- MASON CONFIGURATION
-- ============================================================================
-- Mason setup for LSP server management

-- Mason setup for LSP server management
require('mason').setup({
    ui = {
        border = "rounded",
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
        }
    }
})

-- Mason-lspconfig setup for automatic LSP server installation
require('mason-lspconfig').setup({
    ensure_installed = {
        -- Lua
        "lua_ls",

        -- Web Development
        "biome",
        "emmet_ls", -- Note: emmet_ls in Mason, not emmetls
        "tailwindcss", -- Tailwind CSS LSP server
        "jsonls", -- JSON LSP server
        "yamlls", -- YAML LSP server

        -- Programming Languages
        "gopls", -- Go LSP server
        "pyright", -- Python LSP server
        "rust_analyzer", -- Rust LSP server

        -- PHP Development
        "phpactor", -- PHP LSP server

        -- Document Processing
        "tinymist", -- Typst LSP server
    },
    automatic_installation = true,
})

-- Mason-tool-installer for additional tools
require('mason-tool-installer').setup({
    ensure_installed = {
        -- LSP Servers
        "lua_ls",
        "biome",
        "tinymist",
        "emmet_ls",
        "phpactor", -- PHP LSP server
        "tailwindcss", -- Tailwind CSS LSP server
        "gopls", -- Go LSP server
        "pyright", -- Python LSP server
        "rust_analyzer", -- Rust LSP server
        "jsonls", -- JSON LSP server
        "yamlls", -- YAML LSP server

        -- Linters
        "eslint_d", -- Fast ESLint daemon
        "pylint", -- Python linter
        "golangci-lint", -- Go linter
        "shellcheck", -- Shell script linter
        "markdownlint", -- Markdown linter
        "yamllint", -- YAML linter
        "jsonlint", -- JSON linter

        -- Formatters
        "stylua", -- Lua formatter
        "prettier", -- Web technologies formatter
        "black", -- Python formatter
        "isort", -- Python import sorter
        "php-cs-fixer", -- PHP formatter
        "shfmt", -- Shell script formatter
        "rustfmt", -- Rust formatter
        -- "gofmt", -- Go formatter (built-in with Go toolchain, not available in Mason)
        "goimports", -- Go import formatter
        "clang-format", -- C/C++ formatter
        "taplo", -- TOML formatter
        "xmlformatter", -- XML formatter (correct package name)
        "sql-formatter", -- SQL formatter
        "google-java-format", -- Java formatter
        "ktlint", -- Kotlin formatter
        -- "dart-format", -- Dart formatter (not available in Mason - use built-in dart format)
        "rubocop", -- Ruby formatter
        "ormolu", -- Haskell formatter
        "nixfmt", -- Nix formatter
        "terraform", -- Terraform formatter
        "buf", -- Protocol Buffers formatter
        "blade-formatter", -- Laravel Blade formatter

        -- Debug Adapters
        "debugpy", -- Python debugger
        "delve", -- Go debugger
        "codelldb", -- Rust/C++ debugger
        "node-debug2-adapter", -- Node.js debugger
    },
    auto_update = true, -- Set to true if you want automatic updates
    run_on_start = true,
})
