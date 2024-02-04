-- Pull in the wezterm API
local wezterm = require('wezterm')
local act = wezterm.action

function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then
    return s
  end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

local c = {}

if wezterm.config_builder then
  c = wezterm.config_builder()
end

c.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

c.enable_tab_bar = true
c.tab_bar_at_bottom = true
c.tab_max_width = 16
c.use_fancy_tab_bar = false

c.font = wezterm.font('InputMono Nerd Font Mono')
c.font_size = 12
c.colors = {
  -- The default text color
  foreground = '#839496',
  -- The default background color
  background = '#002b36',

  -- Overrides the cell background color when the current cell is occupied by the
  -- cursor and the cursor style is set to Block
  cursor_bg = '#8a8a8a',
  -- Overrides the text color when the current cell is occupied by the cursor
  cursor_fg = 'black',
  -- Specifies the border color of the cursor when the cursor style is set to Block,
  -- or the color of the vertical or horizontal bar when the cursor style is set to
  -- Bar or Underline.
  cursor_border = '#8a8a8a',

  -- the foreground color of selected text
  selection_fg = 'black',
  -- the background color of selected text
  selection_bg = '#fffacd',

  -- The color of the scrollbar "thumb"; the portion that represents the current viewport
  scrollbar_thumb = '#222222',

  -- The color of the split lines between panes
  split = '#444444',

  ansi = {
    '#073642',
    '#dc322f',
    '#859900',
    '#b58900',
    '#268bd2',
    '#d33682',
    '#2aa198',
    '#eee8d5',
  },
  brights = {

    'grey',
    -- '0x002b36'
    '#cb4b16',
    '#586e75',
    '#657b83',
    '#839496',
    '#6c71c4',
    '#93a1a1',
    '#fdf6e3',
  },

  -- Arbitrary colors of the palette in the range from 16 to 255
  -- indexed = { [136] = "#af8700" },

  -- Since: 20220319-142410-0fcdea07
  -- When the IME, a dead key or a leader key are being processed and are effectively
  -- holding input pending the result of input composition, change the cursor
  -- to this color to give a visual cue about the compose state.
  compose_cursor = 'orange',

  -- Colors for copy_mode and quick_select
  -- available since: 20220807-113146-c2fee766
  -- In copy_mode, the color of the active text is:
  -- 1. copy_mode_active_highlight_* if additional text was selected using the mouse
  -- 2. selection_* otherwise
  copy_mode_active_highlight_bg = { Color = '#b58900' },
  -- use `AnsiColor` to specify one of the ansi color palette values
  -- (index 0-15) using one of the names "Black", "Maroon", "Green",
  --  "Olive", "Navy", "Purple", "Teal", "Silver", "Grey", "Red", "Lime",
  -- "Yellow", "Blue", "Fuchsia", "Aqua" or "White".
  copy_mode_active_highlight_fg = { AnsiColor = 'Black' },
  copy_mode_inactive_highlight_bg = { Color = '#52ad70' },
  copy_mode_inactive_highlight_fg = { AnsiColor = 'White' },

  quick_select_label_bg = { Color = 'peru' },
  quick_select_label_fg = { Color = '#ffffff' },
  quick_select_match_bg = { AnsiColor = 'Navy' },
  quick_select_match_fg = { Color = '#ffffff' },
  tab_bar = {
    -- The color of the strip that goes along the top of the window
    -- (does not apply when fancy tab bar is in use)
    background = '#001c26',

    -- The active tab is the one that has focus in the window
    active_tab = {
      -- The color of the background area for the tab
      -- bg_color = "#5f8700", -- green
      bg_color = '#268bd2', -- blue
      -- The color of the text for the tab
      fg_color = '#eee8d5',

      -- Specify whether you want "Half", "Normal" or "Bold" intensity for the
      -- label shown for this tab.
      -- The default is "Normal"
      intensity = 'Bold',

      -- Specify whether you want "None", "Single" or "Double" underline for
      -- label shown for this tab.
      -- The default is "None"
      underline = 'None',

      -- Specify whether you want the text to be italic (true) or not (false)
      -- for this tab.  The default is false.
      italic = false,

      -- Specify whether you want the text to be rendered with strikethrough (true)
      -- or not for this tab.  The default is false.
      strikethrough = false,
    },
    inactive_tab = {
      bg_color = '#002b36',
      fg_color = '#839496',
    },
    inactive_tab_hover = {
      bg_color = '#073642',
      fg_color = '#839496',
      italic = false,
    },
    new_tab = {
      bg_color = '#00222b',
      fg_color = '#839496',
    },
    new_tab_hover = {
      bg_color = '#073642',
      fg_color = '#839496',
      italic = false,
    },
  },
}

c.disable_default_key_bindings = true

local my_act = {}

function my_act.ActivateOrCreateTab(no)
  return wezterm.action_callback(function(win, pane)
    local mux_win = win:mux_window()
    while #mux_win:tabs() <= no do
      mux_win:spawn_tab({}):activate()
    end
    mux_win:tabs()[no + 1]:activate()
  end)
end

c.leader = { key = 'g', mods = 'CTRL', timeout_milliseconds = 1000 }

local copy_mode = {
  {
    key = 'Escape',
    mods = 'NONE',
    action = act.Multiple({
      act.CopyMode('ClearPattern'),
      act.CopyMode('Close'),
    }),
  },
  {
    key = '/',
    mods = 'NONE',
    action = act.CopyMode('EditPattern'),
  },
  {
    key = 'n',
    mods = 'NONE',
    action = act.Multiple({
      act.CopyMode('PriorMatch'),
      act.CopyMode({ SetSelectionMode = 'Cell' }),
    }),
  },
  {
    key = 'N',
    mods = 'NONE',
    action = act.Multiple({
      act.CopyMode('NextMatch'),
      act.CopyMode({ SetSelectionMode = 'Cell' }),
    }),
  },
  {
    key = 'p',
    mods = 'NONE',
    action = act.Multiple({
      act.CopyMode('NextMatch'),
      act.CopyMode({ SetSelectionMode = 'Cell' }),
    }),
  },
  {
    key = 'y',
    mods = 'NONE',
    action = act.Multiple({
      act.CopyTo('Clipboard'),
      act.ClearSelection,
      act.CopyMode('ClearPattern'),
      act.CopyMode('Close'),
    }),
  },
}
local search_mode = {
  {
    key = 'Escape',
    mods = 'NONE',
    action = act.Multiple({
      act.CopyMode('ClearPattern'),
      act.CopyMode('Close'),
    }),
  },
  {
    key = 'Enter',
    mods = 'NONE',
    action = act.Multiple({
      act.CopyMode({ SetSelectionMode = 'Cell' }),
      act.CopyMode('AcceptPattern'),
    }),
  },
  {
    key = '/',
    mods = 'NONE',
    action = act.CopyMode('EditPattern'),
  },
}
c.keys = {
  {
    key = 'g',
    mods = 'LEADER|CTRL',
    action = wezterm.action.SendKey({ key = 'g', mods = 'CTRL' }),
  },
  -- This will create a new split and run your default program inside it
  {
    key = 'v',
    mods = 'LEADER',
    action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
  },
  {
    key = 's',
    mods = 'LEADER',
    action = act.SplitVertical({ domain = 'CurrentPaneDomain' }),
  },
  {
    key = '/',
    mods = 'LEADER',
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(act.Search({ CaseInSensitiveString = '' }), pane)
      window:perform_action(act.CopyMode('ClearPattern'), pane)
    end),
  },
  {
    key = 'l',
    mods = 'LEADER',
    action = act.ShowDebugOverlay,
  },
  {
    key = 'p',
    mods = 'CTRL|ALT',
    action = act.PasteFrom('Clipboard'),
  },
  {
    key = ';',
    mods = 'CTRL|ALT',
    action = act.PasteFrom('PrimarySelection'),
  },
  {
    key = 'Escape',
    mods = 'ALT',
    action = act.ActivateCopyMode,
  },
  {
    key = 'u',
    mods = 'LEADER|CTRL',
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(act.ActivateCopyMode, pane)
      window:perform_action(act.CopyMode({ MoveByPage = -0.5 }), pane)
    end),
  },
  {
    key = 'u',
    mods = 'ALT',
    action = wezterm.action.QuickSelectArgs({
      label = 'open url',
      patterns = {
        'https?://[^"\\s]+',
      },
      action = wezterm.action_callback(function(window, pane)
        local url = window:get_selection_text_for_pane(pane)
        wezterm.log_info('opening: ' .. url)
        wezterm.open_with(url)
      end),
    }),
  },
  {
    key = 'e',
    mods = 'LEADER',
    action = wezterm.action.EmitEvent('x-scrollback-nvim'),
  },

  -- Create a new workspace with a random name and switch to it
  { key = 'i', mods = 'CTRL|SHIFT', action = act.SwitchToWorkspace },
  -- Show the launcher in fuzzy selection mode and have it list all workspaces
  -- and allow activating one.
  {
    key = '9',
    mods = 'ALT',
    action = act.ShowLauncherArgs({
      flags = 'FUZZY|WORKSPACES',
    }),
  },
  -- switch pane
  {
    -- on my keyboard ctrl + h is sending backspace
    key = 'Backspace',
    mods = 'ALT',
    action = act.ActivatePaneDirection('Left'),
  },
  {
    key = 'h',
    mods = 'CTRL|ALT',
    action = act.ActivatePaneDirection('Left'),
  },
  {
    key = 'l',
    mods = 'CTRL|ALT',
    action = act.ActivatePaneDirection('Right'),
  },
  {
    key = 'k',
    mods = 'CTRL|ALT',
    action = act.ActivatePaneDirection('Up'),
  },
  {
    key = 'j',
    mods = 'CTRL|ALT',
    action = act.ActivatePaneDirection('Down'),
  },
  {
    key = 'z',
    mods = 'LEADER',
    action = act.TogglePaneZoomState,
  },
  -- tabs
  {
    key = 'c',
    mods = 'CTRL|ALT',
    action = act.SpawnTab('CurrentPaneDomain'),
  },
  {
    key = 'j',
    mods = 'ALT',
    action = my_act.ActivateOrCreateTab(0),
  },
  {
    key = 'k',
    mods = 'ALT',
    action = my_act.ActivateOrCreateTab(1),
  },
  {
    key = 'l',
    mods = 'ALT',
    action = my_act.ActivateOrCreateTab(2),
  },
  {
    key = ';',
    mods = 'ALT',
    action = my_act.ActivateOrCreateTab(3),
  },
}

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local title = tab.tab_title

  -- if the tab title is explicitly set, take that
  if not title or #title == 0 then
    title = tab.active_pane.title
    -- local process_name = tab.active_pane.foreground_process_name
    -- if process_name and #process_name > 0 then
    --   title = process_name:gsub('^.*/', '')
    -- end
  end
  title = (tab.tab_index + 1) .. ': ' .. title
  if #title >= c.tab_max_width - 1 then
    title = title:sub(1, c.tab_max_width - 4)
  end

  local before_sep = '  '
  local after_sep = '  '
  local fg_color = c.colors.tab_bar.inactive_tab.fg_color
  -- local bg_color = c.colors.tab_bar.inactive_tab.bg_color
  local bg_color = c.colors.tab_bar.inactive_tab.bg_color
  local fg_sep = c.colors.tab_bar.inactive_tab.fg_color
  local bg_sep = c.colors.tab_bar.inactive_tab.bg_color
  if tab.is_active then
    before_sep = '█'
    after_sep = '█'
    fg_color = c.colors.tab_bar.active_tab.fg_color
    bg_color = c.colors.tab_bar.active_tab.bg_color
    fg_sep = bg_color
  end
  if tab.tab_index == 0 then
    if tab.is_active then
      before_sep = '█'
    else
      before_sep = ' '
    end
  end

  return {
    { Background = { Color = bg_sep } },
    { Foreground = { Color = fg_sep } },
    { Text = before_sep },
    { Background = { Color = bg_color } },
    { Foreground = { Color = fg_color } },
    { Text = title },
    { Background = { Color = bg_sep } },
    { Foreground = { Color = fg_sep } },
    { Text = after_sep },
  }
end)

local status_cache = {
  right = {},
  title = {},
}

local function get_status(cwd_uri, status_type)
  status_type = status_type or 'right'
  if cwd_uri and not status_cache[status_type][cwd_uri] then
    local cwd = ''
    local hostname = ''
    if type(cwd_uri) == 'userdata' then
      -- Running on a newer version of wezterm and we have
      -- a URL object here, making this simple!

      cwd = cwd_uri.file_path
      hostname = cwd_uri.host or wezterm.hostname()
    else
      -- an older version of wezterm, 20230712-072601-f4abf8fd or earlier,
      -- which doesn't have the Url object
      cwd_uri = cwd_uri:sub(8)
      local slash = cwd_uri:find('/')
      if slash then
        hostname = cwd_uri:sub(1, slash - 1)
        -- and extract the cwd from the uri, decoding %-encoding
        cwd = cwd_uri:sub(slash):gsub('%%(%x%x)', function(hex)
          return string.char(tonumber(hex, 16))
        end)
      end
    end
    cwd = cwd:gsub('%/$', '')

    local session_name = os.capture('wezterm-status ' .. cwd .. ' --' .. status_type)
    status_cache[status_type][cwd_uri] = session_name
  end

  return status_cache[status_type][cwd_uri] or ''
end

local function get_pid()
  local socket = os.getenv('WEZTERM_UNIX_SOCKET')
  if not socket then
    return
  end
  local pid = socket:gsub('.*%-(%d+)', '%1')
  return pid
end

wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
  local zoomed = ''
  if tab.active_pane.is_zoomed then
    zoomed = '[Z] '
  end

  local status_text = os.getenv('WEZTERM_PROJECT') or '' -- get_status(cwd_uri, 'title')
  if status_text and status_text:len() > 0 then
    status_text = '[' .. status_text .. '] '
  end
  local id = ' |w$' .. get_pid() .. ':' .. pane.pane_id
  local index = ''
  if #tabs > 1 then
    index = string.format('[%d/%d] ', tab.tab_index + 1, #tabs)
  end

  return zoomed .. status_text .. index .. tab.active_pane.title .. ' ' .. id
end)

wezterm.on('update-right-status', function(window, _)
  local status_text = os.getenv('WEZTERM_PROJECT') or '' -- get_status(cwd_uri, 'title')
  window:set_right_status(status_text)
end)

wezterm.on('x-scrollback-nvim', function(window, pane)
  local scrollback = pane:get_lines_as_text()
  local name = os.tmpname()
  local f = io.open(name, 'w+')
  if not f then
    return
  end

  f:write(scrollback)
  f:flush()
  f:close()

  window:perform_action(
    wezterm.action({ SpawnCommandInNewWindow = {
      args = { 'nvim', name },
    } }),
    pane
  )

  wezterm.sleep_ms(1000)
  os.remove(name)
end)

-- merge custom keys with default keys
local copy_mode_keys = wezterm.gui.default_key_tables().copy_mode
local search_mode_keys = wezterm.gui.default_key_tables().search_mode

for _, v in ipairs(copy_mode) do
  table.insert(copy_mode_keys, v)
end

for _, v in ipairs(search_mode) do
  table.insert(search_mode_keys, v)
end

c.key_tables = {
  copy_mode = copy_mode_keys,
  search_mode = search_mode_keys,
}

return c
