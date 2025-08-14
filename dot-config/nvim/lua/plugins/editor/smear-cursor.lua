-- ============================================================================
-- SMEAR CURSOR CONFIGURATION
-- ============================================================================
-- Smooth cursor animation configuration

require("smear_cursor").setup({
    -- Cursor color. Defaults to Cursor gui color if not set.
    -- Set to "none" to match the character color at the cursor position.
    cursor_color = "#d3cdc3",
    
    -- Background color. Defaults to Normal gui background color if not set.
    normal_bg = "#282828",
    
    -- Smear cursor when switching buffers or windows.
    smear_between_buffers = true,
    
    -- Smear cursor when moving in insert mode.
    smear_between_neighbor_lines = true,
    
    -- Use floating windows to display smears outside of buffer.
    -- May have performance issues with other plugins.
    use_floating_windows = true,
    
    -- Set to `true` if your font supports legacy computing symbols (block unicode symbols).
    -- Smears will blend better on all backgrounds.
    legacy_computing_symbols_support = false,
})