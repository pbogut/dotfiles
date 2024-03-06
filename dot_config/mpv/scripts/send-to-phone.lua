local mp = require('mp')

mp.add_key_binding(nil, 'send_to_phone', function()
  local path = mp.get_property('path')
  local time = mp.get_property('time-pos')

  if time and path:match('[%&|%?]t%=%d+') then
    path = path:gsub('([%&|%?])t%=(%d+)', '%1t=' .. time)
  elseif time then
    local split = '?'
    if path:match('%?') then
      split = '&'
    end

    path = path .. split .. 't=' .. time
  end

  mp.osd_message('Opening on phone: ' .. path)
  os.execute('~/.scripts/open-on-phone.sh "' .. path .. '"')
end)
