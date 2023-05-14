require('toggleterm').setup()

local command = vim.api.nvim_create_user_command
local Terminal = require('toggleterm.terminal').Terminal

local lg_cmd = 'lazygit'
  .. ' -ucf '
  .. (os.getenv('HOME') .. '/.config/lazygit/config.yml')
  .. ','
  .. (os.getenv('HOME') .. '/.config/lazygit/config-nvim.yml')

local lazygit = Terminal:new({ cmd = lg_cmd, direction = 'float' })

command('LazyGitToggle', function()
  lazygit:toggle()
end, {})
