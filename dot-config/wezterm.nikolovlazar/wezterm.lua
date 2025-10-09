local wezterm = require 'wezterm'
local commands = require 'commands'

local config = wezterm.config_builder()
-- Set the color scheme depending on the system setting
function get_appearance()
    if wezterm.gui then
        return wezterm.gui.get_appearance()
    end
    return 'Dark'
end

function scheme_for_appearance(appearance)
    if appearance:find 'Dark' then
        return 'Modus-Vivendi'
    else
        return 'Modus-Operandi'
    end
end

config.automatically_reload_config = true

config.check_for_updates = true

-- Font settings
config.font_size = 16
config.line_height = 1.2
config.font = wezterm.font_with_fallback {
    {
        family = 'Monaspace Neon NF',
        harfbuzz_features = {
            'calt',
            'ss01',
            'ss02',
            'ss03',
            'ss04',
            'ss05',
            'ss06',
            'ss07',
            'ss08',
            'ss09',
            'liga',
        },
    },
    { family = 'Symbols Nerd Font Mono' },
}
config.font_rules = {
    {
        font = wezterm.font('Dank Mono', {
            bold = true,
        }),
    },
    {
        italic = true,
        font = wezterm.font('Dank Mono', {
            italic = true,
        }),
    },
}

-- Colors
config.color_scheme = 'Catppuccin Mocha'

-- Appearance
config.cursor_blink_rate = 300
-- config.window_decorations = 'RESIZE'
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
}
config.macos_window_background_blur = 40

-- I got the GPU settings below from a comment by user @anthonyknowles
-- In my wezterm video and will test them out
-- https://youtu.be/ibCPb4tSRXM
-- https://wezfurlong.org/wezterm/config/lua/config/animation_fps.html?h=animation
config.animation_fps = 120

-- Miscellaneous settings
config.max_fps = 240
config.prefer_egl = true

-- color_scheme = 'Modus-Vivendi',
-- config.color_scheme = scheme_for_appearance(get_appearance())

config.cursor_blink_ease_in = 'Linear'
config.cursor_blink_ease_out = 'Linear'
config.default_cursor_style = "BlinkingBar"

config.debug_key_events = true

-- To enable kitty graphics
-- https://github.com/wez/wezterm/issues/986
-- It seems that kitty graphics is not enabled by default according to this
-- Not sure, so I'm enabling it just in case
-- https://github.com/wez/wezterm/issues/1406#issuecomment-996253377
config.enable_kitty_graphics = true
config.enable_kitty_keyboard = true

config.enable_tab_bar = true

config.native_macos_fullscreen_mode = false

-- Custom commands
wezterm.on('augment-command-palette', function()
    return commands
end)

return config
