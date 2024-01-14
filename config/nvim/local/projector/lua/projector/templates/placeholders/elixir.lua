local h = require('projector.helper')
local c = require('pbogut.config')
local p = {}

p.module_name_parts = function()
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
      'features',
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

  local main_module = nil
  local has_file, content = pcall(vim.fn.readfile, 'lib/' .. list[1] .. '.ex')
  if has_file then
    for _, line in pairs(content) do
      if line:match('defmodule ') then
        main_module = line:gsub('.*defmodule (%w+).*$', '%1')
        break
      end
    end
  end

  if main_module then
    list[1] = h.snakecase(main_module)
  end

  return h.map(h.map(list, h.camelcase), h.upper_first)
end

p.module_name = function()
  return table.concat(p.module_name_parts(), '.')
end

p.tested_module_name = function()
  return table.concat(p.module_name_parts(), '.'):gsub('Test$', '')
end

p.base_module = function()
  return p.module_name_parts()[1]
end

return p
