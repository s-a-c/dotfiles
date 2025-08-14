-- ============================================================================
-- COLORSCHEME CONFIGURATION
-- ============================================================================
-- Colorscheme loading with fallback options

local function set_colorscheme()
    -- List of preferred colorschemes in order of preference
    local colorschemes = {
        "modus_vivendi",  -- Correct name for modus-themes.nvim
        "tokyonight-night",
        "gruvbox",
        "kanagawa",
        "catppuccin",
        "default"  -- Built-in fallback
    }
    
    for _, colorscheme in ipairs(colorschemes) do
        local ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
        if ok then
            vim.notify("Loaded colorscheme: " .. colorscheme, vim.log.levels.INFO)
            return
        end
    end
    
    -- If all else fails, use the default colorscheme
    vim.cmd("colorscheme default")
    vim.notify("Using default colorscheme", vim.log.levels.WARN)
end

-- Set the colorscheme
set_colorscheme()