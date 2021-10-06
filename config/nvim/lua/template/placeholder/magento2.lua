local h = require('projector.helper')
local fn = vim.fn
local p = {}

p.module_name = {
  value = function()
    local list = h.get_file_parts()
    if #list > 4 then
      return list[3] .. '_' .. list[4]
    end
    return 'Vendor_ModuleName'
  end
}
p.module_namespace = {
  value = function()
    local list = h.get_file_parts()
    if #list > 4 then
      return list[3] .. [[\]] .. list[4]
    end
    return [[Vendor\ModuleName]]
  end
}
p.resource_name = {
  value = function()
    local list = h.get_file_parts()
    if #list > 4 then
      return list[#list-1]
    end
    return 'ResourceName'
  end
}
p.resource_key = {
  value = function()
    local list = h.get_file_parts()
    if #list > 4 then
      return list[#list-1]:lower()
    end
    return 'resourcename'
  end
}
p.module_name_str = {
  value = function()
    return p.module_name.value():gsub('_', ' '):gsub('([a-z0-9A-Z])([A-Z])', '%1 %2')
  end
}
p.module_key = {
  value = function()
    return p.module_name.value():lower()
  end
}
p.namespace = {
  value = function()
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
}
p.block_namespace = {
  value = function()
    return p.namespace.value() .. [[\Block]]
  end
}
p.block_class = {
  value = function()
    local path = fn.expand('%:.'):gsub('^.*/view/frontend/templates/(.*).phtml$', '%1')
    return h.capitalize(h.camelcase(path))
  end
}

return p
