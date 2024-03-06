local h = require('projector.helper')

local p = {}

p.base_name = function()
  return vim.fn.expand('%:t:r')
end

p.file_name = function()
  return vim.fn.expand('%:t')
end

p.current_date = function()
  return os.date('%d/%m/%Y')
end

p.snake_name = function()
  return h.snakecase(p.base_name())
end

p.lower_first_name = function()
  return h.lower_first(p.base_name())
end

p._ = function()
  return '[[coursor_position]]'
end

return p
