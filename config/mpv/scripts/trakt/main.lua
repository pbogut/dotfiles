local mp = require('mp')
local options = require('mp.options')

local opts = {
  client_id = os.getenv('TRAKT_CLIENT_ID') or '',
  client_secret = os.getenv('TRAKT_CLIENT_SECRET') or '',
  disable_output = false,
  auto_stop = true,
  auto_stop_threshold = 95,
  stop_on_pause = true,
  stop_on_pause_threshold = 90,
}
options.read_options(opts, 'trakt')

local function log(message)
  if not opts.disable_output then
    print(message)
  end
end

local function trakt_cmd(opt)
  local args = {
    'python',
    mp.get_script_directory() .. '/trakt_cmd.py',
    '--client-id',
    opts.client_id,
    '--client-secret',
    opts.client_secret,
  }

  for key, val in pairs(opt) do
    args[#args + 1] = '--' .. key:gsub('%_', '%-')
    if val ~= true then
      args[#args + 1] = tostring(val)
    end
  end

  return mp.command_native_async({
    name = 'subprocess',
    playback_only = false,
    capture_stdout = true,
    capture_stderr = true,
    args = args,
  }, function(_, result)
    if result then
      log(result.stdout)
    else
      log('There was an error when trying to execute trakt_cmd.py')
    end
  end)
end

mp.add_key_binding(nil, 'trakt_reauth', function()
  trakt_cmd({ reauth = true })
end)

local function trakt(action, title, progress)
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

  trakt_cmd({ name = title, progress = progress, action = action })

  return true
end

local last_title = nil
local last_progress = nil
local stopped = false

mp.register_event('shutdown', function()
  if last_title then
    trakt('stop', last_title, last_progress)
  end
end)

local function get_progress()
  if mp.get_property('percent-pos') == nil then
    return nil
  end
  return math.floor(mp.get_property('percent-pos') + 0.5)
end

local function get_title()
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
