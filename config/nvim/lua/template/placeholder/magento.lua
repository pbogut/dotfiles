local h = require('projector.helper')
local fn = vim.fn
local p = {}

p.module_name = {
  value = function()
    local list = h.get_file_parts()
    if #list > 5 then
      return list[4] .. '_' .. list[5]
    end
    return 'Vendor_ModuleName'
  end
}
p.module_namespace = {
  value = function()
    local list = h.get_file_parts()
    if #list > 5 then
      return list[4] .. [[\]] .. list[5]
    end
    return [[Vendor\ModuleName]]
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

return p
