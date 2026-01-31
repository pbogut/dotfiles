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

command('NonAscii', function()
  vim.api.nvim_feedkeys('/[^\\x00-\\x7F]\n', 'n', true)
  vim.cmd([[
    syntax match NonAscii "[^\x00-\x7F]" containedin=ALL
  ]])
end, {})

command('Print', function(opts)
  local outfile = opts.args ~= '' and opts.args or vim.fn.tempname() .. '.html'
  local html = require('tohtml').tohtml(0, { range = { opts.line1, opts.line2 } })

  if not opts.bang then
    html[#html + 1] = '<style>.NonText {display: none}</style>'
  end

  html[#html + 1] = '<style>* { font-size: 14px; color: black; } pre { white-space: wrap }</style>'
  html[#html + 1] = '<script>print();setTimeout(function() { close() }, 1000)</script>'

  -- insert new lines in pre blocks so we can use wrap
  local i = 1
  local insert = false
  while i <= #html do
    if html[i]:sub(html[i]:len() - 6) == '</pre>' then
      insert = false
    end
    if insert then
      html[i] = html[i] .. '<br>'
    end
    if html[i]:sub(1, 4) == '<pre' then
      insert = true
    end
    i = i + 1
  end

  vim.fn.writefile(html, outfile)
  fn.jobstart({ 'chromium', '--profile-directory=Default', '--app=file://' .. outfile })
end, { bang = true, range = '%', nargs = '?' })

command('ProfileStart', function(opt)
  vim.cmd([[
    profile start profile.log
    profile func *
    profile file *
  ]])
end, { nargs = '*' })
