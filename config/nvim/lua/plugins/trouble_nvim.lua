local k = vim.keymap
local trouble = require('trouble')

k.set('n', '<space>ed', '<cmd>TroubleToggle document_diagnostics<cr>')
k.set('n', '<space>ew', '<cmd>TroubleToggle workspace_diagnostics<cr>')
k.set('n', '<space>lq', '<cmd>TroubleToggle quickfix<cr>')
k.set('n', '<space>ll', '<cmd>TroubleToggle loclist<cr>')

k.set('n', ']q', function()
  trouble.next({ skip_groups = true, jump = true })
end)

k.set('n', '[q', function()
  trouble.previous({ skip_groups = true, jump = true })
end)
