local k = vim.keymap
local trouble = require('trouble')

k.set('n', '<space>ed', '<cmd>TroubleToggle document_diagnostics<cr>')
k.set('n', '<space>ew', '<cmd>TroubleToggle workspace_diagnostics<cr>')
k.set('n', '<space>lq', '<cmd>TroubleToggle quickfix<cr>')
k.set('n', '<space>ll', '<cmd>TroubleToggle loclist<cr>')

k.set('n', ']q', function()
  if trouble.is_open() then
    trouble.next({ skip_groups = true, jump = true })
  else
    pcall(vim.cmd.cnext)
  end
end)

k.set('n', '[q', function()
  if trouble.is_open() then
    trouble.previous({ skip_groups = true, jump = true })
  else
    pcall(vim.cmd.cprevious)
  end
end)
