local mp = require('mp')
local options = require('mp.options')

local auth_file = ''

if os.getenv('TRAKT_AUTH_FILE') then
  auth_file = os.getenv('TRAKT_AUTH_FILE')
elseif os.getenv('HOME') then
  auth_file = os.getenv('HOME') .. '/.config/mpv_trakt.json'
end

local opts = {
  client_id = os.getenv('TRAKT_CLIENT_ID') or '',
  client_secret = os.getenv('TRAKT_CLIENT_SECRET') or '',
  disable_output = false,
  auto_stop = true,
  auto_stop_threshold = 99,
  stop_on_pause = true,
  stop_on_pause_threshold = 95,
  auth_file_location = auth_file,
  icon_ok = '/usr/share/icons/gnome/48x48/emblems/emblem-default.png',
  icon_err = '/usr/share/icons/gnome/48x48/emblems/emblem-important.png',
}

options.read_options(opts, 'trakt')

local function log(message)
  if not opts.disable_output then
    print(message)
  end
end

local last_enabled = false

local function is_enabled()
  local path = mp.get_property("path")
  last_enabled = true
  if path and path:match('http.?://.-invidious') or
     path and path:match('http.?://.-youtube')
  then
    last_enabled = false
  end

  if path and not path:match('http://192.168') then
    last_enabled = false
  end

  return last_enabled
end

last_enabled = is_enabled()

local function trakt_cmd(opt)
  local args = {
    'python',
    mp.get_script_directory() .. '/trakt_cmd.py',
    '--client-id',
    opts.client_id,
    '--client-secret',
    opts.client_secret,
    '--auth-file',
    opts.auth_file_location,
  }

  for key, val in pairs(opt) do
    args[#args + 1] = '--' .. key:gsub('%_', '%-')
    if val ~= true then
      args[#args + 1] = tostring(val)
    end
  end

  local result = mp.command_native({
    name = 'subprocess',
    playback_only = false,
    capture_stdout = true,
    capture_stderr = true,
    args = args,
  })
  if result then
    log(result.stdout)
    if result.stderr then
      log(result.stderr)
    end
    return result.stdout
  else
    log('There was an error when trying to execute trakt_cmd.py')
    return ''
  end
end

mp.add_key_binding(nil, 'trakt_reauth', function()
  trakt_cmd({ reauth = true })
end)

mp.add_key_binding(nil, 'trakt_history', function()
  local result = trakt_cmd({ history = true })
  mp.osd_message('Trakt history: \n' .. result)
  mp.osd_message(result, 5)
end)

local function red(text)
  local ass_start = mp.get_property_osd('osd-ass-cc/0')
  local ass_stop = mp.get_property_osd('osd-ass-cc/1')
  return ass_start .. '{\\1c&H0000FF&}' .. text .. ass_stop
end
local function green(text)
  local ass_start = mp.get_property_osd('osd-ass-cc/0')
  local ass_stop = mp.get_property_osd('osd-ass-cc/1')
  return ass_start .. '{\\1c&H00FF00&}' .. text .. ass_stop
end

local function trakt(action, title, progress)
  if not is_enabled() then
    return false
  end
  if title == nil or progress == nil then
    return false
  end
  -- if given % watched send it as stop, to mark it as watched
  if
    action == 'pause'
    and opts.stop_on_pause
    and progress > opts.stop_on_pause_threshold
  then
    action = 'stop'
  end

  local result = trakt_cmd({
    name = title,
    progress = progress,
    action = action,
  })

  if result:match('Response received: None') or result == "" then
    mp.osd_message(red('Trakt: ' .. action .. ' FAILED\n') .. title, 2)
    return false
  else
    mp.osd_message(green('Trakt: ' .. action .. ' ' .. 'SUCCEED\n') .. title, 2)
    return true
  end
end

local last_title = nil
local last_progress = nil
local stopped = false

mp.register_event('shutdown', function()
  if last_title and last_enabled then
    local success = trakt('stop', last_title, last_progress)
    local icon = ''
    local msg = ''

    if success then
      icon = opts.icon_ok
      msg = 'Trakt stop succeed'
    else
      icon = opts.icon_err
      msg = 'Trakt stop FAILED'
    end

    mp.command_native({
      name = 'subprocess',
      playback_only = false,
      capture_stdout = true,
      capture_stderr = true,
      args = {'notify-send', '-i', icon, msg}
    })
  end
end)

local function get_progress()
  if mp.get_property('percent-pos') == nil then
    return nil
  end
  return math.floor(mp.get_property('percent-pos') + 0.5)
end

local function get_title()
  -- log(mp.get_property('path'))
  -- log(mp.get_property('path'):match('youtube'))
  return mp.get_property('media-title')
end

local function media_changed(new, old)
  if old then
    trakt('stop', old.title, old.progress)
  end
  if new then
    trakt('start', new.title, new.progress)
  end
end

local function check_title()
  local progress = get_progress()
  local title = get_title()

  -- wait for progress and title to be available before update
  if progress == nil or title == nil then
    return
  end

  -- Mark it done above 95, just in case mpv shut down without updating
  if
    not stopped
    and opts.auto_stop
    and last_progress
    and last_progress > opts.auto_stop_threshold
  then
    stopped = trakt('stop', last_title, last_progress)
  end

  if last_title == nil then
    media_changed({ title = title, progress = progress })
  elseif last_title ~= title then
    media_changed(
      { title = title, progress = progress },
      { title = last_title, progress = last_progress }
    )
    stopped = false -- disable stopped after title change
  end

  last_title = title
  last_progress = progress
end

mp.add_periodic_timer(1, check_title)

local function update_idle(_, idle)
  if idle then
    trakt('stop', get_title(), get_progress())
  end
end

local function update_pause(_, pause)
  if pause then
    trakt('pause', get_title(), get_progress())
  else
    trakt('start', get_title(), get_progress())
  end
end

mp.observe_property('idle', 'bool', update_idle)
mp.observe_property('pause', 'bool', update_pause)
