local k = vim.keymap
local harpoon = require('harpoon')

harpoon.setup()

k.set('n', '<plug>(harpoon-toggle-menu)', function()
  harpoon.ui:toggle_quick_menu(harpoon:list(), {
    border = 'rounded',
    title_pos = 'center',
  })
end) -- ALT_GR-G
k.set('n', '<plug>(harpoon-add-file)', function()
  harpoon:list():append()
end) -- ALT_GR+V
k.set('n', '<plug>(harpoon-nav-1)', function()
  harpoon:list():select(1)
end) -- ALT_GR-F
k.set('n', '<plug>(harpoon-nav-2)', function()
  harpoon:list():select(2)
end) -- ALT_GR-D
k.set('n', '<plug>(harpoon-nav-3)', function()
  harpoon:list():select(3)
end) -- ALT_GR-S
k.set('n', '<plug>(harpoon-nav-4)', function()
  harpoon:list():select(4)
end) -- ALT_GR-A
