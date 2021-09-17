local u = require('utils')
local fn = vim.fn

local M = {}

function M.camelcase(text)
  text = text:gsub('_(%w)', function(match)
    return match:upper()
  end)
  return text
end

function M.capitalize(text)
  text = text:gsub('([^%l%u])(%l)', function(sign, letter)
    return sign .. letter:upper()
  end)
  text = text:gsub('^(%l)', function(letter)
    return letter:upper()
  end)
  return text
end

function M.snakecase(text)
  return text:gsub('([a-z])([A-Z])', '%1_%2'):lower()
end

function M.upper_first(text)
  text = text:gsub('^(%l)', function(letter)
    return letter:upper()
  end)
  return text
end

function M.map(list, fun)
  local result = {}
  for k, v in pairs(list) do
    result[k] = fun(v)
  end
  return result
end

function M.get_file_parts()
  local cwd = fn.getcwd()
  local filename = fn.expand('%:p')
  local relative = filename:gsub('^' .. cwd .. '/', '')
  local noext = relative:gsub('(.*)%..-$', '%1')
  return u.split_string(noext, '/')
end

return M
