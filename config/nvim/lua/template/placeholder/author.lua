local config = require('config')

local p = function()
  return config.get('templates.author')
end

return p
