-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end


-- This is where you actually apply your config choices


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

config = {
  adjust_window_size_when_changing_font_size = false,

  -- I got the GPU settings below from a comment by user @anthonyknowles
  -- In my wezterm video and will test them out
  -- https://youtu.be/ibCPb4tSRXM
  -- https://wezfurlong.org/wezterm/config/lua/config/animation_fps.html?h=animation
  animation_fps = 120,

  automatically_reload_config = true,
  background = {
    {
      source = {
        File = "/Users/" .. os.getenv("USER") .. "/.config/wezterm/mariam-soliman-Ht5XmeuLyDg-unsplash.jpg",
      },
      hsb = {
        hue = 1.0,
        saturation = 1.02,
        brightness = 0.25,
      },
      -- attachment = { Parallax = 0.3 },
      -- width = "100%",
      -- height = "100%",
    },
    {
      source = {
        Color = "#282c35",
      },
      width = "100%",
      height = "100%",
      opacity = 0.55,
    },
  },
  check_for_updates = true,

  -- color_scheme = 'Modus-Vivendi',
  color_scheme = scheme_for_appearance(get_appearance()),

  cursor_blink_ease_in = 'Linear',
  cursor_blink_ease_out = 'Linear',
  default_cursor_style = "BlinkingBar",

  debug_key_events = true,

  -- To enable kitty graphics
  -- https://github.com/wez/wezterm/issues/986
  -- It seems that kitty graphics is not enabled by default according to this
  -- Not sure, so I'm enabling it just in case
  -- https://github.com/wez/wezterm/issues/1406#issuecomment-996253377
  enable_kitty_graphics = true,

  enable_kitty_keyboard = true,

  enable_tab_bar = true,

  font = wezterm.font_with_fallback {
    'Dank Mono', 'Iosevka Comfy', 'GeistMono Nerd Font', 'JetBrains Mono', 'OpenDyslexicM Nerd Font', 'NotoColorEmoji',
  },
  font_size = 18,

  force_reverse_video_cursor = true,

  -- front_end = "WebGpu" - will more directly use Metal than the OpenGL
  -- The default is "WebGpu". In earlier versions it was "OpenGL"
  -- Metal translation used on M1 machines, may yield some more fps.
  -- https://github.com/wez/wezterm/discussions/3664
  -- https://wezfurlong.org/wezterm/config/lua/config/front_end.html?h=front_
  front_end = "WebGpu",

  -- https://wezfurlong.org/wezterm/config/lua/config/webgpu_preferred_adapter.html?h=webgpu_preferred_adapter
  -- webgpu_preferred_adapter

  -- webgpu_power_preference = "LowPower"
  -- https://wezfurlong.org/wezterm/config/lua/config/webgpu_power_preference.html

  hyperlink_rules = {
    -- from: https://akos.ma/blog/adopting-wezterm/

    { -- make username/project paths clickable. this implies paths like the following are for github.
      -- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
      -- as long as a full url hyperlink regex exists above this it should not match a full url to
      -- github or gitlab / bitbucket (i.e. https://gitlab.com/user/project.git is still a whole clickable url)
      regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
      format = 'https://www.github.com/$1/$3',
      highlight = 1,
    },
    { -- Matches: a URL in parens: (URL)
      regex = "\\((\\w+://\\S+)\\)",
      format = "$1",
      highlight = 1,
    },
    { -- Matches: a URL in brackets: [URL]
      regex = "\\[(\\w+://\\S+)\\]",
      format = "$1",
      highlight = 1,
    },
    { -- Matches: a URL in braces: {URL}
      regex = "\\{(\\w+://\\S+)\\}",
      format = "$1",
      highlight = 1,
    },
    { -- Matches: a URL in chevrons: <URL>
      regex = "<(\\w+://\\S+)>",
      format = "$1",
      highlight = 1,
    },
    { -- Then handle URLs not wrapped in brackets
      -- Before
      --regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
      --format = '$0',
      -- After
      regex = "[^(]\\b(\\w+://\\S+[)/a-zA-Z0-9-]+)",
      format = "$1",
      highlight = 1,
    },
    { -- implicit mailto link
      regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
      format = "mailto:$0",
      highlight = 1,
    },
  },

  -- tmux
  leader = { key = "q", mods = "ALT", timeout_milliseconds = 2000 },
  keys = {
    {
      mods = "LEADER",
      key = "c",
      action = wezterm.action.SpawnTab "CurrentPaneDomain",
    },
    {
      mods = "LEADER",
      key = "x",
      action = wezterm.action.CloseCurrentPane { confirm = true }
    },
    {
      mods = "LEADER",
      key = "b",
      action = wezterm.action.ActivateTabRelative(-1)
    },
    {
      mods = "LEADER",
      key = "n",
      action = wezterm.action.ActivateTabRelative(1)
    },
    {
      mods = "LEADER",
      key = "|",
      action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" }
    },
    {
      mods = "LEADER",
      key = "-",
      action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" }
    },
    {
      mods = "LEADER",
      key = "h",
      action = wezterm.action.ActivatePaneDirection "Left"
    },
    {
      mods = "LEADER",
      key = "j",
      action = wezterm.action.ActivatePaneDirection "Down"
    },
    {
      mods = "LEADER",
      key = "k",
      action = wezterm.action.ActivatePaneDirection "Up"
    },
    {
      mods = "LEADER",
      key = "l",
      action = wezterm.action.ActivatePaneDirection "Right"
    },
    {
      mods = "LEADER",
      key = "LeftArrow",
      action = wezterm.action.AdjustPaneSize { "Left", 5 }
    },
    {
      mods = "LEADER",
      key = "RightArrow",
      action = wezterm.action.AdjustPaneSize { "Right", 5 }
    },
    {
      mods = "LEADER",
      key = "DownArrow",
      action = wezterm.action.AdjustPaneSize { "Down", 5 }
    },
    {
      mods = "LEADER",
      key = "UpArrow",
      action = wezterm.action.AdjustPaneSize { "Up", 5 }
    },
  },

  -- Limits the maximum number of frames per second that wezterm will attempt to draw
  -- I tried settings this value to 5, 15, 30, 60 and you do feel a difference
  -- It feels WAY SMOOTHER at 120
  -- In my humble opiniont, 120 should be the default as I'm not the only one
  -- experiencing this "performance" issue in wezterm
  -- https://wezfurlong.org/wezterm/config/lua/config/max_fps.html
  max_fps = 240,

  -- How many lines of scrollback you want to retain per tab
  scrollback_lines = 1000000,
  -- Enable the scrollbar.
  -- It will occupy the right window padding space.
  -- If right padding is set to 0 then it will be increased
  -- to a single cell width
  enable_scroll_bar = true,

  -- -- Setting the term to wezterm is what allows support for undercurl
  -- --
  -- -- BEFORE you can set the term to wezterm, you need to install a copy of the
  -- -- wezterm TERM definition
  -- -- https://wezfurlong.org/wezterm/config/lua/config/term.html?h=term
  -- -- https://github.com/wez/wezterm/blob/main/termwiz/data/wezterm.terminfo
  -- --
  -- -- If you're using tmux, set your tmux.conf file to:
  -- -- set -g default-terminal "${TERM}"
  -- -- So that it picks up the wezterm TERM we're defining here
  -- --
  -- -- NOTE: When inside neovim, run a `checkhealth` and under `tmux` you will see that
  -- -- the term is set to `wezterm`. If the term is set to something else:
  -- -- - Reload your tmux configuration,
  -- -- - Then close all your tmux sessions, one at a time and quit wezterm
  -- -- - re-open wezterm
  -- term = "wezterm",
  term = "xterm-256color",

  -- When using the wezterm terminfo file, I had issues with images in neovim, images
  -- were shown like split in half, and some part of the image always stayed on the
  -- screen until I quit neovim
  --
  -- Images are working wonderfully in kitty, so decided to try the kitty.terminfo file
  -- https://github.com/kovidgoyal/kitty/blob/master/terminfo/kitty.terminfo
  --
  -- NOTE: I added a modified version of this in my zshrc file, so if the kitty terminfo
  -- file is not present it will be downloaded and installed automatically
  --
  -- But if you want to manually download and install the kitty terminfo file
  -- run the command below on your terminal:
  -- tempfile=$(mktemp) \
  --     && curl -o "$tempfile" https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo \
  --     && tic -x -o ~/.terminfo "$tempfile" \
  --     && rm "$tempfile"
  --
  -- NOTE: When inside neovim, run a `checkhealth` and under `tmux` you will see that
  -- the term is set to `xterm-kitty`. If the term is set to something else:
  -- - Reload your tmux configuration,
  -- - Then close all your tmux sessions, one at a time and quit wezterm
  -- - re-open wezterm
  --
  -- Then you'll be able to set your terminal to `xterm-kitty` as seen below
  --term = "xterm-kitty",


  -- tab bar
  hide_tab_bar_if_only_one_tab = false,
  tab_and_split_indices_are_zero_based = false,
  tab_bar_at_bottom = false,
  use_fancy_tab_bar = true,

  macos_window_background_blur = 20,
  window_background_opacity = 0.90,
  window_close_confirmation = "NeverPrompt",
  window_decorations = "TITLE|RESIZE",
  window_frame = {
    active_titlebar_bg = '#2b2042',
    active_titlebar_border_bottom = '#2b2042',
    active_titlebar_fg = '#ffffff',
    border_bottom_color = 'purple',
    border_bottom_height = '0.25cell',
    border_left_color = 'purple',
    border_left_width = '0.5cell',
    border_right_color = 'purple',
    border_right_width = '0.5cell',
    border_top_color = 'purple',
    border_top_height = '0.25cell',
    button_bg = '#2b2042',
    button_fg = '#cccccc',
    button_hover_bg = '#3b3052',
    button_hover_fg = '#ffffff',
    font = require('wezterm').font 'OpenDyslexicM Nerd Font',
    font_size = 12,
    inactive_titlebar_bg = '#353535',
    inactive_titlebar_border_bottom = '#2b2042',
    inactive_titlebar_fg = '#cccccc',
  },
  window_padding = {
    left = 3,
    right = 3,
    top = 0,
    bottom = 0,
  },
}

for i = 0, 9 do
  -- leader + number to activate that tab
  table.insert(config.keys, {
    mods = "LEADER",
    key = tostring(i),
    action = wezterm.action.ActivateTab(i),
  })
end

return config
