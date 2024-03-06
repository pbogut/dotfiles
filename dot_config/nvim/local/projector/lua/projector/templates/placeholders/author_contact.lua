local config = require('pbogut.config')

local p = function()
  return config.get('templates.author_contact')
end

return p
