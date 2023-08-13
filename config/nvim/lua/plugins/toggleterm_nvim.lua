require('toggleterm').setup()

local command = vim.api.nvim_create_user_command
local Terminal = require('toggleterm.terminal').Terminal

local lg_cmd = 'lazygit'
  .. ' -ucf '
  .. (os.getenv('HOME') .. '/.config/lazygit/config.yml')
  .. ','
  .. (os.getenv('HOME') .. '/.config/lazygit/config-nvim.yml')

local lazygit = Terminal:new({
  cmd = lg_cmd,
  direction = 'float',
  float_opts = {
    width = function(_)
      return vim.o.columns
    end,
    height = function(_)
      local statusheight = 1
      return vim.o.lines - vim.o.cmdheight - statusheight
    end,
    border = 'none',
  },
})

command('LazyGitToggle', function()
  lazygit:toggle()
end, {})
