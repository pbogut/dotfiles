local h = require('projector.helper')
local fn = vim.fn
local p = {}

p.module_name = function()
  local list = h.get_file_parts()
  if #list > 4 then
  return list[3] .. '_' .. list[4]
end
  return 'Vendor_ModuleName'
end

p.module_namespace = function()
  local list = h.get_file_parts()
  if list[2] == 'design' then
    return list[6]:gsub('%_', [[\]])
  end
  if #list > 4 then
    return list[3] .. [[\]] .. list[4]
  end
  return [[Vendor\ModuleName]]
end

p.resource_name = function()
  local list = h.get_file_parts()
  if #list > 4 then
    return list[#list-1]
  end
  return 'ResourceName'
end

p.resource_key = function()
  local list = h.get_file_parts()
  if #list > 4 then
    return list[#list-1]:lower()
  end
  return 'resourcename'
end

p.module_name_str = function()
  return p.module_name():gsub('_', ' '):gsub('([a-z0-9A-Z])([A-Z])', '%1 %2')
end

p.module_key = function()
  return p.module_name():lower()
end

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
  end

  return result
end

p.block_namespace = function()
  return p.namespace() .. [[\Block]]
end

p.block_class = function()
  local path = fn.expand('%:.'):gsub('^.*/view/frontend/templates/(.*).phtml$', '%1')
  return h.capitalize(h.camelcase(path))
end

p.snake_base_name = function()
  return h.snakecase(vim.fn.expand('%:t:r'))
end

p.drop_suffix_index = function()
  return vim.fn.expand('%:t:r'):gsub('_index$', '')
end

p.drop_suffix_edit = function()
  return vim.fn.expand('%:t:r'):gsub('_edit$', '')
end

return p
