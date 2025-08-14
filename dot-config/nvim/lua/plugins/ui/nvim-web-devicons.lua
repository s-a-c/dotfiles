-- ============================================================================
-- NVIM-WEB-DEVICONS CONFIGURATION
-- ============================================================================
-- File type icons for Neovim plugins and UI components

-- Ensure nvim-web-devicons is loaded first
vim.cmd('packadd nvim-web-devicons')

local ok, devicons = pcall(require, "nvim-web-devicons")
if not ok then
    vim.notify("nvim-web-devicons not found", vim.log.levels.WARN)
    return
end

devicons.setup({
    -- Globally enable different highlight colors per icon (default to true)
    color_icons = true,

    -- Globally enable default icons (default to false)
    -- Will get overridden by `get_icons` option
    default = true,

    -- Globally enable "strict" selection of icons - icon will be looked up in
    -- different tables, first by filename, and if not found by extension; this
    -- prevents cases where file doesn't have any extension but still gets some icon
    -- because its name happened to match some extension (default to false)
    strict = true,

    -- Override specific icons and colors
    override = {
        -- Lua files
        lua = {
            icon = "",
            color = "#51a0cf",
            cterm_color = "74",
            name = "Lua"
        },

        -- JavaScript/TypeScript
        js = {
            icon = "",
            color = "#f1e05a",
            cterm_color = "185",
            name = "JavaScript"
        },
        ts = {
            icon = "",
            color = "#3178c6",
            cterm_color = "67",
            name = "TypeScript"
        },
        jsx = {
            icon = "",
            color = "#61dafb",
            cterm_color = "81",
            name = "JSX"
        },
        tsx = {
            icon = "",
            color = "#61dafb",
            cterm_color = "81",
            name = "TSX"
        },

        -- PHP
        php = {
            icon = "",
            color = "#8892bf",
            cterm_color = "103",
            name = "PHP"
        },

        -- Python
        py = {
            icon = "",
            color = "#3776ab",
            cterm_color = "67",
            name = "Python"
        },

        -- Rust
        rs = {
            icon = "",
            color = "#dea584",
            cterm_color = "180",
            name = "Rust"
        },

        -- Go
        go = {
            icon = "",
            color = "#00add8",
            cterm_color = "38",
            name = "Go"
        },

        -- C/C++
        c = {
            icon = "",
            color = "#599eff",
            cterm_color = "75",
            name = "C"
        },
        cpp = {
            icon = "",
            color = "#f34b7d",
            cterm_color = "204",
            name = "CPP"
        },

        -- HTML/CSS
        html = {
            icon = "",
            color = "#e34c26",
            cterm_color = "196",
            name = "HTML"
        },
        css = {
            icon = "",
            color = "#1572b6",
            cterm_color = "26",
            name = "CSS"
        },
        scss = {
            icon = "",
            color = "#cf649a",
            cterm_color = "169",
            name = "SCSS"
        },

        -- JSON/YAML
        json = {
            icon = "",
            color = "#cbcb41",
            cterm_color = "185",
            name = "JSON"
        },
        yaml = {
            icon = "",
            color = "#cb171e",
            cterm_color = "160",
            name = "YAML"
        },
        yml = {
            icon = "",
            color = "#cb171e",
            cterm_color = "160",
            name = "YAML"
        },

        -- Markdown
        md = {
            icon = "",
            color = "#519aba",
            cterm_color = "67",
            name = "Markdown"
        },

        -- Configuration files
        toml = {
            icon = "",
            color = "#9c4221",
            cterm_color = "124",
            name = "TOML"
        },
        conf = {
            icon = "",
            color = "#6d8086",
            cterm_color = "66",
            name = "Configuration"
        },

        -- Git
        gitignore = {
            icon = "",
            color = "#f1502f",
            cterm_color = "196",
            name = "GitIgnore"
        },

        -- Docker
        dockerfile = {
            icon = "",
            color = "#384d54",
            cterm_color = "59",
            name = "Dockerfile"
        },

        -- Shell scripts
        sh = {
            icon = "",
            color = "#4eaa25",
            cterm_color = "70",
            name = "Shell"
        },
        zsh = {
            icon = "",
            color = "#4eaa25",
            cterm_color = "70",
            name = "Zsh"
        },

        -- Vim
        vim = {
            icon = "",
            color = "#019833",
            cterm_color = "28",
            name = "Vim"
        },

        -- License files
        license = {
            icon = "",
            color = "#cbcb41",
            cterm_color = "185",
            name = "License"
        },

        -- README files
        readme = {
            icon = "",
            color = "#519aba",
            cterm_color = "67",
            name = "README"
        },
    },

    -- Override by filename
    override_by_filename = {
        [".gitignore"] = {
            icon = "",
            color = "#f1502f",
            name = "GitIgnore"
        },
        ["package.json"] = {
            icon = "",
            color = "#e8274b",
            name = "PackageJson"
        },
        ["package-lock.json"] = {
            icon = "",
            color = "#7a2048",
            name = "PackageLockJson"
        },
        ["composer.json"] = {
            icon = "",
            color = "#8892bf",
            name = "ComposerJson"
        },
        ["Dockerfile"] = {
            icon = "",
            color = "#384d54",
            name = "Dockerfile"
        },
        ["docker-compose.yml"] = {
            icon = "",
            color = "#384d54",
            name = "DockerCompose"
        },
        ["docker-compose.yaml"] = {
            icon = "",
            color = "#384d54",
            name = "DockerCompose"
        },
        [".env"] = {
            icon = "",
            color = "#faf743",
            name = "DotEnv"
        },
        [".env.local"] = {
            icon = "",
            color = "#faf743",
            name = "DotEnv"
        },
        [".env.example"] = {
            icon = "",
            color = "#faf743",
            name = "DotEnv"
        },
        ["README.md"] = {
            icon = "",
            color = "#519aba",
            name = "README"
        },
        ["LICENSE"] = {
            icon = "",
            color = "#cbcb41",
            name = "License"
        },
        ["Makefile"] = {
            icon = "",
            color = "#427819",
            name = "Makefile"
        },
        ["makefile"] = {
            icon = "",
            color = "#427819",
            name = "Makefile"
        },
    },

    -- Override by file extension
    override_by_extension = {
        ["log"] = {
            icon = "",
            color = "#81e043",
            name = "Log"
        },
        ["tmp"] = {
            icon = "",
            color = "#6d8086",
            name = "Temp"
        },
        ["bak"] = {
            icon = "",
            color = "#6d8086",
            name = "Backup"
        },
    },
})

-- Set up highlight groups for better integration
vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("DevIconsHighlight", { clear = true }),
    callback = function()
        -- Ensure devicons highlights are properly set after colorscheme changes
        devicons.refresh()
    end,
})

vim.notify("nvim-web-devicons configured successfully", vim.log.levels.INFO)
