-- ============================================================================
-- TELESCOPE CONFIGURATION
-- ============================================================================
-- Fuzzy finder and picker configuration

local telescope = require('telescope')
local actions = require('telescope.actions')

-- ============================================================================
-- TELESCOPE SETUP
-- ============================================================================

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
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
        },
    }
})

-- ============================================================================
-- LOAD EXTENSIONS
-- ============================================================================

local extensions = {
    'fzf',
    'zoxide',
    'neorg',
    'foldmarkers',
    'jj',
    'gh',
    'media_files',
    'fzf_writer',
    'symbols',
    'conventional_commits',
    'cheatsheet',
    'color_names',
    'menu',
    'undo',
    'dap',
}

for _, ext in ipairs(extensions) do
    pcall(require('telescope').load_extension, ext)
end

-- ============================================================================
-- TELESCOPE KEYMAPS
-- ============================================================================

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
