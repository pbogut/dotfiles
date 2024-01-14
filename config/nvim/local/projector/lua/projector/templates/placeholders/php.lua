local u = require('pbogut.utils')
local h = require('projector.helper')
local fn = vim.fn
local p = {}

p.namespace = function()
  local list = h.get_file_parts()
  table.remove(list, #list)
  local result = ''
  for _, el in ipairs(list) do
    local sep = ''
    if result ~= '' then
      sep = [[\]]
    end
    if not el:match('^%l') then
      result = result .. sep .. el
    end
    -- if app folowed by other lowercase folders, remove it
    if result == 'App' and el:match('^%l') then
      result = ''
    end
    -- if class preceeded with App
    if result == '' and el == 'app' then
      result = 'App'
    end
  end

  return result
end

p.snake_name = function()
  return h.snakecase(fn.expand('%:t:r'))
end

p.class = function()
  return fn.expand('%:t:r')
end

p.class1 = function()
  local list = h.get_file_parts()
  local result = ''

  for _, el in ipairs(list) do
    local sep = ''
    if result ~= '' then
      sep = '_'
    end
    if not el:match('^%l') then
      result = result .. sep .. el
    end
    -- if app folowed by other lowercase folders, remove it
    if result == 'App' and el:match('^%l') then
      result = ''
    end
    -- if class preceeded with App
    if result == '' and el == 'app' then
      result = 'App'
    end
  end

  return result
end

p.doc = function()
  local next_line = h.get_relative_line(1)
  print(next_line)
  if next_line:match('class') then
    return 'doc_class'
  end
  if next_line:match('function') then
    return 'doc_function'
  end
  if next_line:match('protected %$%l') or next_line:match('public %$%l') or next_line:match('private %$%l') then
    return 'doc_property'
  end
  if next_line:match('%s+%$%l') then
    return 'doc_variable'
  end
  return 'doc'
end

p.get_class_name = function()
  local next_line = h.get_relative_line(1)
  return next_line:gsub('class (%w+).*$', '%1')
end

p.get_visibility = function()
  local next_line = h.get_relative_line(1)
  return h.upper_first(next_line:gsub('%s+(%w+) .*$', '%1'))
end

p.get_variable_name = function()
  local next_line = h.get_relative_line(1)
  return next_line:gsub('.*%$(%w+).*$', '%1')
end

p.get_function_name = function()
  local next_line = h.get_relative_line(1)
  return next_line:gsub('%s+%w+ function (%w+)%(.*$', '%1')
end

p._ = function()
  return '[[coursor_position]]'
end

return p
