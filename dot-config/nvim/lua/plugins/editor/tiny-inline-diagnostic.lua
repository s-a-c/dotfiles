-- ============================================================================
-- TINY INLINE DIAGNOSTIC CONFIGURATION
-- ============================================================================
-- Minimalist inline diagnostic display for LSP diagnostics

require('tiny-inline-diagnostic').setup({
    blend = {
        factor = 0.22,
    },
    disabled_ft = {}, -- List of filetypes to disable the plugin
    hi = {
        arrow = "NonText",
        background = "CursorLine", -- Can be a highlight or a hexadecimal color (#RRGGBB)
        error = "DiagnosticError",
        hint = "DiagnosticHint",
        info = "DiagnosticInfo",
        mixing_color = "None", -- Can be None or a hexadecimal color (#RRGGBB). Used to blend the background color with the diagnostic background color with another color.
        warn = "DiagnosticWarn",
    },
    options = {
        -- Add messages to diagnostics when multiline diagnostics are enabled
        -- If set to false, only signs will be displayed
        add_messages = true,
        -- Configuration for breaking long messages into separate lines
        break_line = {
            -- Enable the feature to break messages after a specific length
            enabled = false,
            -- Number of characters after which to break the line
            after = 30,
        },
        -- Enable diagnostics in Insert mode
        -- If enabled, it is better to set the `throttle` option to 0 to avoid visual artifacts
        enable_on_insert = false,
		-- Enable diagnostics in Select mode (e.g when auto inserting with Blink)
        enable_on_select = false,
        -- Custom format function for diagnostic messages
        -- Example:
        -- format = function(diagnostic)
        --     return diagnostic.message .. " [" .. diagnostic.source .. "]"
        -- end
        format = nil,
        -- Configuration for multiline diagnostics
        -- Can either be a boolean or a table with the following options:
        --  multilines = {
        --      enabled = false,
        --      always_show = false,
        -- }
        -- If it set as true, it will enable the feature with this options:
        --  multilines = {
        --      enabled = true,
        --      always_show = false,
        -- }
        multilines = {
            -- Enable multiline diagnostic messages
            enabled = false,
            -- Always show messages on all lines for multiline diagnostics
            always_show = false,
            -- Trim whitespaces from the start/end of each line
            trim_whitespaces = true,
            -- Replace tabs with spaces in multiline diagnostics
            tabstop = 4,
        },
        multiple_diag_under_cursor = false,
        overflow = {
            -- Manage how diagnostic messages handle overflow
            -- Options:
            -- "wrap" - Split long messages into multiple lines
            -- "none" - Do not truncate messages
            -- "oneline" - Keep the message on a single line, even if it's long
            mode = "wrap",

            -- Trigger wrapping to occur this many characters earlier when mode == "wrap".
            -- Increase this value appropriately if you notice that the last few characters
            -- of wrapped diagnostics are sometimes obscured.
            padding = 0,
        },
        -- Events to attach diagnostics to buffers
        -- You should not change this unless the plugin does not work with your configuration
        overwrite_events = nil,
        -- Set the arrow icon to the same color as the first diagnostic severity
        set_arrow_to_diag_color = false,
        -- Filter diagnostics by severity
        -- Available severities:
        -- vim.diagnostic.severity.ERROR
        -- vim.diagnostic.severity.WARN
        -- vim.diagnostic.severity.INFO
        -- vim.diagnostic.severity.HINT
        severity = {
            vim.diagnostic.severity.ERROR,
            vim.diagnostic.severity.WARN,
            vim.diagnostic.severity.INFO,
            vim.diagnostic.severity.HINT,
        },
        -- Display the source of the diagnostic (e.g., basedpyright, vsserver, lua_ls etc.)
        show_source = {
            enabled = false,
            if_many = false,
        },
        softwrap = 30,
        -- Time (in milliseconds) to throttle updates while moving the cursor
        -- Increase this value for better performance if your computer is slow
        -- or set to 0 for immediate updates and better visual
        throttle = 20,
        -- Use icons defined in the diagnostic configuration
        use_icons_from_diagnostic = false,
        virt_texts = {
            -- Priority for virtual text display
            priority = 2048,
        },
    },
    -- Style preset for diagnostic messages
    -- Available options:
    -- "modern", "classic", "minimal", "powerline",
    -- "ghost", "simple", "nonerdfont", "amongus"
    preset = "modern",
    signs = {
        left = "",
        right = "",
        diag = "●",
        arrow = "    ",
        up_arrow = "    ",
        vertical = " │",
        vertical_end = " └",
    },
    transparent_bg = false, -- Set the background of the diagnostic to transparent
    transparent_cursorline = false, -- Set the background of the cursorline to transparent (only one the first diagnostic)
})

-- ============================================================================
-- KEYMAPS
-- ============================================================================

-- Toggle inline diagnostics
vim.keymap.set("n", "<leader>dt", function()
    require("tiny-inline-diagnostic").toggle()
end, { desc = "Toggle Inline Diagnostics" })

-- Enable inline diagnostics
vim.keymap.set("n", "<leader>de", function()
    require("tiny-inline-diagnostic").enable()
end, { desc = "Enable Inline Diagnostics" })

-- Disable inline diagnostics
vim.keymap.set("n", "<leader>dd", function()
    require("tiny-inline-diagnostic").disable()
end, { desc = "Disable Inline Diagnostics" })
