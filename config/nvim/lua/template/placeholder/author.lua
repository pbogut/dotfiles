local config = require('config')
local p = {
  value = function()
    return config.get('templates.author')
  end
}

return p
