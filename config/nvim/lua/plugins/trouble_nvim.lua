local k = vim.keymap
local trouble = require('trouble')

k.set('n', '<space>ed', ':TroubleToggle lsp_document_diagnostics<CR>')
k.set('n', '<space>ew', ':TroubleToggle lsp_workspace_diagnostics<CR>')
k.set('n', '<space>lq', ':TroubleToggle quickfix<CR>')
k.set('n', '<space>ll', ':TroubleToggle loclist<CR>')

k.set('n', ']q', function()
  trouble.next({ skip_groups = true, jump = true })
end)

k.set('n', '[q', function()
  trouble.previous({ skip_groups = true, jump = true })
end)
