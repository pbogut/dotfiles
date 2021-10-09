local h = require('projector.helper')

local p = {}
p.base_name = {
  value = function()
    return vim.fn.expand('%:t:r')
  end
}
p.file_name = {
  value = function()
    return vim.fn.expand('%:t')
  end
}
p.current_date = {
  value = function()
    return os.date('%d/%m/%Y')
  end
}
p.snake_name = {
  value = function()
    return h.snakecase(p.base_name.value())
  end
}
p.lower_first_name = {
  value = function()
    return h.lower_first(p.base_name.value())
  end
}
p._ = {
  value = function()
    return '[[coursor_position]]'
  end
}

return p
