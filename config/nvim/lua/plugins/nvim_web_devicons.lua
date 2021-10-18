local function config()
  local devicons = require('nvim-web-devicons')
  local icons = devicons.get_icons()
  for _, data in pairs(icons) do
    data['color'] = '#ffffff'
  end
  devicons.set_default_icon("", '#ffffff')
  devicons.set_icon(icons)
end

return {
  config = config
}
