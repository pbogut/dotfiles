local u = require('utils')
local fn = vim.fn

local function get_file_parts()
  local cwd = fn.getcwd()
  local filename = fn.expand('%:p')
  local relative = filename:gsub('^' .. cwd .. '/', '')
  local noext = relative:gsub('(.*)%..-$', '%1')
  return u.split_string(noext, '/')
end

local p = {
  namespace = {
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
        if result == '' and el == 'app' then
          result = 'App'
        end
      end

      return result
    end
  },
  class = {
    value = function()
      return fn.expand('%:t:r')
    end
  },
  class1 = {
    value = function()
      local list = get_file_parts()
      local result = ''

      for _, el in ipairs(list) do
        local sep = ''
        if result ~= '' then
          sep = '_'
        end
        if not el:match('^%l') then
          result = result .. sep .. el
        end
      end

      return result
    end
  },
  _ = {
    value = function()
      return '[[coursor_position]]'
    end
  }
}

return p
