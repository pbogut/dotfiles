local h = require('projector.helper')
local u = require('utils')
local fn = vim.fn

local function get_file_parts()
  local cwd = fn.getcwd()
  local filename = fn.expand('%:p')
  local relative = filename:gsub('^' .. cwd .. '/', '')
  local noext = relative:gsub('(.*)%..-$', '%1')
  return u.split_string(noext, '/')
end

local p = {}

p.module_name = {
  value = function()
    local list = get_file_parts()
    if #list > 4 then
      return list[3] .. '_' .. list[4]
    end
    return 'Vendor_ModuleName'
  end
}
p.module_key = {
  value = function()
    return p.module_name.value:lower()
  end
}
p.namespace = {
  value = function()
    local list = get_file_parts()
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
