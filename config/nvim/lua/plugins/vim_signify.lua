local u = require('utils')
local k = vim.keymap
local g = vim.g

g.signify_priority = 1
g.signify_vcs_list = { 'git' }
g.signify_sign_add = g.icon.added
g.signify_sign_delete = g.icon.deleted
g.signify_sign_delete_first_line = '‾'
g.signify_sign_change = g.icon.changed
g.signify_sign_changedelete = g.icon.changed
g.signify_sign_show_count = 0

k.set('n', '<space>hh', ':SignifyToggleHighlight<cr>')
k.set('n', '<space>hr', ':SignifyRefresh<cr>')
k.set('n', '<space>hd', ':SignifyHunkDiff<cr>')
k.set('n', '<space>hu', ':SignifyHunkUndo<cr>')
k.set('n', '<space>gd', ':SignifyDiff<cr>')

k.set('n', ']h', '<plug>(signify-next-hunk)', { remap = true })
k.set('n', '[h', '<plug>(signify-prev-hunk)', { remap = true })

k.set('o', 'ih', '<plug>(signify-motion-inner-pending)', { remap = true })
k.set('x', 'ih', '<plug>(signify-motion-inner-visual)', { remap = true })
k.set('o', 'ah', '<plug>(signify-motion-outer-pending)', { remap = true })
k.set('x', 'ah', '<plug>(signify-motion-outer-visual)', { remap = true })
