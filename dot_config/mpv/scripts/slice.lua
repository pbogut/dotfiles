local msg = require('mp.msg')
local utils = require('mp.utils')
local options = require('mp.options')

local startpos
local endpos
local o = {
  target_dir = '~/Videos',
  command_template = [[
    ffmpeg -v warning -y -stats
    -ss $startpos -i "$in" -t $duration
    -c:v copy -c:a copy "$out.$ext"
  ]],
}
options.read_options(o)

function timestamp(duration)
  local hours = duration / 3600
  local minutes = duration % 3600 / 60
  local seconds = duration % 60
  return string.format('%02d-%02d-%02.03f', hours, minutes, seconds)
end

function osd(str)
  return mp.osd_message(str, 3)
end

function get_homedir()
  -- It would be better to do platform detection instead of fallback but
  -- it's not that easy in Lua.
  return os.getenv('HOME') or os.getenv('USERPROFILE') or ''
end

function log(str)
  local logpath = utils.join_path(o.target_dir:gsub('~', get_homedir()), 'mpv_slicing.log')
  f = io.open(logpath, 'a')
  f:write(string.format('# %s\n%s\n', os.date('%Y-%m-%d %H:%M:%S'), str))
  f:close()
end

function escape(str)
  -- FIXME(Kagami): This escaping is NOT enough, see e.g.
  -- https://stackoverflow.com/a/31413730
  -- Consider using `utils.subprocess` instead.
  return str:gsub('\\', '\\\\'):gsub('"', '\\"')
end

function trim(str)
  return str:gsub('^%s+', ''):gsub('%s+$', '')
end

function get_csp()
  local csp = mp.get_property('colormatrix')
  if csp == 'bt.601' then
    return 'bt601'
  elseif csp == 'bt.709' then
    return 'bt709'
  elseif csp == 'smpte-240m' then
    return 'smpte240m'
  else
    local err = 'Unknown colorspace: ' .. csp
    osd(err)
    error(err)
  end
end

function get_outname(startpos, endpos)
  local name = mp.get_property('filename')
  local dotidx = name:reverse():find('.', 1, true)
  if dotidx then
    name = name:sub(1, -dotidx - 1)
  end
  name = name:gsub(' ', '_')
  name = name:gsub(':', '-')
  name = name .. string.format('.%s-%s', timestamp(startpos), timestamp(endpos))
  return name
end

function cut(startpos, endpos)
  local cmd = trim(o.command_template:gsub('%s+', ' '))
  local inpath = escape(utils.join_path(utils.getcwd(), mp.get_property('stream-path')))
  local basedir = inpath:gsub('^(.+)[/\\].+$', '%1')
  local outpath = escape(utils.join_path(
    -- o.target_dir:gsub("~", get_homedir()),
    basedir,
    get_outname(startpos, endpos)
  ))

  local ext = inpath:gsub('^.+%.(.+)$', '%1')

  cmd = cmd:gsub('$startpos', startpos)
  cmd = cmd:gsub('$duration', endpos - startpos)
  cmd = cmd:gsub('$ext', ext)
  cmd = cmd:gsub('$out', outpath)
  cmd = cmd:gsub('$in', inpath, 1)

  msg.info(cmd)
  log(cmd)
  os.execute(cmd)
end

function mark_validation()
  if startpos == endpos then
    osd('Cut fragment is empty')
  end
end

function mark_show()
  if startpos and endpos then
    osd(string.format('Marked fragment: %s - %s', timestamp(startpos), timestamp(endpos)))
  elseif startpos then
    osd(string.format('Marked fragment: %s - ...', timestamp(startpos)))
  elseif endpos then
    osd(string.format('Marked fragment: ... - %s', timestamp(endpos)))
  end
end

function mark_end()
  local pos = mp.get_property_number('time-pos')
  endpos = pos
  if startpos and endpos and startpos > endpos then
    startpos = nil
  end
  mark_validation()
  mark_show()
end

function mark_start()
  local pos = mp.get_property_number('time-pos')
  startpos = pos
  if startpos and endpos and startpos > endpos then
    endpos = nil
  end
  mark_validation()
  mark_show()
end

function cut_fragment()
  if startpos and endpos and startpos < endpos then
    cut(startpos, endpos)
    osd(string.format('Cut fragment: %s - %s', timestamp(startpos), timestamp(endpos)))
  else
    osd(string.format('Cut fragment invalid'))
  end
end

mp.add_key_binding(nil, 'slicing_start', mark_start)
mp.add_key_binding(nil, 'slicing_end', mark_end)
mp.add_key_binding(nil, 'slicing_save', cut_fragment)
