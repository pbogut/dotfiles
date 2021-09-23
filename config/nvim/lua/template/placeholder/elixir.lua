local h = require('projector.helper')
local p = {}

p.module_name_parts = {
  value = function()
    local list = h.get_file_parts()
    if list[1] == 'lib' or list[1] == 'test' then
      table.remove(list, 1)
    end

    if list[1]:match('%_web$') then
      local skip = {
        -- phoenix
        'controllers',
        'views',
        'channels',
        'live',
        -- for tests
        'features'
      }

      local drop = false
      for _, s in pairs(skip) do
        if list[2] == s then
          drop = true
        end
      end
      if drop then
        table.remove(list, 2)
      end
    end

    return h.map(h.map(list, h.camelcase), h.upper_first)
  end
}
p.module_name = {
  value = function()
    return table.concat(p.module_name_parts.value(), '.')
  end
}
p.tested_module_name = {
  value = function()
    return table.concat(p.module_name_parts.value(), '.'):gsub('Test$', '')
  end
}
p.base_module = {
  value = function()
    return p.module_name_parts.value()[1]
  end
}

return p
