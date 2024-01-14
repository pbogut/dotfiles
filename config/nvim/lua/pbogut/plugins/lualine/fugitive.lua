local M = {}

local filename = require('pbogut.plugins.lualine.filename')

function M.filename_green()
  local file = vim.fn.expand('%')
  if file:match('^fugitive://') then
    local hash = file:gsub('fugitive://.*//(.-)/.*', '%1')
    return '%#sl_diffmode# ' .. hash:sub(1, 8) .. ':' .. vim.fn.expand('%:t')
  end
  return filename()
end

function M.filename()
  local file = vim.fn.expand('%')
  if file:match('^fugitive://') then
    local hash = file:gsub('fugitive://.*//(.-)/.*', '%1')
    return ' ' .. hash:sub(1, 8) .. ':' .. vim.fn.expand('%:t')
  end
  return filename()
end

return M
