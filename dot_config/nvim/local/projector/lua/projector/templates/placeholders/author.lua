local config = require('pbogut.config')

local p = function()
  return config.get('templates.author')
end

return p
