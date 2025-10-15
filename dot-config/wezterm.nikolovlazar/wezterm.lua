local wezterm = require 'wezterm'
local commands = require 'commands'
local mux = wezterm.mux

local config = wezterm.config_builder()

-- -- Set the color scheme depending on the system setting
-- function get_appearance()
--     if wezterm.gui then
--         -- return wezterm.gui.get_appearance()
--         return 'Dark'
--     end
--     return 'Dark'
-- end

function scheme_for_appearance(appearance)
    if appearance:find 'Dark' then
        return 'Catppuccin Mocha' -- 'Modus-Vivendi'
    else
        -- return 'Catppuccin Latte' -- 'Modus-Operandi'
        return 'Catppuccin Mocha' -- 'Modus-Vivendi'
    end
end

config.automatically_reload_config = true

config.check_for_updates = true

-- Font settings
config.font_size = 15
config.line_height = 1.5
config.font = wezterm.font_with_fallback {
    {
        family = 'Monaspace Argon NF',
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

-- Appearance
config.cursor_blink_rate = 300
-- config.window_decorations = 'RESIZE'
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
    left = 4,
    right = 4,
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

-- Colors
-- color_scheme = 'Modus-Vivendi',
config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

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

config.enable_scroll_bar = true

config.enable_tab_bar = true

config.native_macos_fullscreen_mode = true -- false
config.keys = {
    {
        key = 'n',
        mods = 'SHIFT|CTRL',
        action = wezterm.action.ToggleFullScreen,
    },
}

wezterm.on('gui-startup', function(window)
    local tab, pane, window = mux.spawn_window(cmd or {})
    local gui_window = window:gui_window();
    gui_window:perform_action(wezterm.action.ToggleFullScreen, pane)
end)

config.prefer_to_spawn_tabs = true -- false

config.check_for_updates = true
config.check_for_updates_interval_seconds = 86400
config.show_update_window = true -- false

config.tab_bar_at_bottom = true  -- false


-- The filled in variant of the < symbol
local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider

-- The filled in variant of the > symbol
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider

-- config.tab_bar_style = {
--     active_tab_left = wezterm.format {
--         { Background = { Color = '#0b0022' } },
--         { Foreground = { Color = '#2b2042' } },
--         { Text = SOLID_LEFT_ARROW },
--     },
--     active_tab_right = wezterm.format {
--         { Background = { Color = '#0b0022' } },
--         { Foreground = { Color = '#2b2042' } },
--         { Text = SOLID_RIGHT_ARROW },
--     },
--     inactive_tab_left = wezterm.format {
--         { Background = { Color = '#0b0022' } },
--         { Foreground = { Color = '#1b1032' } },
--         { Text = SOLID_LEFT_ARROW },
--     },
--     inactive_tab_right = wezterm.format {
--         { Background = { Color = '#0b0022' } },
--         { Foreground = { Color = '#1b1032' } },
--         { Text = SOLID_RIGHT_ARROW },
--     },
-- }

config.visual_bell = {
    fade_in_duration_ms = 75,
    fade_out_duration_ms = 75,
    target = 'CursorColor',
}

-- Custom commands
wezterm.on('augment-command-palette', function()
    return commands
end)

return config
