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

-- vim-dispatch compatibility
u.command('Start', function(bang, qargs)
  if not bang then
    cmd('belowright 20split')
    cmd('enew')
    fn.termopen(qargs)
    cmd('startinsert')
  else
    fn.jobstart(qargs)
  end
end, {bang = true, nargs = '?', qargs = true})

u.command('LazyGit', function(qargs)
  cmd('tabnew')
  fn.termopen('lazygit', {
    on_exit = function()
      cmd('wincmd q')
    end
  })
  cmd('startinsert')

  local bufnr = fn.bufnr()

  u.augroup('x_lazygit' .. bufnr, {
    BufEnter = {
      {
        '<buffer=' .. bufnr .. '>',
        'startinsert'
      }
    }
  })
end, {nargs = '?', qargs = true})

u.command('Dispatch', function(bang, qargs)
  if not bang then
    cmd('belowright split')
    cmd('enew')
    fn.termopen(qargs)
    cmd('norm G')
    cmd('wincmd J')
    cmd('resize 4')
    cmd('setlocal laststatus=0')
    cmd([[autocmd BufEnter <buffer> resize 20]])
    cmd([[autocmd BufLeave <buffer> resize 4]])
    cmd('wincmd k')
  else
    fn.jobstart(qargs)
  end
end, {bang = true, nargs = '?', qargs = true})
