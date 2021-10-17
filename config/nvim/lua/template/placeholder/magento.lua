local h = require('projector.helper')
local p = {}

p.module_name = function()
  local list = h.get_file_parts()
  if #list > 5 then
    return list[4] .. '_' .. list[5]
  end
  return 'Vendor_ModuleName'
end

p.module_namespace = function()
  local list = h.get_file_parts()
  if #list > 5 then
    return list[4] .. [[\]] .. list[5]
  end
  return [[Vendor\ModuleName]]
end

p.module_name_str = function()
  return p.module_name():gsub('_', ' '):gsub('([a-z0-9A-Z])([A-Z])', '%1 %2')
end

p.module_key = function()
  return p.module_name():lower()
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

p.resource_name_snake = function()
  local list = h.get_file_parts()
  if #list > 4 then
    return h.lower_first(list[#list-1])
  end
  return 'resourceName'
end

p.template_for_block = function()
  local list = h.get_file_parts()
  table.remove(list, 1) -- remove app
  table.remove(list, 1) -- remove code
  table.remove(list, 1) -- remove pull (local, core, coommunity)

  list = h.map(list, h.snakecase)

  return table.concat(list, '/'):gsub('%/block%/', '%/') .. '.phtml';
end

return p
