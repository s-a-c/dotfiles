
-- ============================================================================
-- NEOVIM CONFIGURATION - MODULAR STRUCTURE
-- ============================================================================
-- Main entry point for Neovim configuration
-- This file loads the modular configuration structure

-- Load core configuration
require("config").setup()

do -- Plugin Installation and Management
    do -- echasnovski/mini.nvim bootstrap
        local path_package = vim.fn.stdpath('data') .. '/site'
        local mini_path = path_package .. '/pack/deps/start/mini.nvim'
        if not vim.loop.fs_stat(mini_path) then
        vim.cmd('echo "Installing `mini.nvim`" | redraw')
        local clone_cmd = {
            'git', 'clone', '--filter=blob:none',
            -- Uncomment next line to use 'stable' branch
            -- '--branch', 'stable',
            'https://github.com/echasnovski/mini.nvim', mini_path
        }
        vim.fn.system(clone_cmd)
        vim.cmd('packadd mini.nvim | helptags ALL')
        vim.cmd('echo "Installed `mini.nvim`" | redraw')
        end
    end

    vim.pack.add({ -- Plugin declarations
        { src = "https://github.com/vague2k/vague.nvim" },
        { src = "https://github.com/echasnovski/mini.nvim" },
        { src = "https://github.com/stevearc/oil.nvim" },
        { src = "https://github.com/folke/flash.nvim" }, -- Enhanced jump/search with labels
        { src = "https://github.com/nvim-lua/plenary.nvim" }, -- Required for telescope
        { src = "https://github.com/nvim-telescope/telescope.nvim" },
        { src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" }, -- Optional but recommended
        { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
        { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects" },
        { src = "https://github.com/neovim/nvim-lspconfig" },
        { src = "https://github.com/mason-org/mason.nvim" },
        { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
        { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
        { src = "https://github.com/ThePrimeagen/harpoon" },
        { src = "https://github.com/mbbill/undotree" },
        { src = "https://github.com/tpope/vim-fugitive" },
        { src = "https://github.com/kevinhwang91/nvim-ufo" }, -- Advanced folding
        { src = "https://github.com/kevinhwang91/promise-async" }, -- Required for nvim-ufo
        { src = "https://github.com/chomosuke/typst-preview.nvim" },
        { src = "https://github.com/saghen/blink.cmp", checkout = "v0.*" }, -- Modern completion engine with version pin
        -- UI and Dashboard
        { src = "https://github.com/folke/snacks.nvim" }, -- Modern UI components and dashboard
        { src = "https://github.com/folke/which-key.nvim" }, -- Key mapping helper
        { src = "https://github.com/folke/noice.nvim" }, -- Modern UI replacements (command popup, messages, etc.)
        { src = "https://github.com/MunifTanjim/nui.nvim" }, -- Required for Laravel.nvim

        -- Note taking and organization
        { src = "https://github.com/nvim-neorg/neorg" }, -- Note taking and organization (re-enabled with safer config)

        -- Telescope extensions
        { src = "https://github.com/jvgrootveld/telescope-zoxide" }, -- Zoxide integration
        { src = "https://github.com/nvim-neorg/neorg-telescope" }, -- Neorg telescope integration (re-enabled)
        { src = "https://github.com/gbirke/telescope-foldmarkers.nvim" }, -- Fold markers search (corrected URL)
        { src = "https://github.com/zschreur/telescope-jj.nvim" }, -- Jujutsu VCS integration (corrected URL)
        { src = "https://github.com/nvim-telescope/telescope-github.nvim" }, -- GitHub integration
        { src = "https://github.com/nvim-telescope/telescope-media-files.nvim" }, -- Media files preview
        { src = "https://github.com/nvim-telescope/telescope-fzf-writer.nvim" }, -- FZF writer
        { src = "https://github.com/nvim-telescope/telescope-symbols.nvim" }, -- Symbol picker
        { src = "https://github.com/olacin/telescope-cc.nvim" }, -- Conventional commits (corrected URL)
        { src = "https://github.com/sudormrfbin/cheatsheet.nvim" }, -- Cheatsheet
        { src = "https://github.com/nat-418/telescope-color-names.nvim" }, -- Color names (corrected URL)
        { src = "https://github.com/octarect/telescope-menu.nvim" }, -- Menu system
        { src = "https://github.com/debugloop/telescope-undo.nvim" }, -- Undo tree

        -- Debugging
        { src = "https://github.com/mfussenegger/nvim-dap" }, -- Debug adapter protocol
        { src = "https://github.com/nvim-telescope/telescope-dap.nvim" }, -- DAP telescope integration
        -- Themes
        { src = "https://github.com/catppuccin/nvim" },
        { src = "https://github.com/rebelot/kanagawa.nvim" },

        -- Laravel Development
        { src = "https://github.com/adalessa/laravel.nvim" }, -- Comprehensive Laravel plugin
        { src = "https://github.com/ricardoramirezr/blade-nav.nvim" }, -- Blade navigation and completion
        { src = "https://github.com/jwalton512/vim-blade" }, -- Blade syntax highlighting

        -- AI Assistance
        { src = "https://github.com/github/copilot.vim" }, -- GitHub Copilot
        { src = "https://github.com/augmentcode/augment.vim" }, -- Augment AI code suggestions
        { src = "https://github.com/Exafunction/codeium.nvim" }, -- Local AI and cloud AI support

        -- LM Studio / Local LLM Integration
        { src = "https://github.com/olimorris/codecompanion.nvim" }, -- AI coding companion with local LLM support
        { src = "https://github.com/David-Kunz/gen.nvim" }, -- Local AI text generation plugin

        -- Command line enhancement
        { src = "https://github.com/gelguy/wilder.nvim" }, -- Enhanced command line completion and wildmenu
    })
end

do -- Telescope Configuration
    local telescope = require('telescope')
    local actions = require('telescope.actions')

    telescope.setup({
        defaults = {
            -- UI Configuration
            prompt_prefix = "🔍 ",
            selection_caret = "➤ ",
            entry_prefix = "  ",
            initial_mode = "insert",
            selection_strategy = "reset",
            sorting_strategy = "ascending",
            layout_strategy = "horizontal",
            layout_config = {
                horizontal = {
                    prompt_position = "top",
                    preview_width = 0.55,
                    results_width = 0.8,
                },
                vertical = {
                    mirror = false,
                },
                width = 0.87,
                height = 0.80,
                preview_cutoff = 120,
            },
            file_sorter = require('telescope.sorters').get_fuzzy_file,
            file_ignore_patterns = { "node_modules", ".git/", "dist/", "build/", "*.lock" },
            generic_sorter = require('telescope.sorters').get_generic_fuzzy_sorter,
            winblend = 0,
            border = {},
            borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
            color_devicons = true,
            use_less = true,
            path_display = {},
            set_env = { ["COLORTERM"] = "truecolor" },
            file_previewer = require('telescope.previewers').vim_buffer_cat.new,
            grep_previewer = require('telescope.previewers').vim_buffer_vimgrep.new,
            qflist_previewer = require('telescope.previewers').vim_buffer_qflist.new,
            buffer_previewer_maker = require('telescope.previewers').buffer_previewer_maker,

            -- Enhanced mappings
            mappings = {
                i = {
                    -- Navigation
                    ["<C-n>"] = actions.move_selection_next,
                    ["<C-p>"] = actions.move_selection_previous,
                    ["<C-c>"] = actions.close,
                    ["<C-j>"] = actions.move_selection_next,
                    ["<C-k>"] = actions.move_selection_previous,
                    ["<Down>"] = actions.move_selection_next,
                    ["<Up>"] = actions.move_selection_previous,

                    -- Selection
                    ["<CR>"] = actions.select_default,
                    ["<C-x>"] = actions.select_horizontal,
                    ["<C-v>"] = actions.select_vertical,
                    ["<C-t>"] = actions.select_tab,

                    -- Preview scrolling
                    ["<C-u>"] = actions.preview_scrolling_up,
                    ["<C-d>"] = actions.preview_scrolling_down,
                    ["<PageUp>"] = actions.results_scrolling_up,
                    ["<PageDown>"] = actions.results_scrolling_down,

                    -- Multi-selection
                    ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
                    ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
                    ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                    ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

                    -- Utility
                    ["<C-l>"] = actions.complete_tag,
                    ["<C-_>"] = actions.which_key,
                    ["<C-w>"] = { "<c-s-w>", type = "command" },
                    ["<C-r><C-w>"] = actions.insert_original_cword,
                },
                n = {
                    -- Navigation
                    ["<esc>"] = actions.close,
                    ["<CR>"] = actions.select_default,
                    ["<C-x>"] = actions.select_horizontal,
                    ["<C-v>"] = actions.select_vertical,
                    ["<C-t>"] = actions.select_tab,

                    -- Movement
                    ["j"] = actions.move_selection_next,
                    ["k"] = actions.move_selection_previous,
                    ["H"] = actions.move_to_top,
                    ["M"] = actions.move_to_middle,
                    ["L"] = actions.move_to_bottom,
                    ["<Down>"] = actions.move_selection_next,
                    ["<Up>"] = actions.move_selection_previous,
                    ["gg"] = actions.move_to_top,
                    ["G"] = actions.move_to_bottom,
                    ["q"] = actions.close,

                    -- Multi-selection
                    ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
                    ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
                    ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                    ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

                    -- Preview scrolling
                    ["<C-u>"] = actions.preview_scrolling_up,
                    ["<C-d>"] = actions.preview_scrolling_down,
                    ["<PageUp>"] = actions.results_scrolling_up,
                    ["<PageDown>"] = actions.results_scrolling_down,

                    -- Utility
                    ["?"] = actions.which_key,
                    ["dd"] = require("telescope.actions").delete_buffer,
                },
            },
        },
        pickers = {
            -- Enhanced picker configurations
            find_files = {
                theme = "dropdown",
                previewer = false,
                hidden = true,
                find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
            },
            live_grep = {
                additional_args = function(opts)
                    return {"--hidden"}
                end
            },
            grep_string = {
                additional_args = function(opts)
                    return {"--hidden"}
                end
            },
            buffers = {
                theme = "dropdown",
                previewer = false,
                initial_mode = "normal",
                mappings = {
                    i = {
                        ["<C-d>"] = actions.delete_buffer,
                    },
                    n = {
                        ["dd"] = actions.delete_buffer,
                    }
                }
            },
            colorscheme = {
                enable_preview = true,
            },
            lsp_references = {
                theme = "dropdown",
                initial_mode = "normal",
            },
            lsp_definitions = {
                theme = "dropdown",
                initial_mode = "normal",
            },
            lsp_declarations = {
                theme = "dropdown",
                initial_mode = "normal",
            },
            lsp_implementations = {
                theme = "dropdown",
                initial_mode = "normal",
            },
            lsp_type_definitions = {
                theme = "dropdown",
                initial_mode = "normal",
            },
            diagnostics = {
                theme = "ivy",
                initial_mode = "normal",
            },
            git_files = {
                theme = "dropdown",
                previewer = false,
            },
            oldfiles = {
                theme = "dropdown",
                previewer = false,
            },
            command_history = {
                theme = "dropdown",
            },
            search_history = {
                theme = "dropdown",
            },
            help_tags = {
                theme = "ivy",
            },
            man_pages = {
                theme = "ivy",
            },
            marks = {
                theme = "dropdown",
                previewer = false,
            },
            jumps = {
                theme = "dropdown",
                previewer = false,
            },
            vim_options = {
                theme = "dropdown",
            },
            registers = {
                theme = "dropdown",
            },
            autocommands = {
                theme = "ivy",
            },
            spell_suggest = {
                theme = "cursor",
            },
        },
        extensions = {
            -- FZF native extension for better performance
            fzf = {
                fuzzy = true,                    -- false will only do exact matching
                override_generic_sorter = true,  -- override the generic sorter
                override_file_sorter = true,     -- override the file sorter
                case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
            },

            -- Media files extension for image/video preview
            media_files = {
                filetypes = {"png", "webp", "jpg", "jpeg", "gif", "mp4", "webm", "pdf"},
                find_cmd = "rg",
                preview = {
                    check_mime_type = true,
                }
            },

            -- Undo extension for visual undo tree
            undo = {
                use_delta = true,
                use_custom_command = nil,
                side_by_side = false,
                vim_diff_opts = { ctxlen = vim.o.scrolloff },
                entry_format = "state #$ID, $STAT, $TIME",
                time_format = "",
                saved_only = false,
                mappings = {
                    i = {
                        ["<cr>"] = require("telescope-undo.actions").yank_additions,
                        ["<S-cr>"] = require("telescope-undo.actions").yank_deletions,
                        ["<C-cr>"] = require("telescope-undo.actions").restore,
                    },
                    n = {
                        ["y"] = require("telescope-undo.actions").yank_additions,
                        ["Y"] = require("telescope-undo.actions").yank_deletions,
                        ["u"] = require("telescope-undo.actions").restore,
                    },
                },
            },

            -- Zoxide extension for smart directory jumping
            zoxide = {
                prompt_title = "[ Walking on the shoulders of TJ ]",
                mappings = {
                    default = {
                        after_action = function(selection)
                            print("Update to (" .. selection.z_score .. ") " .. selection.path)
                        end
                    },
                    ["<C-s>"] = {
                        before_action = function(selection) print("before C-s") end,
                        action = function(selection)
                            vim.cmd.edit(selection.path)
                        end
                    },
                    ["<C-q>"] = { action = "file_vsplit" },
                    ["<C-e>"] = { action = "file_edit" },
                    ["<C-b>"] = {
                        keepinsert = true,
                        action = function(selection)
                            require("telescope.builtin").file_browser({ cwd = selection.path })
                        end
                    },
                    ["<C-f>"] = {
                        keepinsert = true,
                        action = function(selection)
                            require("telescope.builtin").find_files({ cwd = selection.path })
                        end
                    },
                },
            },

            -- GitHub extension
            gh = {
                wrap_lines = true,
            },

            -- DAP extension for debugging
            dap = {},

            -- Symbols extension
            symbols = {
                sources = {'emoji', 'kaomoji', 'gitmoji'},
            },

            -- Conventional commits extension
            conventional_commits = {
                theme = "dropdown",
                action = function(entry)
                    vim.ui.input({ prompt = entry.display .. " " }, function(msg)
                        if not msg then return end
                        vim.cmd("Git commit -m '" .. entry.value .. msg .. "'")
                    end)
                end,
                include_body_and_footer = true,
            },

            -- Menu extension
            menu = {
                default = {
                    items = {
                        { display = "Find Files", value = "find_files" },
                        { display = "Live Grep", value = "live_grep" },
                        { display = "Buffers", value = "buffers" },
                        { display = "Help Tags", value = "help_tags" },
                        { display = "Recent Files", value = "oldfiles" },
                        { display = "Git Files", value = "git_files" },
                        { display = "Git Status", value = "git_status" },
                        { display = "Git Commits", value = "git_commits" },
                        { display = "Colorschemes", value = "colorscheme" },
                        { display = "Keymaps", value = "keymaps" },
                    }
                }
            },

            -- Fold markers extension
            foldmarkers = {},

            -- Color names extension
            color_names = {
                enable_preview = true,
            },

            -- Cheatsheet extension
            cheatsheet = {
                theme = "dropdown",
            },

            -- FZF writer extension
            fzf_writer = {
                minimum_grep_characters = 2,
                minimum_files_characters = 2,
                use_highlighter = true,
            },

            -- Jujutsu VCS extension
            jj = {},

            -- Neorg extension
            neorg = {},
        }
    })

    do -- Load telescope extensions
        pcall(require('telescope').load_extension, 'fzf')
        pcall(require('telescope').load_extension, 'zoxide')
        pcall(require('telescope').load_extension, 'neorg')
        pcall(require('telescope').load_extension, 'foldmarkers') -- Re-enabled with correct URL
        pcall(require('telescope').load_extension, 'jj') -- Re-enabled with correct URL
        pcall(require('telescope').load_extension, 'gh')
        pcall(require('telescope').load_extension, 'media_files')
        pcall(require('telescope').load_extension, 'fzf_writer')
        pcall(require('telescope').load_extension, 'symbols')
        pcall(require('telescope').load_extension, 'conventional_commits') -- Re-enabled with correct URL
        pcall(require('telescope').load_extension, 'cheatsheet')
        pcall(require('telescope').load_extension, 'color_names') -- Re-enabled with correct URL
        pcall(require('telescope').load_extension, 'menu')
        pcall(require('telescope').load_extension, 'undo')
        pcall(require('telescope').load_extension, 'dap')
    end

    do -- Telescope key mappings
        local builtin = require('telescope.builtin')

        -- Core telescope mappings
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
        vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Buffers' })
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })
        vim.keymap.set('n', '<leader>fr', builtin.oldfiles, { desc = 'Recent files' })
        vim.keymap.set('n', '<leader>fs', builtin.current_buffer_fuzzy_find, { desc = 'Search in current buffer' })
        vim.keymap.set('n', '<leader>fc', builtin.commands, { desc = 'Commands' })
        vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Keymaps' })
        vim.keymap.set('n', '<leader>f', builtin.find_files, { desc = 'Find files' })
        vim.keymap.set('n', '<leader>h', builtin.help_tags, { desc = 'Help tags' })

        -- Extension mappings
        vim.keymap.set('n', '<leader>tz', '<cmd>Telescope zoxide list<cr>', { desc = 'Zoxide' })
        vim.keymap.set('n', '<leader>tu', '<cmd>Telescope undo<cr>', { desc = 'Undo tree' })
        vim.keymap.set('n', '<leader>tm', '<cmd>Telescope media_files<cr>', { desc = 'Media files' })
        vim.keymap.set('n', '<leader>ts', '<cmd>Telescope symbols<cr>', { desc = 'Symbols' })
        vim.keymap.set('n', '<leader>tc', '<cmd>Telescope cheatsheet<cr>', { desc = 'Cheatsheet' })
        vim.keymap.set('n', '<leader>tC', '<cmd>Telescope color_names<cr>', { desc = 'Color names' }) -- Re-enabled with correct URL
        vim.keymap.set('n', '<leader>tM', '<cmd>Telescope menu<cr>', { desc = 'Menu' })
        vim.keymap.set('n', '<leader>tj', '<cmd>Telescope jj<cr>', { desc = 'Jujutsu VCS' }) -- New mapping for Jujutsu
        vim.keymap.set('n', '<leader>tf', '<cmd>Telescope foldmarkers<cr>', { desc = 'Fold markers' }) -- Re-enabled with correct URL
        vim.keymap.set('n', '<leader>tcc', '<cmd>Telescope conventional_commits<cr>', { desc = 'Conventional commits' }) -- New mapping

        -- Git/GitHub mappings
        vim.keymap.set('n', '<leader>gi', '<cmd>Telescope gh issues<cr>', { desc = 'GitHub issues' })
        vim.keymap.set('n', '<leader>gp', '<cmd>Telescope gh pull_request<cr>', { desc = 'GitHub PRs' })
        vim.keymap.set('n', '<leader>gr', '<cmd>Telescope gh run<cr>', { desc = 'GitHub runs' })

        -- Debug mappings
        vim.keymap.set('n', '<leader>dc', '<cmd>Telescope dap commands<cr>', { desc = 'DAP commands' })
        vim.keymap.set('n', '<leader>db', '<cmd>Telescope dap list_breakpoints<cr>', { desc = 'DAP breakpoints' })
        vim.keymap.set('n', '<leader>dv', '<cmd>Telescope dap variables<cr>', { desc = 'DAP variables' })
        vim.keymap.set('n', '<leader>df', '<cmd>Telescope dap frames<cr>', { desc = 'DAP frames' })

        -- Neorg mappings
        vim.keymap.set('n', '<leader>nf', '<cmd>Telescope neorg find_linkable<cr>', { desc = 'Find linkable' })
        vim.keymap.set('n', '<leader>nh', '<cmd>Telescope neorg search_headings<cr>', { desc = 'Search headings' })
        vim.keymap.set('n', '<leader>ni', '<cmd>Telescope neorg insert_link<cr>', { desc = 'Insert link' })
        vim.keymap.set('n', '<leader>nF', '<cmd>Telescope neorg insert_file_link<cr>', { desc = 'Insert file link' })
    end
end

do -- Editor Options and Settings
    vim.o.clipboard = "unnamedplus"
    vim.o.expandtab = true
    vim.o.number = true
    vim.o.relativenumber = true
    vim.o.signcolumn = "yes"
    vim.o.smartindent = true
    vim.o.softtabstop = 4
    vim.o.swapfile = false
    vim.o.tabstop = 4
    vim.o.termguicolors = true
    vim.o.winborder = "rounded"
    vim.o.wrap = true
end

do -- Key Mappings
    -- File operations
    vim.keymap.set('n', '<leader>o', ':update<CR> :source<CR>')
    vim.keymap.set('n', '<leader>w', ':write<CR>')
    vim.keymap.set('n', '<leader>q', ':quit<CR>')

    -- Clipboard operations
    vim.keymap.set({ 'n', 'v', 'x' }, '<leader>y', '"+y<CR>')
    vim.keymap.set({ 'n', 'v', 'x' }, '<leader>d', '"+d<CR>')

    -- File explorer
    vim.keymap.set('n', '<leader>e', ":Oil<CR>")

    -- LSP mappings
    vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)

    -- Mason mappings
    vim.keymap.set('n', '<leader>lm', '<cmd>Mason<cr>', { desc = 'Mason' })
    vim.keymap.set('n', '<leader>li', '<cmd>MasonInstall ', { desc = 'Mason install' })
    vim.keymap.set('n', '<leader>lu', '<cmd>MasonUpdate<cr>', { desc = 'Mason update' })
    vim.keymap.set('n', '<leader>ls', '<cmd>MasonUninstall ', { desc = 'Mason uninstall' })
end

do -- Mason and LSP Configuration
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
            "lua_ls",
            "biome",
            "tinymist",
            "emmet_ls", -- Note: emmet_ls in Mason, not emmetls
            "phpactor", -- PHP LSP server
            "tailwindcss", -- Tailwind CSS LSP server
        },
        automatic_installation = true,
    })

    -- Mason-tool-installer for additional tools
    require('mason-tool-installer').setup({
        ensure_installed = {
            "lua_ls",
            "stylua", -- Lua formatter
            "biome",
            "tinymist",
            "emmet_ls",
            "phpactor", -- PHP LSP server
            "tailwindcss", -- Tailwind CSS LSP server
        },
        auto_update = true, -- Set to true if you want automatic updates
        run_on_start = true,
    })

    -- LSP configuration with enhanced Lua settings
    local lspconfig = require('lspconfig')

    -- Lua LSP configuration
    lspconfig.lua_ls.setup({
        settings = {
            Lua = {
                runtime = {
                    version = 'LuaJIT',
                },
                diagnostics = {
                    globals = {
                        'vim',
                        'require'
                    },
                },
                workspace = {
                    library = vim.api.nvim_get_runtime_file("", true),
                },
                telemetry = {
                    enable = false,
                },
            },
        },
    })

    -- LSP attach configuration
    vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
            -- Blink.cmp handles completion, so we don't need to enable native completion
            local client = vim.lsp.get_client_by_id(ev.data.client_id)

            -- Optional: Add LSP-specific keymaps here
            local opts = { buffer = ev.buf }
            vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
            vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
            vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
            vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
            vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
            vim.keymap.set("n", "[d", vim.diagnostic.goto_next, opts)
            vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, opts)
            vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
            vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
            vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
            vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
        end,
    })

    -- Manual PHP LSP configuration for Devsense PHP LS (keeping your existing setup)
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "php",
        callback = function()
            vim.lsp.start({
                name = "devsense-php-ls",
                cmd = { "devsense-php-ls" }, -- Adjust this if the command is different
                root_dir = vim.fs.dirname(vim.fs.find({"composer.json", ".git"}, { upward = true })[1]),
                settings = {
                    php = {
                        completion = {
                            enabled = true,
                        },
                        diagnostics = {
                            enabled = true,
                        },
                        format = {
                            enabled = true,
                        },
                    },
                },
            })
        end,
    })
end

do -- Plugin Configurations

    -- Load essential plugins first
    vim.cmd('packadd plenary.nvim')
    vim.cmd('packadd nui.nvim')
    vim.cmd('packadd promise-async')

    -- Build blink.cmp from source if needed
    do -- Blink.cmp build check and setup
        local blink_path = vim.fn.stdpath('data') .. '/site/pack/deps/start/blink.cmp'
        local target_dir = blink_path .. '/target/release'

        -- Force rebuild if checkout version exists (cleanup old version)
        if vim.fn.isdirectory(blink_path) == 1 then
            local git_cmd = 'cd ' .. blink_path .. ' && git describe --tags 2>/dev/null'
            local current_ref = vim.fn.system(git_cmd)
            if string.match(current_ref, 'v0%.') then
                vim.cmd('echo "Removing old blink.cmp version..." | redraw')
                vim.fn.delete(blink_path, 'rf')
            end
        end

        -- Check if binary exists, if not build it
        if vim.fn.isdirectory(blink_path) == 1 and vim.fn.isdirectory(target_dir) == 0 then
            vim.cmd('echo "Building blink.cmp from source..." | redraw')
            local build_cmd = 'cd ' .. blink_path .. ' && cargo build --release'
            local result = vim.fn.system(build_cmd)
            if vim.v.shell_error == 0 then
                vim.cmd('echo "blink.cmp built successfully" | redraw')
            else
                vim.cmd('echo "Failed to build blink.cmp: ' .. result .. '" | redraw')
            end
        end
    end

    do -- Debug Adapter Protocol (DAP) configuration
        local dap = require('dap')

        -- Basic DAP configuration for common languages
        -- JavaScript/TypeScript (Node.js)
        dap.adapters.node2 = {
            type = 'executable',
            command = 'node',
            args = { vim.fn.stdpath('data') .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js' },
        }

        dap.configurations.javascript = {
            {
                name = 'Launch',
                type = 'node2',
                request = 'launch',
                program = '${file}',
                cwd = vim.fn.getcwd(),
                sourceMaps = true,
                protocol = 'inspector',
                console = 'integratedTerminal',
            },
        }

        dap.configurations.typescript = dap.configurations.javascript
    end

    -- Flash.nvim Configuration - Enhanced jump/search with labels
    do
        require("flash").setup({
            -- Flash configuration
            labels = "asdfghjklqwertyuiopzxcvbnm",
            search = {
                -- search/jump in all windows
                multi_window = true,
                -- search direction
                forward = true,
                -- when `false`, find only matches in the given direction
                wrap = true,
                -- Each mode will take ignorecase and smartcase into account.
                -- * exact: exact match
                -- * search: regular search
                -- * fuzzy: fuzzy search
                -- * fun(str): custom function that returns a pattern
                --   For example, to only match at the beginning of a word:
                --   mode = function(str)
                --     return "\\<" .. str
                --   end,
                mode = "exact",
                -- behave like `incsearch`
                incremental = false,
                -- Excluded filetypes and buftypes from flash
                exclude = {
                    "notify",
                    "cmp_menu",
                    "noice",
                    "flash_prompt",
                },
            },
            jump = {
                -- save location in the jumplist
                jumplist = true,
                -- jump position
                pos = "start", -- "start" / "end" / "range"
                -- add pattern to search history
                history = false,
                -- add pattern to search register
                register = false,
                -- clear highlight after jump
                nohlsearch = false,
                -- automatically jump when there is only one match
                autojump = false,
            },
            label = {
                -- allow uppercase labels
                uppercase = true,
                -- add any labels with the correct case here, that you want to exclude
                exclude = "",
                -- add a label for the first match in the current window.
                -- you can always jump to the first match with `<CR>`
                current = true,
                -- show the label after the match
                after = true, ---@type boolean|number[]
                -- show the label before the match
                before = false, ---@type boolean|number[]
                -- position of the label extmark
                style = "overlay", ---@type "eol" | "overlay" | "right_align" | "inline"
                -- flash tries to re-use labels that were already assigned to a position,
                -- when typing more characters. By default only lower-case labels are re-used.
                reuse = "lowercase", ---@type "lowercase" | "all" | "none"
                -- for the current window, label targets closer to the cursor first
                distance = true,
                -- minimum pattern length to show labels
                -- Ignored for custom labelers.
                min_pattern_length = 0,
                -- Enable this to use rainbow colors to highlight labels
                -- Can be useful for visualizing Treesitter ranges.
                rainbow = {
                    enabled = false,
                    -- number between 1 and 9
                    shade = 5,
                },
            },
            highlight = {
                -- show a backdrop with hl FlashBackdrop
                backdrop = true,
                -- Highlight the search matches
                matches = true,
                -- extmark priority
                priority = 5000,
                groups = {
                    match = "FlashMatch",
                    current = "FlashCurrent",
                    backdrop = "FlashBackdrop",
                    label = "FlashLabel",
                },
            },
            -- action to perform when picking a label.
            -- defaults to the jumping logic depending on the mode.
            action = nil, ---@type fun(match:Flash.Match, state:Flash.State)|nil
            -- initial pattern to use when opening flash
            pattern = "",
            -- When `true`, flash will try to continue the last search
            continue = false,
            -- Set config for ftFT motions
            config = nil, ---@type fun(opts:Flash.Config)|nil
            -- You can override the default options for a specific mode.
            -- Use it with `require("flash").jump({mode = "forward"})`
            modes = {
                -- options used when flash is activated through
                -- a regular search with `/` or `?`
                search = {
                    -- when `true`, flash will be activated during regular search by default.
                    -- You can always toggle when searching with `require("flash").toggle()`
                    enabled = true,
                    highlight = { backdrop = false },
                    jump = { history = true, register = true, nohlsearch = true },
                    search = {
                        -- `forward` will be automatically set to the search direction
                        -- `mode` is always set to `search`
                        -- `incremental` is set to `true` when `incsearch` is enabled
                    },
                },
                -- options used when flash is activated through
                -- `f`, `F`, `t`, `T`, `;` and `,` motions
                char = {
                    enabled = true,
                    -- dynamic configuration for ftFT motions
                    config = function(opts)
                        -- autohide flash when in operator-pending mode
                        opts.autohide = opts.autohide or (vim.fn.mode(true):find("no") and vim.v.operator == "y")

                        -- disable jump labels when not enabled, when using a count,
                        -- or when recording/executing registers
                        opts.jump_labels = opts.jump_labels
                            and vim.v.count == 0
                            and vim.fn.reg_executing() == ""
                            and vim.fn.reg_recording() == ""

                        -- Show jump labels only in operator-pending mode
                        -- opts.jump_labels = vim.v.count == 0 and vim.fn.mode(true):find("o")
                    end,
                    -- hide after jump when not using jump labels
                    autohide = false,
                    -- show jump labels
                    jump_labels = false,
                    -- set to `false` to use the current line only
                    multi_line = true,
                    -- When using jump labels, don't use these keys
                    -- This allows using those keys directly after the motion
                    label = { exclude = "hjkliardc" },
                    -- by default all keymaps are enabled, but you can disable some of them,
                    -- by removing them from the list.
                    -- If you rather not use default keymaps at all, set this to an empty table: {}
                    keys = { "f", "F", "t", "T", ";", "," },
                    ---@type number
                    char_actions = function(motion)
                        return {
                            [";"] = "next", -- set to `right` to always go right
                            [","] = "prev", -- set to `left` to always go left
                            -- clever-f style
                            [motion:lower()] = "next",
                            [motion:upper()] = "prev",
                            -- jump2d style: same case goes next, opposite case goes prev
                            -- [motion] = "next",
                            -- [motion:match("%l") and motion:upper() or motion:lower()] = "prev",
                        }
                    end,
                    search = { wrap = false },
                    highlight = { backdrop = true },
                    jump = { register = false },
                },
                -- options used for treesitter selections
                -- `require("flash").treesitter()`
                treesitter = {
                    labels = "abcdefghijklmnopqrstuvwxyz",
                    jump = { pos = "range" },
                    search = { incremental = false },
                    label = { before = true, after = true, style = "inline" },
                    highlight = {
                        backdrop = false,
                        matches = false,
                    },
                },
                treesitter_search = {
                    jump = { pos = "range" },
                    search = { multi_window = true, wrap = true, incremental = false },
                    remote_op = { restore = true },
                    label = { before = true, after = true, style = "inline" },
                },
                -- options used for remote flash
                remote = {
                    remote_op = { restore = true, motion = true },
                },
            },
        })

        -- Flash keymaps
        vim.keymap.set({ "n", "x", "o" }, "s", function()
            require("flash").jump()
        end, { desc = "Flash" })

        vim.keymap.set({ "n", "x", "o" }, "S", function()
            require("flash").treesitter()
        end, { desc = "Flash Treesitter" })

        vim.keymap.set("o", "r", function()
            require("flash").remote()
        end, { desc = "Remote Flash" })

        vim.keymap.set({ "o", "x" }, "R", function()
            require("flash").treesitter_search()
        end, { desc = "Treesitter Search" })

        vim.keymap.set("c", "<c-s>", function()
            require("flash").toggle()
        end, { desc = "Toggle Flash Search" })

        -- Additional useful flash keymaps
        vim.keymap.set("n", "<leader>s", function()
            require("flash").jump()
        end, { desc = "Flash jump" })

        vim.keymap.set("n", "<leader>S", function()
            require("flash").treesitter()
        end, { desc = "Flash treesitter" })

        -- Flash integration with telescope
        vim.keymap.set("n", "<leader>fs", function()
            require("flash").jump({
                search = { mode = "search", max_length = 0 },
                label = { after = { 0, 0 } },
                pattern = "^"
            })
        end, { desc = "Flash search lines" })
    end

    -- Fugitive Configuration - Git integration
    do
        -- Fugitive keymaps
        vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git status" })
        vim.keymap.set("n", "<leader>ga", "<cmd>Git add .<cr>", { desc = "Git add all" })
        vim.keymap.set("n", "<leader>gA", "<cmd>Git add %<cr>", { desc = "Git add current file" })
        vim.keymap.set("n", "<leader>gc", "<cmd>Git commit<cr>", { desc = "Git commit" })
        vim.keymap.set("n", "<leader>gC", "<cmd>Git commit --amend<cr>", { desc = "Git commit amend" })
        vim.keymap.set("n", "<leader>gp", "<cmd>Git push<cr>", { desc = "Git push" })
        vim.keymap.set("n", "<leader>gP", "<cmd>Git pull<cr>", { desc = "Git pull" })
        vim.keymap.set("n", "<leader>gf", "<cmd>Git fetch<cr>", { desc = "Git fetch" })
        vim.keymap.set("n", "<leader>gl", "<cmd>Git log --oneline<cr>", { desc = "Git log" })
        vim.keymap.set("n", "<leader>gL", "<cmd>Git log<cr>", { desc = "Git log detailed" })
        vim.keymap.set("n", "<leader>gd", "<cmd>Gdiffsplit<cr>", { desc = "Git diff split" })
        vim.keymap.set("n", "<leader>gD", "<cmd>Gdiffsplit HEAD<cr>", { desc = "Git diff HEAD" })
        vim.keymap.set("n", "<leader>gb", "<cmd>Git blame<cr>", { desc = "Git blame" })
        vim.keymap.set("n", "<leader>gB", "<cmd>GBrowse<cr>", { desc = "Git browse" })
        vim.keymap.set("n", "<leader>gr", "<cmd>Gread<cr>", { desc = "Git read (checkout file)" })
        vim.keymap.set("n", "<leader>gw", "<cmd>Gwrite<cr>", { desc = "Git write (stage file)" })
        vim.keymap.set("n", "<leader>gx", "<cmd>GDelete<cr>", { desc = "Git delete file" })
        vim.keymap.set("n", "<leader>gm", "<cmd>GMove<cr>", { desc = "Git move/rename file" })

        -- Git branch operations
        vim.keymap.set("n", "<leader>gco", "<cmd>Git checkout<cr>", { desc = "Git checkout" })
        vim.keymap.set("n", "<leader>gcb", "<cmd>Git checkout -b ", { desc = "Git checkout new branch" })
        vim.keymap.set("n", "<leader>gM", "<cmd>Git merge<cr>", { desc = "Git merge" })

        -- Git stash operations
        vim.keymap.set("n", "<leader>gss", "<cmd>Git stash<cr>", { desc = "Git stash" })
        vim.keymap.set("n", "<leader>gsp", "<cmd>Git stash pop<cr>", { desc = "Git stash pop" })
        vim.keymap.set("n", "<leader>gsl", "<cmd>Git stash list<cr>", { desc = "Git stash list" })

        -- Conflict resolution
        vim.keymap.set("n", "<leader>gh", "<cmd>diffget //2<cr>", { desc = "Get left (HEAD)" })
        vim.keymap.set("n", "<leader>gj", "<cmd>diffget //3<cr>", { desc = "Get right (merge)" })
    end

    do -- Laravel configuration
        -- Load Laravel.nvim dependencies first
        vim.cmd('packadd nui.nvim')
        vim.cmd('packadd promise-async')

        -- Laravel.nvim configuration
        require("laravel").setup({
            lsp_server = "phpactor", -- Use phpactor as LSP server
            -- Use snacks picker since you have snacks.nvim configured
            default_picker = "snacks",
            -- Alternatively, use telescope since you have extensive telescope setup
            -- default_picker = "telescope",
        })

        -- Blade-nav.nvim configuration
        require("blade-nav").setup({
            -- This setting works for blink.cmp
            close_tag_on_complete = true, -- default: true
        })

        do -- Laravel key mappings
            -- Artisan commands
            vim.keymap.set('n', '<leader>aa', '<cmd>Laravel artisan<cr>', { desc = 'Artisan commands' })
            vim.keymap.set('n', '<leader>ar', '<cmd>Laravel routes<cr>', { desc = 'Laravel routes' })
            vim.keymap.set('n', '<leader>am', '<cmd>Laravel make<cr>', { desc = 'Laravel make' })

            -- Laravel development
            vim.keymap.set('n', '<leader>av', '<cmd>Laravel view_finder<cr>', { desc = 'View finder' })
            vim.keymap.set('n', '<leader>ac', '<cmd>Laravel composer<cr>', { desc = 'Composer commands' })
            vim.keymap.set('n', '<leader>at', '<cmd>Laravel tinker<cr>', { desc = 'Laravel Tinker' })

            -- Route navigation (blade-nav provides this)
            vim.keymap.set('n', '<leader>ao', '<cmd>Laravel route:open<cr>', { desc = 'Open route in browser' })
        end
    end

    do -- Neorg configuration with safe loading to avoid circular dependencies
        pcall(function()
            -- Only load neorg if it's available and properly installed
            local neorg_ok, neorg = pcall(require, "neorg")
            if neorg_ok then
                neorg.setup({
                    load = {
                        ["core.defaults"] = {},
                        ["core.concealer"] = {
                            config = {
                                icon_preset = "basic", -- Use basic icons to avoid font issues
                            }
                        },
                        ["core.dirman"] = {
                            config = {
                                workspaces = {
                                    notes = "~/notes",
                                    work = "~/work-notes",
                                },
                                default_workspace = "notes",
                            }
                        },
                        -- Skip completion module to avoid conflicts with blink.cmp
                        -- ["core.completion"] = {
                        --     config = {
                        --         engine = "nvim-cmp",
                        --     }
                        -- },
                        ["core.integrations.telescope"] = {},
                    },
                })
            end
        end)
    end

    -- Noice.nvim Configuration - Modern UI with popup command line
    do
        require("noice").setup({
            lsp = {
                -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
                },
            },
            -- you can enable a preset for easier configuration
            presets = {
                bottom_search = true, -- use a classic bottom cmdline for search
                command_palette = true, -- position the cmdline and popupmenu together
                long_message_to_split = true, -- long messages will be sent to a split
                inc_rename = false, -- enables an input dialog for inc-rename.nvim
                lsp_doc_border = false, -- add a border to hover docs and signature help
            },
            cmdline = {
                enabled = true, -- enables the Noice cmdline UI
                view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
                opts = {}, -- global options for the cmdline. See section on views
                ---@type table<string, CmdlineFormat>
                format = {
                    -- conceal: (default=true) This will hide the text in the cmdline that matches the pattern.
                    -- view: (default is cmdline view)
                    -- opts: any options passed to the view
                    -- icon_hl_group: optional hl_group for the icon
                    -- title: set to anything or empty string to hide
                    cmdline = { pattern = "^:", icon = "", lang = "vim" },
                    search_down = { pattern = "^/", icon = " ", lang = "regex" },
                    search_up = { pattern = "^%?", icon = " ", lang = "regex" },
                    filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
                    lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
                    help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
                    input = { view = "cmdline_input", icon = "󰥻 " }, -- Used by input()
                    -- lua = false, -- to disable a format, set to `false`
                },
            },
            messages = {
                -- NOTE: If you enable messages, then the cmdline is enabled automatically.
                -- This is a current Neovim limitation.
                enabled = true, -- enables the Noice messages UI
                view = "notify", -- default view for messages
                view_error = "notify", -- view for errors
                view_warn = "notify", -- view for warnings
                view_history = "messages", -- view for :messages
                view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
            },
            popupmenu = {
                enabled = true, -- enables the Noice popupmenu UI
                ---@type 'nui'|'cmp'
                backend = "nui", -- backend to use to show regular cmdline completions
                ---@type NoicePopupmenuItemKind|false
                -- Icons for completion item kinds (see defaults at noice.config.icons.kinds)
                kind_icons = {}, -- set to `false` to disable icons
            },
            -- default options for require('noice').redirect
            -- see the section on Command Redirection
            redirect = {
                view = "popup",
                filter = { event = "msg_show" },
            },
            -- You can add any custom commands below that will be available when noice is loaded
            commands = {
                history = {
                    -- options for the message history that you get with `:Noice`
                    view = "split",
                    opts = { enter = true, format = "details" },
                    filter = {
                        any = {
                            { event = "notify" },
                            { error = true },
                            { warning = true },
                            { event = "msg_show", kind = { "" } },
                            { event = "lsp", kind = "message" },
                        },
                    },
                },
                -- :Noice last
                last = {
                    view = "popup",
                    opts = { enter = true, format = "details" },
                    filter = {
                        any = {
                            { event = "notify" },
                            { error = true },
                            { warning = true },
                            { event = "msg_show", kind = { "" } },
                            { event = "lsp", kind = "message" },
                        },
                    },
                    filter_opts = { count = 1 },
                },
                -- :Noice errors
                errors = {
                    -- options for the message history that you get with `:Noice`
                    view = "popup",
                    opts = { enter = true, format = "details" },
                    filter = { error = true },
                    filter_opts = { reverse = true },
                },
            },
            notify = {
                -- Noice can be used as `vim.notify` so you can route any notification like other messages
                -- Notification messages have their level and other properties set.
                -- event is always "notify" and kind can be any log level as a string
                -- The default routes will forward notifications to nvim-notify
                -- Benefit of using Noice for this is the routing and consistent history view
                enabled = true,
                view = "notify",
            },
            lsp = {
                progress = {
                    enabled = true,
                    -- Lsp Progress is formatted using the builtins for lsp_progress. See config.format.builtin
                    -- See the section on formatting for more details on how to customize.
                    --- @type NoiceFormat|string
                    format = "lsp_progress",
                    --- @type NoiceFormat|string
                    format_done = "lsp_progress_done",
                    throttle = 1000 / 30, -- frequency to update lsp progress message
                    view = "mini",
                },
                override = {
                    -- override the default lsp markdown formatter with Noice
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
                    -- override the lsp markdown formatter with Noice
                    ["vim.lsp.util.stylize_markdown"] = false,
                    -- override cmp documentation with Noice (needs the other options to work)
                    ["cmp.entry.get_documentation"] = false,
                },
                hover = {
                    enabled = true,
                    silent = false, -- set to true to not show a message if hover is not available
                    view = nil, -- when nil, use defaults from documentation
                    ---@type NoiceViewOptions
                    opts = {}, -- merged with defaults from documentation
                },
                signature = {
                    enabled = true,
                    auto_open = {
                        enabled = true,
                        trigger = true, -- Automatically show signature help when typing a trigger character from the LSP
                        luasnip = true, -- Will open signature help when jumping to Luasnip insert nodes
                        throttle = 50, -- Debounce lsp signature help request by 50ms
                    },
                    view = nil, -- when nil, use defaults from documentation
                    ---@type NoiceViewOptions
                    opts = {}, -- merged with defaults from documentation
                },
                message = {
                    -- Messages shown by lsp servers
                    enabled = true,
                    view = "notify",
                    opts = {},
                },
                -- defaults for hover and signature help
                documentation = {
                    view = "hover",
                    ---@type NoiceViewOptions
                    opts = {
                        lang = "markdown",
                        replace = true,
                        render = "plain",
                        format = { "{message}" },
                        win_options = { concealcursor = "n", conceallevel = 3 },
                    },
                },
            },
            markdown = {
                hover = {
                    ["|(%S-)|"] = vim.cmd.help, -- vim help links
                    ["%[.-%]%((%S-)%)"] = require("noice.util").open, -- markdown links
                },
                highlights = {
                    ["|%S-|"] = "@text.reference",
                    ["@%S+"] = "@parameter",
                    ["^%s*(Parameters:)"] = "@text.title",
                    ["^%s*(Return:)"] = "@text.title",
                    ["^%s*(See also:)"] = "@text.title",
                    ["{%S-}"] = "@parameter",
                },
            },
            health = {
                checker = false, -- Disable if you don't want health checks to run
            },
            smart_move = {
                -- noice tries to move out of the way of existing floating windows.
                enabled = true, -- you can disable this behaviour here
                -- add any filetypes here, that shouldn't trigger smart move.
                excluded_filetypes = { "cmp_menu", "cmp_docs", "notify" },
            },
            ---@type table<string, NoiceFilter>
            routes = {
                {
                    filter = {
                        event = "msg_show",
                        any = {
                            { find = "%d+L, %d+B" },
                            { find = "; after #%d+" },
                            { find = "; before #%d+" },
                        },
                    },
                    view = "mini",
                },
            },
            status = {}, --- @see section on statusline components
            format = {}, --- @see section on formatting
        })

        -- Noice keymaps for message management
        vim.keymap.set("n", "<leader>sn", function() require("noice").cmd("history") end, { desc = "Noice History" })
        vim.keymap.set("n", "<leader>sl", function() require("noice").cmd("last") end, { desc = "Noice Last Message" })
        vim.keymap.set("n", "<leader>se", function() require("noice").cmd("errors") end, { desc = "Noice Errors" })
        vim.keymap.set("c", "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, { desc = "Redirect Cmdline" })
        vim.keymap.set({ "i", "n", "s" }, "<c-f>", function()
            if not require("noice.lsp").scroll(4) then
                return "<c-f>"
            end
        end, { silent = true, expr = true, desc = "Scroll forward" })
        vim.keymap.set({ "i", "n", "s" }, "<c-b>", function()
            if not require("noice.lsp").scroll(-4) then
                return "<c-b>"
            end
        end, { silent = true, expr = true, desc = "Scroll backward" })
    end

    -- Oil file manager
    require "oil".setup()

    -- Snacks.nvim - Modern UI components and comprehensive dashboard
    do -- Dashboard configuration with random selection
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
                            return Snacks.git.get_root() ~= nil
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
            -- Orginal snax header
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
                    [[   █  █   ]],
                    [[   █ ██   ]],
                    [[   ████   ]],
                    [[   ██ ███   ]],
                    [[   █  █   ]],
                    [[             ]],
                    [[ n e o v i m ]],
                    [[             ]],
                }, '\n'),
            },
            { header_spec = table.concat({
                    [[                                                                       ]],
                    [[                                                                     ]],
                    [[       ████ ██████           █████      ██                     ]],
                    [[      ███████████             █████                             ]],
                    [[      █████████ ███████████████████ ███   ███████████   ]],
                    [[     █████████  ███    █████████████ █████ ██████████████   ]],
                    [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
                    [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
                    [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
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
            -- Global configuration
            bigfile = { enabled = true },
            explorer = { enabled = true },
            indent = { enabled = true },
            input = { enabled = true },
            notifier = {
                enabled = true,
                timeout = 3000,
            },
            picker = { enabled = true },
            quickfile = { enabled = true },
            scope = { enabled = true },
            scroll = { enabled = true },
            statuscolumn = { enabled = true },
            words = { enabled = true },
            styles = {
                notification = {
                    wo = { wrap = true } -- Wrap notifications
                }
            },

            -- Dashboard configuration
            dashboard = vim.tbl_deep_extend("force", base_config, selected_spec),
        })

        -- Snacks.nvim keymaps
        local function map(mode, lhs, rhs, opts)
            opts = opts or {}
            opts.silent = opts.silent ~= false
            vim.keymap.set(mode, lhs, rhs, opts)
        end

        (function() -- Top Pickers & Explorer
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

            -- Neovim News
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
        end)()

        -- Setup globals and toggles
        vim.api.nvim_create_autocmd("User", {
            pattern = "VeryLazy",
            callback = function()
                -- Setup some globals for debugging (lazy-loaded)
                _G.dd = function(...)
                    require("snacks").debug.inspect(...)
                end
                _G.bt = function()
                    require("snacks").debug.backtrace()
                end
                vim.print = _G.dd -- Override print to use snacks for `:=` command

                -- Create some toggle mappings
                require("snacks").toggle.option("spell", { name = "Spelling" }):map("<leader>us")
                require("snacks").toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
                require("snacks").toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
                require("snacks").toggle.diagnostics():map("<leader>ud")
                require("snacks").toggle.line_number():map("<leader>ul")
                require("snacks").toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
                require("snacks").toggle.treesitter():map("<leader>uT")
                require("snacks").toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
                require("snacks").toggle.inlay_hints():map("<leader>uh")
                require("snacks").toggle.indent():map("<leader>ug")
                require("snacks").toggle.dim():map("<leader>uD")
            end,
        })
    end

    -- Quick File Navigation - Alternative to Harpoon using Telescope and Snacks
    do
        -- Enhanced file navigation using existing tools

        -- -- Telescope configuration
        -- local builtin = require('telescope.builtin')
        -- vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
        -- vim.keymap.set('n', '<C-p>', builtin.git_files, {})
        -- vim.keymap.set('n', '<leader>ps', function()
        --     builtin.grep_string({ search = vim.fn.input("Grep > ") })
        -- end)
        -- vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})

        -- Quick access to recent files (replaces Harpoon's main functionality)
        vim.keymap.set("n", "<C-e>", function()
            require('telescope.builtin').oldfiles({
                prompt_title = "Recent Files",
                cwd_only = true,
                previewer = false,
            })
        end, { desc = "Recent files (project)" })

        -- Global recent files
        vim.keymap.set("n", "<leader>fr", function()
            require('telescope.builtin').oldfiles({
                prompt_title = "All Recent Files",
                previewer = false,
            })
        end, { desc = "Recent files (global)" })

        -- Quick buffer navigation (similar to Harpoon's numbered access)
        vim.keymap.set("n", "<C-h>", function() vim.cmd("bprevious") end, { desc = "Previous buffer" })
        vim.keymap.set("n", "<C-l>", function() vim.cmd("bnext") end, { desc = "Next buffer" })

        -- Buffer picker with enhanced features
        vim.keymap.set("n", "<leader>bb", function()
            require('telescope.builtin').buffers({
                sort_mru = true,
                ignore_current_buffer = true,
                previewer = false,
            })
        end, { desc = "Buffer picker" })

        -- Project-specific file finder
        vim.keymap.set("n", "<leader>pf", function()
            require('telescope.builtin').find_files({
                prompt_title = "Project Files",
                hidden = true,
                previewer = false,
            })
        end, { desc = "Find project files" })

        -- Quick access to frequently used directories
        vim.keymap.set("n", "<leader>fc", function()
            require('telescope.builtin').find_files({
                prompt_title = "Config Files",
                cwd = vim.fn.stdpath('config'),
                previewer = false,
            })
        end, { desc = "Find config files" })

        -- Alternative keymaps that match Harpoon's style
        vim.keymap.set("n", "<leader>ha", function()
            -- Add current file to vim's jumplist and mark it
            vim.cmd("normal! m'")
            vim.notify("File marked in jumplist", vim.log.levels.INFO)
        end, { desc = "Mark file (jumplist)" })

        vim.keymap.set("n", "<leader>he", function()
            require('telescope.builtin').oldfiles({
                prompt_title = "Quick Menu - Recent Files",
                cwd_only = true,
                previewer = false,
            })
        end, { desc = "Quick file menu" })

        -- Jump to specific marks (similar to Harpoon's numbered navigation)
        vim.keymap.set("n", "<leader>h1", function() vim.cmd("normal! '1") end, { desc = "Jump to mark 1" })
        vim.keymap.set("n", "<leader>h2", function() vim.cmd("normal! '2") end, { desc = "Jump to mark 2" })
        vim.keymap.set("n", "<leader>h3", function() vim.cmd("normal! '3") end, { desc = "Jump to mark 3" })
        vim.keymap.set("n", "<leader>h4", function() vim.cmd("normal! '4") end, { desc = "Jump to mark 4" })

        -- Set numbered marks
        vim.keymap.set("n", "<leader>m1", function() vim.cmd("normal! m1") end, { desc = "Set mark 1" })
        vim.keymap.set("n", "<leader>m2", function() vim.cmd("normal! m2") end, { desc = "Set mark 2" })
        vim.keymap.set("n", "<leader>m3", function() vim.cmd("normal! m3") end, { desc = "Set mark 3" })
        vim.keymap.set("n", "<leader>m4", function() vim.cmd("normal! m4") end, { desc = "Set mark 4" })

        -- Show all marks
        vim.keymap.set("n", "<leader>hm", function()
            require('telescope.builtin').marks({
                prompt_title = "All Marks",
                previewer = false,
            })
        end, { desc = "Show marks" })
    end

    -- Treesitter (keeping your existing configuration)
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

    -- UFO Configuration - Advanced folding
    do
        -- UFO folding settings
        vim.o.foldcolumn = '1' -- '0' is not bad
        vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
        vim.o.foldlevelstart = 99
        vim.o.foldenable = true

        -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
        vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = "Open all folds" })
        vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = "Close all folds" })
        vim.keymap.set('n', 'zr', require('ufo').openFoldsExceptKinds, { desc = "Open folds except kinds" })
        vim.keymap.set('n', 'zm', require('ufo').closeFoldsWith, { desc = "Close folds with" })
        vim.keymap.set('n', 'zp', require('ufo').peekFoldedLinesUnderCursor, { desc = "Peek folded lines" })

        -- Additional UFO keymaps
        vim.keymap.set('n', '<leader>zR', require('ufo').openAllFolds, { desc = "UFO: Open all folds" })
        vim.keymap.set('n', '<leader>zM', require('ufo').closeAllFolds, { desc = "UFO: Close all folds" })
        vim.keymap.set('n', '<leader>zp', require('ufo').peekFoldedLinesUnderCursor, { desc = "UFO: Peek folded lines" })
        vim.keymap.set('n', '<leader>zP', function()
            local winid = require('ufo').peekFoldedLinesUnderCursor()
            if not winid then
                vim.lsp.buf.hover()
            end
        end, { desc = "UFO: Peek or hover" })

        -- UFO setup with multiple providers
        require('ufo').setup({
            provider_selector = function(bufnr, filetype, buftype)
                -- Handle different file types appropriately
                if filetype == '' or buftype == 'nofile' then
                    return ''
                end

                -- For most files, use LSP as main, indent as fallback
                -- Treesitter can be unreliable for some file types
                return {'lsp', 'indent'}
            end,
            open_fold_hl_timeout = 150,
            close_fold_kinds_for_ft = {
                default = {'imports', 'comment'},
                json = {'array'},
                c = {'comment', 'region'}
            },
            preview = {
                win_config = {
                    border = {'', '─', '', '', '', '─', '', ''},
                    winhighlight = 'Normal:Folded',
                    winblend = 0
                },
                mappings = {
                    scrollU = '<C-u>',
                    scrollD = '<C-d>',
                    jumpTop = '[',
                    jumpBot = ']'
                }
            },
            fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
                local newVirtText = {}
                local suffix = (' 󰁂 %d '):format(endLnum - lnum)
                local sufWidth = vim.fn.strdisplaywidth(suffix)
                local targetWidth = width - sufWidth
                local curWidth = 0
                for _, chunk in ipairs(virtText) do
                    local chunkText = chunk[1]
                    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    if targetWidth > curWidth + chunkWidth then
                        table.insert(newVirtText, chunk)
                    else
                        chunkText = truncate(chunkText, targetWidth - curWidth)
                        local hlGroup = chunk[2]
                        table.insert(newVirtText, {chunkText, hlGroup})
                        chunkWidth = vim.fn.strdisplaywidth(chunkText)
                        -- str width returned from truncate() may less than 2nd argument, need padding
                        if curWidth + chunkWidth < targetWidth then
                            suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
                        end
                        break
                    end
                    curWidth = curWidth + chunkWidth
                end
                table.insert(newVirtText, {suffix, 'MoreMsg'})
                return newVirtText
            end
        })
    end

    -- Undotree Configuration - Visual undo tree
    do
        -- Undotree settings
        vim.g.undotree_WindowLayout = 2
        vim.g.undotree_SplitWidth = 40
        vim.g.undotree_SetFocusWhenToggle = 1
        vim.g.undotree_ShortIndicators = 1
        vim.g.undotree_DiffAutoOpen = 1
        vim.g.undotree_DiffpanelHeight = 10
        vim.g.undotree_RelativeTimestamp = 1
        vim.g.undotree_TreeNodeShape = '*'
        vim.g.undotree_TreeVertShape = '|'
        vim.g.undotree_TreeSplitShape = '/'
        vim.g.undotree_TreeReturnShape = '\\'
        vim.g.undotree_DiffCommand = "diff"

        -- Undotree keymaps
        vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Toggle undotree" })
        vim.keymap.set("n", "<leader>uf", vim.cmd.UndotreeFocus, { desc = "Focus undotree" })
        vim.keymap.set("n", "<leader>uh", vim.cmd.UndotreeHide, { desc = "Hide undotree" })
        vim.keymap.set("n", "<leader>us", vim.cmd.UndotreeShow, { desc = "Show undotree" })
    end

    -- Which-Key Configuration - Maximize key mapping organization
    do
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
                { "<leader>d", group = "󰃤 Debug", icon = "󰃤" },
                { "<leader>f", group = "󰈞 Find", icon = "󰈞" },
                { "<leader>g", group = "󰊢 Git", icon = "󰊢" },
                { "<leader>h", group = "󰛕 Harpoon", icon = "󰛕" },
                { "<leader>l", group = "󰿘 LSP", icon = "󰿘" },
                { "<leader>n", group = "󱞁 Neorg", icon = "󱞁" },
                { "<leader>r", group = "󰑕 Refactor", icon = "󰑕" },
                { "<leader>s", group = "󰆍 Search", icon = "󰆍" },
                { "<leader>t", group = "󰙨 Terminal", icon = "󰙨" },
                { "<leader>u", group = "󰕌 UI/Undo", icon = "󰕌" },
                { "<leader>w", group = "󰖲 Window", icon = "󰖲" },
                { "<leader>x", group = "󰒡 Trouble", icon = "󰒡" },
                { "<leader>z", group = "󰘖 Fold", icon = "󰘖" },

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
                spacing = 3, -- spacing between columns
            },
            keys = {
                scroll_down = "<c-d>", -- binding to scroll down inside the popup
                scroll_up = "<c-u>", -- binding to scroll up inside the popup
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
                    { "^%+", "" },
                    { "<[cC]md>", "" },
                    { "<[cC][rR]>", "" },
                    { "<[sS]ilent>", "" },
                    { "^lua%s+", "" },
                    { "^call%s+", "" },
                    { "^:%s*", "" },
                },
            },
        })

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
            { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "󰊄 Live grep", mode = "n" },
            { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "󰓩 Find buffers", mode = "n" },
            { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "󰋖 Help tags", mode = "n" },
            { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "󰋚 Recent files", mode = "n" },
            { "<leader>fc", "<cmd>Telescope colorscheme<cr>", desc = "󰏘 Colorschemes", mode = "n" },
            { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "󰌌 Keymaps", mode = "n" },
            { "<leader>fm", "<cmd>Telescope marks<cr>", desc = "󰃀 Marks", mode = "n" },
            { "<leader>fj", "<cmd>Telescope jumplist<cr>", desc = "󰕇 Jump list", mode = "n" },
            { "<leader>fq", "<cmd>Telescope quickfix<cr>", desc = "󰁨 Quickfix", mode = "n" },
            { "<leader>fl", "<cmd>Telescope loclist<cr>", desc = "󰁩 Location list", mode = "n" },
            { "<leader>fs", "<cmd>Telescope grep_string<cr>", desc = "󰱽 Grep string", mode = "n" },
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
            { "<leader>fls", "<cmd>Telescope lsp_document_symbols<cr>", desc = "󰘦 Document symbols", mode = "n" },
            { "<leader>flw", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "󰖲 Workspace symbols", mode = "n" },
            { "<leader>fle", "<cmd>Telescope diagnostics<cr>", desc = "󰒡 Diagnostics", mode = "n" },
        })

        -- Telescope Extensions
        wk.add({
            { "<leader>ftu", "<cmd>Telescope undo<cr>", desc = "󰕌 Undo tree", mode = "n" },
            { "<leader>ftz", "<cmd>Telescope zoxide list<cr>", desc = "󰉋 Zoxide directories", mode = "n" },
            { "<leader>ftm", "<cmd>Telescope media_files<cr>", desc = "󰈟 Media files", mode = "n" },
            { "<leader>fts", "<cmd>Telescope symbols<cr>", desc = "󰘦 Symbols", mode = "n" },
            { "<leader>ftc", "<cmd>Telescope conventional_commits<cr>", desc = "󰜘 Conventional commits", mode = "n" },
            { "<leader>fth", "<cmd>Telescope cheatsheet<cr>", desc = "󰋖 Cheatsheet", mode = "n" },
            { "<leader>ftd", "<cmd>Telescope dap commands<cr>", desc = "󰃤 DAP commands", mode = "n" },
            { "<leader>ftg", "<cmd>Telescope gh issues<cr>", desc = "󰊢 GitHub issues", mode = "n" },
            { "<leader>ftp", "<cmd>Telescope gh pull_request<cr>", desc = "󰊢 GitHub PRs", mode = "n" },
            { "<leader>ftn", "<cmd>Telescope neorg<cr>", desc = "󱞁 Neorg", mode = "n" },
            { "<leader>ftf", "<cmd>Telescope foldmarkers<cr>", desc = "󰘖 Fold markers", mode = "n" },
            { "<leader>ftj", "<cmd>Telescope jj<cr>", desc = "󰊢 Jujutsu", mode = "n" },
            { "<leader>ftw", "<cmd>Telescope fzf_writer<cr>", desc = "󰈭 FZF writer", mode = "n" },
            { "<leader>ftM", "<cmd>Telescope menu<cr>", desc = "󰍉 Menu", mode = "n" },
            { "<leader>ftC", "<cmd>Telescope color_names<cr>", desc = "󰏘 Color names", mode = "n" },
        })

        -- Window management
        wk.add({
            { "<leader>wh", "<C-w>h", desc = "󰁍 Move to left window", mode = "n" },
            { "<leader>wj", "<C-w>j", desc = "󰁅 Move to bottom window", mode = "n" },
            { "<leader>wk", "<C-w>k", desc = "󰁝 Move to top window", mode = "n" },
            { "<leader>wl", "<C-w>l", desc = "󰁔 Move to right window", mode = "n" },
            { "<leader>ws", "<C-w>s", desc = "󰤼 Split horizontal", mode = "n" },
            { "<leader>wv", "<C-w>v", desc = "󰤻 Split vertical", mode = "n" },
            { "<leader>wc", "<C-w>c", desc = "󰅖 Close window", mode = "n" },
            { "<leader>wo", "<C-w>o", desc = "󰝤 Close other windows", mode = "n" },
            { "<leader>w=", "<C-w>=", desc = "󰕳 Balance windows", mode = "n" },
            { "<leader>w+", "<C-w>+", desc = "󰝣 Increase height", mode = "n" },
            { "<leader>w-", "<C-w>-", desc = "󰝡 Decrease height", mode = "n" },
            { "<leader>w>", "<C-w>>", desc = "󰝢 Increase width", mode = "n" },
            { "<leader>w<", "<C-w><", desc = "󰝠 Decrease width", mode = "n" },
            { "<leader>wr", "<C-w>r", desc = "󰑕 Rotate windows", mode = "n" },
            { "<leader>wR", "<C-w>R", desc = "󰑕 Rotate windows reverse", mode = "n" },
            { "<leader>wx", "<C-w>x", desc = "󰓡 Exchange windows", mode = "n" },
        })

        -- LSP keymaps
        wk.add({
            { "<leader>la", vim.lsp.buf.code_action, desc = "󰌵 Code action", mode = { "n", "v" } },
            { "<leader>ld", vim.lsp.buf.definition, desc = "󰈮 Go to definition", mode = "n" },
            { "<leader>lD", vim.lsp.buf.declaration, desc = "󰈮 Go to declaration", mode = "n" },
            { "<leader>li", vim.lsp.buf.implementation, desc = "󰡱 Go to implementation", mode = "n" },
            { "<leader>lt", vim.lsp.buf.type_definition, desc = "󰜁 Go to type definition", mode = "n" },
            { "<leader>lr", vim.lsp.buf.references, desc = "󰈇 Show references", mode = "n" },
            { "<leader>lR", vim.lsp.buf.rename, desc = "󰑕 Rename symbol", mode = "n" },
            { "<leader>lh", vim.lsp.buf.hover, desc = "󰋖 Hover documentation", mode = "n" },
            { "<leader>ls", vim.lsp.buf.signature_help, desc = "󰘦 Signature help", mode = "n" },
            { "<leader>lf", vim.lsp.buf.format, desc = "󰉢 Format document", mode = { "n", "v" } },
            { "<leader>le", vim.diagnostic.open_float, desc = "󰒡 Show line diagnostics", mode = "n" },
            { "<leader>lq", vim.diagnostic.setloclist, desc = "󰁨 Diagnostics to loclist", mode = "n" },
            { "<leader>lQ", vim.diagnostic.setqflist, desc = "󰁨 Diagnostics to quickfix", mode = "n" },
            { "<leader>ln", vim.diagnostic.goto_next, desc = "󰒭 Next diagnostic", mode = "n" },
            { "<leader>lp", vim.diagnostic.goto_prev, desc = "󰒮 Previous diagnostic", mode = "n" },
            { "<leader>lwa", vim.lsp.buf.add_workspace_folder, desc = "󰝰 Add workspace folder", mode = "n" },
            { "<leader>lwr", vim.lsp.buf.remove_workspace_folder, desc = "󰝰 Remove workspace folder", mode = "n" },
            { "<leader>lwl", function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, desc = "󰝰 List workspace folders", mode = "n" },
        })

        -- Code/Refactoring keymaps
        wk.add({
            { "<leader>ca", vim.lsp.buf.code_action, desc = "󰌵 Code action", mode = { "n", "v" } },
            { "<leader>cf", vim.lsp.buf.format, desc = "󰉢 Format", mode = { "n", "v" } },
            { "<leader>cr", vim.lsp.buf.rename, desc = "󰑕 Rename", mode = "n" },
            { "<leader>cs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "󰘦 Document symbols", mode = "n" },
            { "<leader>cS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "󰖲 Workspace symbols", mode = "n" },
            { "<leader>cd", "<cmd>Telescope diagnostics<cr>", desc = "󰒡 Diagnostics", mode = "n" },
            { "<leader>ci", "<cmd>LspInfo<cr>", desc = "󰿘 LSP info", mode = "n" },
            { "<leader>cI", "<cmd>LspInstall<cr>", desc = "󰿘 LSP install", mode = "n" },
            { "<leader>cl", "<cmd>LspLog<cr>", desc = "󰿘 LSP log", mode = "n" },
            { "<leader>cR", "<cmd>LspRestart<cr>", desc = "󰿘 LSP restart", mode = "n" },
        })

        -- Debug keymaps
        wk.add({
            { "<leader>db", "<cmd>DapToggleBreakpoint<cr>", desc = "󰃤 Toggle breakpoint", mode = "n" },
            { "<leader>dB", function() require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "󰃤 Conditional breakpoint", mode = "n" },
            { "<leader>dc", "<cmd>DapContinue<cr>", desc = "󰐊 Continue", mode = "n" },
            { "<leader>di", "<cmd>DapStepInto<cr>", desc = "󰆹 Step into", mode = "n" },
            { "<leader>do", "<cmd>DapStepOver<cr>", desc = "󰆷 Step over", mode = "n" },
            { "<leader>dO", "<cmd>DapStepOut<cr>", desc = "󰆸 Step out", mode = "n" },
            { "<leader>dr", "<cmd>DapToggleRepl<cr>", desc = "󰞕 Toggle REPL", mode = "n" },
            { "<leader>dl", "<cmd>DapShowLog<cr>", desc = "󰦪 Show log", mode = "n" },
            { "<leader>dt", "<cmd>DapTerminate<cr>", desc = "󰝤 Terminate", mode = "n" },
            { "<leader>du", "<cmd>Telescope dap commands<cr>", desc = "󰔱 DAP commands", mode = "n" },
            { "<leader>dv", "<cmd>Telescope dap variables<cr>", desc = "󰔱 DAP variables", mode = "n" },
            { "<leader>df", "<cmd>Telescope dap frames<cr>", desc = "󰔱 DAP frames", mode = "n" },
            { "<leader>dh", "<cmd>Telescope dap list_breakpoints<cr>", desc = "󰔱 List breakpoints", mode = "n" },
        })

        -- Search keymaps
        wk.add({
            { "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "󰱼 Search in buffer", mode = "n" },
            { "<leader>sc", "<cmd>Telescope commands<cr>", desc = "󰘳 Commands", mode = "n" },
            { "<leader>sC", "<cmd>Telescope command_history<cr>", desc = "󰘳 Command history", mode = "n" },
            { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "󰊄 Live grep", mode = "n" },
            { "<leader>sG", "<cmd>Telescope grep_string<cr>", desc = "󰱽 Grep string", mode = "n" },
            { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "󰋖 Help tags", mode = "n" },
            { "<leader>sH", "<cmd>Telescope highlights<cr>", desc = "󰸱 Highlights", mode = "n" },
            { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "󰌌 Keymaps", mode = "n" },
            { "<leader>sm", "<cmd>Telescope man_pages<cr>", desc = "󰗚 Man pages", mode = "n" },
            { "<leader>sM", "<cmd>Telescope marks<cr>", desc = "󰃀 Marks", mode = "n" },
            { "<leader>so", "<cmd>Telescope vim_options<cr>", desc = "󰒓 Vim options", mode = "n" },
            { "<leader>sr", "<cmd>Telescope registers<cr>", desc = "󰅌 Registers", mode = "n" },
            { "<leader>ss", "<cmd>Telescope spell_suggest<cr>", desc = "󰓆 Spell suggest", mode = "n" },
            { "<leader>sS", "<cmd>Telescope search_history<cr>", desc = "󰋚 Search history", mode = "n" },
            { "<leader>st", "<cmd>Telescope filetypes<cr>", desc = "󰈔 File types", mode = "n" },
            { "<leader>sw", "<cmd>Telescope grep_string<cr>", desc = "󰱽 Search word under cursor", mode = "n" },
        })

        -- Terminal keymaps
        wk.add({
            { "<leader>tt", function() require("snacks").terminal() end, desc = "󰙨 Terminal", mode = "n" },
            { "<leader>tf", function() require("snacks").terminal(nil, { cwd = vim.fn.expand("%:p:h") }) end, desc = "󰙨 Terminal (file dir)", mode = "n" },
            { "<leader>tg", function() require("snacks").terminal("lazygit") end, desc = "󰊢 Lazygit", mode = "n" },
            { "<leader>th", function() require("snacks").terminal("htop") end, desc = "󰍛 Htop", mode = "n" },
            { "<leader>tp", function() require("snacks").terminal("python") end, desc = "󰌠 Python", mode = "n" },
            { "<leader>tn", function() require("snacks").terminal("node") end, desc = "󰎙 Node", mode = "n" },
            { "<leader>tr", function() require("snacks").terminal("ranger") end, desc = "󰙅 Ranger", mode = "n" },
            { "<leader>td", function() require("snacks").terminal("docker") end, desc = "󰡨 Docker", mode = "n" },
        })

        -- UI/Snacks keymaps
        wk.add({
            { "<leader>ub", function() require("snacks").bufdelete() end, desc = "󰅖 Delete buffer", mode = "n" },
            { "<leader>uc", function() require("snacks").toggle.option("conceallevel", {off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2}) end, desc = "󰈈 Toggle conceal", mode = "n" },
            { "<leader>ud", function() require("snacks").toggle.diagnostics() end, desc = "󰒡 Toggle diagnostics", mode = "n" },
            { "<leader>uf", function() require("snacks").toggle.option("formatexpr", {off = "", on = "v:lua.require'conform'.formatexpr()"}) end, desc = "󰉢 Toggle format on save", mode = "n" },
            { "<leader>ug", function() require("snacks").gitbrowse() end, desc = "󰊢 Git browse", mode = "n" },
            { "<leader>uh", function() require("snacks").toggle.inlay_hints() end, desc = "󰘦 Toggle inlay hints", mode = "n" },
            { "<leader>ui", function() require("snacks").toggle.indent() end, desc = "󰉶 Toggle indent guides", mode = "n" },
            { "<leader>ul", function() require("snacks").toggle.line_number() end, desc = "󰔡 Toggle line numbers", mode = "n" },
            { "<leader>uL", function() require("snacks").lazygit() end, desc = "󰊢 Lazygit", mode = "n" },
            { "<leader>un", function() require("snacks").notifier.show_history() end, desc = "󰍡 Notification history", mode = "n" },
            { "<leader>uN", function() require("snacks").notifier.hide() end, desc = "󰍡 Dismiss notifications", mode = "n" },
            { "<leader>ur", function() require("snacks").rename.rename_file() end, desc = "󰑕 Rename file", mode = "n" },
            { "<leader>us", function() require("snacks").toggle.option("spell") end, desc = "󰓆 Toggle spell", mode = "n" },
            { "<leader>ut", function() require("snacks").toggle.treesitter() end, desc = "󰔱 Toggle treesitter", mode = "n" },
            { "<leader>uw", function() require("snacks").toggle.option("wrap") end, desc = "󰖶 Toggle wrap", mode = "n" },
            { "<leader>uz", function() require("snacks").zen() end, desc = "󰚀 Zen mode", mode = "n" },
            { "<leader>uZ", function() require("snacks").zoom() end, desc = "󰍉 Zoom", mode = "n" },
        })

        -- Snacks specific keymaps
        wk.add({
            { "<leader>snb", function() require("snacks").scratch() end, desc = "󰃃 Scratch buffer", mode = "n" },
            { "<leader>snB", function() require("snacks").scratch.select() end, desc = "󰃃 Select scratch buffer", mode = "n" },
            { "<leader>snd", function() require("snacks").dashboard() end, desc = "🍿 Dashboard", mode = "n" },
            { "<leader>sng", function() require("snacks").gitbrowse() end, desc = "󰊢 Git browse", mode = "n" },
            { "<leader>snl", function() require("snacks").lazygit() end, desc = "󰊢 Lazygit", mode = "n" },
            { "<leader>snn", function() require("snacks").notifier.show_history() end, desc = "󰍡 Notification history", mode = "n" },
            { "<leader>snN", function() require("snacks").notifier.hide() end, desc = "󰍡 Dismiss notifications", mode = "n" },
            { "<leader>snp", function() require("snacks").profiler.toggle() end, desc = "󰔟 Toggle profiler", mode = "n" },
            { "<leader>snP", function() require("snacks").profiler.scratch() end, desc = "󰔟 Profiler scratch", mode = "n" },
            { "<leader>snr", function() require("snacks").rename.rename_file() end, desc = "󰑕 Rename file", mode = "n" },
            { "<leader>sns", function() require("snacks").statuscolumn.toggle() end, desc = "󰕱 Toggle statuscolumn", mode = "n" },
            { "<leader>snt", function() require("snacks").terminal() end, desc = "󰙨 Terminal", mode = "n" },
            { "<leader>snw", function() require("snacks").words.jump(vim.v.count1) end, desc = "󰬴 Next reference", mode = "n" },
            { "<leader>snW", function() require("snacks").words.jump(-vim.v.count1) end, desc = "󰬱 Prev reference", mode = "n" },
            { "<leader>snz", function() require("snacks").zen() end, desc = "󰚀 Zen mode", mode = "n" },
            { "<leader>snZ", function() require("snacks").zoom() end, desc = "󰍉 Zoom", mode = "n" },
        })

        -- Trouble/Diagnostics keymaps (if you have trouble.nvim)
        wk.add({
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "󰒡 Diagnostics (Trouble)", mode = "n" },
            { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "󰒡 Buffer diagnostics (Trouble)", mode = "n" },
            { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "󰘦 Symbols (Trouble)", mode = "n" },
            { "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "󰿘 LSP definitions/references/... (Trouble)", mode = "n" },
            { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "󰁩 Location list (Trouble)", mode = "n" },
            { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "󰁨 Quickfix list (Trouble)", mode = "n" },
        })

        -- Neorg keymaps (if you use neorg)
        wk.add({
            { "<leader>ni", "<cmd>Neorg index<cr>", desc = "󱞁 Neorg index", mode = "n" },
            { "<leader>nr", "<cmd>Neorg return<cr>", desc = "󱞁 Neorg return", mode = "n" },
            { "<leader>nj", "<cmd>Neorg journal<cr>", desc = "󱞁 Neorg journal", mode = "n" },
            { "<leader>nt", "<cmd>Neorg journal today<cr>", desc = "󱞁 Neorg today", mode = "n" },
            { "<leader>ny", "<cmd>Neorg journal yesterday<cr>", desc = "󱞁 Neorg yesterday", mode = "n" },
            { "<leader>nm", "<cmd>Neorg journal tomorrow<cr>", desc = "󱞁 Neorg tomorrow", mode = "n" },
            { "<leader>nc", "<cmd>Neorg journal custom<cr>", desc = "󱞁 Neorg custom date", mode = "n" },
            { "<leader>nw", "<cmd>Neorg workspace<cr>", desc = "󱞁 Neorg workspace", mode = "n" },
        })

        -- Quick actions (commonly used)
        wk.add({
            { "<leader><space>", "<cmd>Telescope find_files<cr>", desc = "󰈞 Find files", mode = "n" },
            { "<leader>,", "<cmd>Telescope buffers<cr>", desc = "󰓩 Switch buffer", mode = "n" },
            { "<leader>.", "<cmd>Telescope file_browser<cr>", desc = "󰉋 File browser", mode = "n" },
            { "<leader>/", "<cmd>Telescope live_grep<cr>", desc = "󰊄 Search", mode = "n" },
            { "<leader>:", "<cmd>Telescope command_history<cr>", desc = "󰘳 Command history", mode = "n" },
            { "<leader>;", "<cmd>Telescope commands<cr>", desc = "󰘳 Commands", mode = "n" },
        })

        -- Additional utility keymaps
        wk.add({
            { "<leader>q", "<cmd>q<cr>", desc = "󰗼 Quit", mode = "n" },
            { "<leader>Q", "<cmd>qa<cr>", desc = "󰗼 Quit all", mode = "n" },
            { "<leader>w", "<cmd>w<cr>", desc = "󰆓 Save", mode = "n" },
            { "<leader>W", "<cmd>wa<cr>", desc = "󰆔 Save all", mode = "n" },
            { "<leader>e", "<cmd>e!<cr>", desc = "󰑐 Reload file", mode = "n" },
            { "<leader>E", "<cmd>Explore<cr>", desc = "󰉋 File explorer", mode = "n" },
            { "<leader>o", "<cmd>only<cr>", desc = "󰝤 Close other windows", mode = "n" },
            { "<leader>O", "<cmd>tabonly<cr>", desc = "󰝤 Close other tabs", mode = "n" },
            { "<leader>|", "<cmd>vsplit<cr>", desc = "󰤻 Vertical split", mode = "n" },
            { "<leader>-", "<cmd>split<cr>", desc = "󰤼 Horizontal split", mode = "n" },
            { "<leader>=", "<C-w>=", desc = "󰕳 Balance windows", mode = "n" },
            { "<leader>+", "<C-w>+", desc = "󰝣 Increase height", mode = "n" },
            { "<leader>_", "<C-w>-", desc = "󰝡 Decrease height", mode = "n" },
            { "<leader>>", "<C-w>>", desc = "󰝢 Increase width", mode = "n" },
            { "<leader><", "<C-w><", desc = "󰝠 Decrease width", mode = "n" },
        })
    end

    -- -- Additional configurations
    -- vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

    -- vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
    -- vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

    -- vim.keymap.set("n", "J", "mzJ`z")
    -- vim.keymap.set("n", "<C-d>", "<C-d>zz")
    -- vim.keymap.set("n", "<C-u>", "<C-u>zz")
    -- vim.keymap.set("n", "n", "nzzzv")
    -- vim.keymap.set("n", "N", "Nzzzv")

    -- vim.keymap.set("x", "<leader>p", [["_dP]])

    -- vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
    -- vim.keymap.set("n", "<leader>Y", [["+Y]])

    -- vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

    -- vim.keymap.set("i", "<C-c>", "<Esc>")

    -- vim.keymap.set("n", "Q", "<nop>")
    -- vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

    -- vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
    -- vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
    -- vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
    -- vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

    -- vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
    -- vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

    -- vim.keymap.set("n", "<leader><leader>", function()
    --     vim.cmd("so")
    -- end)
end
