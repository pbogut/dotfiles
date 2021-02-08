local u = require('utils')
local fn = vim.fn
local cmd = vim.cmd

u.command('BCloseAll', 'execute "%bd"')
u.command('BCloseOther', 'execute "%bd | e#"')
u.command('BCloseOtherForce', 'execute "%bd! | e#"')

u.command('Gan', 'execute "!git an %"')
u.command('Gap', function()
  local file = fn.expand('%:p')
  cmd('belowright vsplit')
  cmd('enew')
  fn.termopen('git ap ' .. file)
  cmd('startinsert')
end)
