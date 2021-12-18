local u = require('utils')
local trouble = require('trouble')

u.map('n', '<space>ed', ':TroubleToggle lsp_document_diagnostics<CR>')
u.map('n', '<space>ew', ':TroubleToggle lsp_workspace_diagnostics<CR>')
u.map('n', '<space>lq', ':TroubleToggle quickfix<CR>')
u.map('n', '<space>ll', ':TroubleToggle loclist<CR>')

u.map('n', ']q', function()
  trouble.next({ skip_groups = true, jump = true })
end)

u.map('n', '[q', function()
  trouble.previous({ skip_groups = true, jump = true })
end)
