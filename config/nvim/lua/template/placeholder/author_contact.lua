local config = require('config')

local p = {
  value = function()
    return config.get('templates.author_contact')
  end
}

return p
