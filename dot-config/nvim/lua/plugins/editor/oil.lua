-- ============================================================================
-- OIL.NVIM CONFIGURATION
-- ============================================================================
-- File explorer that lets you edit your filesystem like a buffer

-- Ensure oil.nvim is available
local ok, oil = pcall(require, "oil")
if not ok then
    vim.notify("oil.nvim not found", vim.log.levels.WARN)
    return
end

-- ============================================================================
-- OIL SETUP
-- ============================================================================

oil.setup({
    -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
    default_file_explorer = true,
    
    -- Id is automatically added at the beginning, and name at the end
    columns = {
        "icon",
        -- "permissions",
        -- "size",
        -- "mtime",
    },
    
    -- Buffer-local options to use for oil buffers
    buf_options = {
        buflisted = false,
        bufhidden = "hide",
    },
    
    -- Window-local options to use for oil buffers
    win_options = {
        wrap = false,
        signcolumn = "no",
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
    },
    
    -- Send deleted files to the trash instead of permanently deleting them (:help oil-trash)
    delete_to_trash = true,
    
    -- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
    skip_confirm_for_simple_edits = false,
    
    -- Selecting a new/moved/renamed file or directory will prompt you to save changes first
    prompt_save_on_select_new_entry = true,
    
    -- Oil will automatically delete hidden buffers after this delay
    cleanup_delay_ms = 2000,
    
    lsp_file_methods = {
        -- Time to wait for LSP file operations to complete before skipping
        timeout_ms = 1000,
        -- Set to true to autosave buffers that are updated with LSP willRenameFiles
        autosave_changes = false,
    },
    
    -- Constrain the cursor to the editable parts of the oil buffer
    constrain_cursor = "editable",
    
    -- Set to true to watch the filesystem for changes and reload oil
    experimental_watch_for_changes = false,
    
    -- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
    -- options with a `callback` (e.g. { callback = function() ... end, desc = "..." })
    keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-s>"] = "actions.select_vsplit",
        ["<C-h>"] = "actions.select_split",
        ["<C-t>"] = "actions.select_tab",
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["<C-l>"] = "actions.refresh",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = "actions.tcd",
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["g."] = "actions.toggle_hidden",
        ["g\\"] = "actions.toggle_trash",
    },
    
    -- Set to false to disable all of the above keymaps
    use_default_keymaps = true,
    
    view_options = {
        -- Show files and directories that start with "."
        show_hidden = false,
        -- This function defines what is considered a "hidden" file
        is_hidden_file = function(name, bufnr)
            return vim.startswith(name, ".")
        end,
        -- This function defines what will never be shown, even when `show_hidden` is set
        is_always_hidden = function(name, bufnr)
            return false
        end,
        sort = {
            -- sort order can be "asc" or "desc"
            -- see :help oil-columns to see which columns are sortable
            { "type", "asc" },
            { "name", "asc" },
        },
    },
    
    -- Configuration for the floating window in oil.open_float
    float = {
        -- Padding around the floating window
        padding = 2,
        max_width = 0,
        max_height = 0,
        border = "rounded",
        win_options = {
            winblend = 0,
        },
        -- This is the config that will be passed to nvim_open_win.
        -- Change values here to customize the layout
        override = function(conf)
            return conf
        end,
    },
    
    -- Configuration for the actions floating preview window
    preview = {
        -- Width dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        max_width = 0.9,
        -- Height dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        min_height = { 5, 0.1 },
        max_height = 0.9,
        border = "rounded",
        win_options = {
            winblend = 0,
        },
        -- Whether the preview window is automatically updated when the cursor is moved
        update_on_cursor_moved = true,
    },
    
    -- Configuration for the floating progress window
    progress = {
        max_width = 0.9,
        min_height = { 5, 0.1 },
        max_height = 0.9,
        border = "rounded",
        minimized_border = "none",
        win_options = {
            winblend = 0,
        },
    },
    
    -- Configuration for the floating SSH window
    ssh = {
        border = "rounded",
    },
})

-- ============================================================================
-- OIL KEYMAPS
-- ============================================================================

local keymap = vim.keymap.set

-- Main oil operations
keymap("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
keymap("n", "<leader>-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- Open oil in floating window
keymap("n", "<leader>e", function()
    require("oil").open_float()
end, { desc = "Open oil in floating window" })

-- Open oil in current directory
keymap("n", "<leader>E", function()
    require("oil").open()
end, { desc = "Open oil in current directory" })

-- ============================================================================
-- WHICH-KEY INTEGRATION
-- ============================================================================

local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
    wk.add({
        { "-", desc = "📁 Open Parent Directory" },
        { "<leader>-", desc = "📁 Open Parent Directory" },
        { "<leader>e", desc = "📁 Oil Float" },
        { "<leader>E", desc = "📁 Oil Current Dir" },
    })
end

vim.notify("oil.nvim configured successfully", vim.log.levels.INFO)