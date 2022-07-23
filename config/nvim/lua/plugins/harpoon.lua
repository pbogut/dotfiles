local k = vim.keymap
local ui = require("harpoon.ui")
local mark = require("harpoon.mark")

require("harpoon").setup({
    menu = {
        width = math.floor(vim.api.nvim_win_get_width(0) * 0.8)
    }
})

k.set('n', 'ŋ', ui.toggle_quick_menu)          -- ALT_GR-G
k.set('n', '„', mark.add_file)                 -- ALT_GR+V
k.set('n', 'æ', function() ui.nav_file(1) end) -- ALT_GR-F
k.set('n', 'ð', function() ui.nav_file(2) end) -- ALT_GR-D
k.set('n', 'ś', function() ui.nav_file(3) end) -- ALT_GR-S
k.set('n', 'ą', function() ui.nav_file(4) end) -- ALT_GR-A

-- navigate to harpones by count motion
-- ie. 2h will call nav_file(2)
k.set('n', 'h', function()
  if vim.v.count == 0 then
    local pos = vim.api.nvim_win_get_cursor(0)
    pos[2] = math.max(pos[2] - 1, 0)
    vim.api.nvim_win_set_cursor(0, pos)
  else
    ui.nav_file(vim.v.count)
  end
end)
