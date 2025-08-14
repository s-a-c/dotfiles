-- ============================================================================
-- NVIM-SPECTRE CONFIGURATION
-- ============================================================================
-- Advanced search and replace functionality across the entire project

-- Ensure nvim-spectre is available
local ok, spectre = pcall(require, "spectre")
if not ok then
    vim.notify("nvim-spectre not found", vim.log.levels.WARN)
    return
end

-- ============================================================================
-- SPECTRE SETUP
-- ============================================================================

spectre.setup({
    -- Color configuration
    color_devicons = true,
    
    -- Highlight configuration
    highlight = {
        ui = "String",
        search = "DiffChange",
        replace = "DiffDelete"
    },
    
    -- Mapping configuration
    mapping = {
        ['toggle_line'] = {
            map = "dd",
            cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
            desc = "toggle current item"
        },
        ['enter_file'] = {
            map = "<cr>",
            cmd = "<cmd>lua require('spectre').enter_file()<CR>",
            desc = "goto current file"
        },
        ['send_to_qf'] = {
            map = "<leader>q",
            cmd = "<cmd>lua require('spectre').send_to_qf()<CR>",
            desc = "send all items to quickfix"
        },
        ['replace_cmd'] = {
            map = "<leader>c",
            cmd = "<cmd>lua require('spectre').replace_cmd()<CR>",
            desc = "input replace command"
        },
        ['show_option_menu'] = {
            map = "<leader>o",
            cmd = "<cmd>lua require('spectre').show_options()<CR>",
            desc = "show options"
        },
        ['run_current_replace'] = {
            map = "<leader>rc",
            cmd = "<cmd>lua require('spectre').run_current_replace()<CR>",
            desc = "replace current line"
        },
        ['run_replace'] = {
            map = "<leader>R",
            cmd = "<cmd>lua require('spectre').run_replace()<CR>",
            desc = "replace all"
        },
        ['change_view_mode'] = {
            map = "<leader>v",
            cmd = "<cmd>lua require('spectre').change_view()<CR>",
            desc = "change result view mode"
        },
        ['change_replace_sed'] = {
            map = "trs",
            cmd = "<cmd>lua require('spectre').change_engine_replace('sed')<CR>",
            desc = "use sed to replace"
        },
        ['change_replace_oxi'] = {
            map = "tro",
            cmd = "<cmd>lua require('spectre').change_engine_replace('oxi')<CR>",
            desc = "use oxi to replace"
        },
        ['toggle_live_update'] = {
            map = "tu",
            cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>",
            desc = "update when vim writes to file"
        },
        ['toggle_ignore_case'] = {
            map = "ti",
            cmd = "<cmd>lua require('spectre').toggle_ignore_case()<CR>",
            desc = "toggle ignore case"
        },
        ['toggle_ignore_hidden'] = {
            map = "th",
            cmd = "<cmd>lua require('spectre').toggle_ignore_hidden()<CR>",
            desc = "toggle search hidden"
        },
        ['resume_last_search'] = {
            map = "<leader>l",
            cmd = "<cmd>lua require('spectre').resume_last_search()<CR>",
            desc = "repeat last search"
        },
    },
    
    -- Find engine configuration
    find_engine = {
        -- rg is better than grep
        ['rg'] = {
            cmd = "rg",
            args = {
                '--color=never',
                '--no-heading',
                '--with-filename',
                '--line-number',
                '--column',
            },
            options = {
                ['ignore-case'] = {
                    value = "--ignore-case",
                    icon = "[I]",
                    desc = "ignore case"
                },
                ['hidden'] = {
                    value = "--hidden",
                    desc = "hidden file",
                    icon = "[H]"
                },
                -- you can put any rg search option you want here it can toggle with
                -- show_option function
            }
        },
        ['ag'] = {
            cmd = "ag",
            args = {
                '--vimgrep',
                '-s'
            },
            options = {
                ['ignore-case'] = {
                    value = "-i",
                    icon = "[I]",
                    desc = "ignore case"
                },
                ['hidden'] = {
                    value = "--hidden",
                    desc = "hidden file",
                    icon = "[H]"
                },
            }
        },
    },
    
    -- Replace engine configuration
    replace_engine = {
        ['sed'] = {
            cmd = "sed",
            args = nil,
            options = {
                ['ignore-case'] = {
                    value = "--ignore-case",
                    icon = "[I]",
                    desc = "ignore case"
                },
            }
        },
        -- call rust code by nvim-oxi to replace
        ['oxi'] = {
            cmd = 'oxi',
            args = {},
            options = {
                ['ignore-case'] = {
                    value = "i",
                    icon = "[I]",
                    desc = "ignore case"
                },
            }
        }
    },
    
    -- Default search engine
    default = {
        find = {
            cmd = "rg",
            options = {"ignore-case"}
        },
        replace = {
            cmd = "sed"
        }
    },
    
    -- Replace vim commands
    replace_vim_cmd = "cdo",
    
    -- Live update configuration
    is_open_target_win = true, -- auto open file on cursor
    is_insert_mode = false,    -- start in normal mode
    
    -- Block on large files
    is_block_on_large_file = false, -- block on file larger than 10MB
})

-- ============================================================================
-- SPECTRE KEYMAPS
-- ============================================================================

local keymap = vim.keymap.set

-- Main spectre operations
keymap('n', '<leader>S', '<cmd>lua require("spectre").toggle()<CR>', { desc = 'Toggle Spectre' })
keymap('n', '<leader>sw', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', { desc = 'Search current word' })
keymap('v', '<leader>sw', '<esc><cmd>lua require("spectre").open_visual()<CR>', { desc = 'Search current word' })
keymap('n', '<leader>sp', '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', { desc = 'Search on current file' })

-- ============================================================================
-- WHICH-KEY INTEGRATION
-- ============================================================================

local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
    wk.add({
        { "<leader>S", desc = "🔍 Toggle Spectre" },
        { "<leader>s", group = "🔍 Search" },
        { "<leader>sw", desc = "Search Word", mode = { "n", "v" } },
        { "<leader>sp", desc = "Search in File" },
    })
end

vim.notify("nvim-spectre configured successfully", vim.log.levels.INFO)