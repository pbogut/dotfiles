local fn = vim.fn
local cmd = vim.cmd
local command = vim.api.nvim_create_user_command

command('DiffOn', 'windo diffthis', {})
command('DiffOff', 'windo diffoff', {})
command('BCloseAll', 'execute "%bd"', {})
command('BCloseOther', 'execute "%bd | e#"', {})
command('BCloseOtherForce', 'execute "%bd! | e#"', {})

command('Gan', 'execute "!git an %"', {})
command('Gap', function(_)
  local file = fn.expand('%:p')
  cmd('belowright vsplit')
  cmd.enew()
  fn.termopen('git ap ' .. file)
  cmd.startinsert()
end, {})

-- vim-dispatch compatibility
command('Start', function(opt)
  if not opt.bang then
    cmd('belowright 20split')
    cmd.enew()
    fn.termopen(opt.args)
    cmd.startinsert()
  else
    fn.jobstart(opt.args)
  end
end, { bang = true, nargs = '?' })

command('Dispatch', function(opt)
  if not opt.bang then
    cmd('belowright split')
    cmd.enew()
    fn.termopen(opt.args)
    cmd.normal('G')
    cmd.wincmd('J')
    cmd.resize('4')
    cmd([[autocmd BufEnter <buffer> resize 20]])
    cmd([[autocmd BufLeave <buffer> resize 4]])
    cmd.wincmd('k')
  else
    fn.jobstart(opt.args)
  end
end, { bang = true, nargs = '?' })

command('OpenFile', function(opt)
  local tabs = vim.api.nvim_list_tabpages()
  for _, tab in ipairs(tabs) do
    local wins = vim.api.nvim_tabpage_list_wins(tab)
    for _, win in ipairs(wins) do
      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.api.nvim_buf_get_name(buf)
      if name == opt.args then
        vim.api.nvim_set_current_win(win)
        return
      end
    end
  end
  local tabcount = #vim.api.nvim_list_tabpages()
  cmd(tabcount .. 'tabnew')
  cmd.edit(opt.args)
end, { nargs = 1 })
