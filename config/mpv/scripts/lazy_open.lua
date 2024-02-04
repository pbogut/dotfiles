local mp = require('mp')

local M = {}
local will_close = false

function M.open_url(url)
  if mp.get_property_native('focused') == true then
    mp.commandv('loadfile', url)

    mp.observe_property('time-remaining', nil, function(_)
      local time_left = mp.get_property('time-remaining')
      if time_left then
        time_left = tonumber(time_left)
      end
      if time_left and time_left < 1.0 and not will_close then
        will_close = true
        mp.add_timeout(3, function()
          mp.commandv('quit', 0)
        end)
      end
    end)
  else
    mp.add_timeout(0.1, function()
      M.open_url(url)
    end)
  end
end

local url = os.getenv('LAZY_OPEN')
if url then
  M.open_url(url)
end
