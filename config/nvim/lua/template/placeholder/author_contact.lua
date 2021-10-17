local config = require('config')

local p = function()
  return config.get('templates.author_contact')
end

return p
