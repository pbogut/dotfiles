local u = require('utils')
local g = vim.g

g.signify_vcs_list = { 'git' }
g.signify_sign_add = '+'
g.signify_sign_delete = '_'
g.signify_sign_delete_first_line = '‾'
g.signify_sign_change = '~'
g.signify_sign_changedelete = '~'
g.signify_sign_show_count = 0

u.map('n', '<space>hh', ':SignifyToggleHighlight<cr>')
u.map('n', '<space>hr', ':SignifyRefresh<cr>')
u.map('n', '<space>hd', ':SignifyHunkDiff<cr>')
u.map('n', '<space>hu', ':SignifyHunkUndo<cr>')
u.map('n', '<space>gd', ':SignifyDiff<cr>')

u.map('n', ']h', '<plug>(signify-next-hunk)', {noremap = false})
u.map('n', '[h', '<plug>(signify-prev-hunk)', {noremap = false})

u.map('o', 'ih', '<plug>(signify-motion-inner-pending)', {noremap = false})
u.map('x', 'ih', '<plug>(signify-motion-inner-visual)', {noremap = false})
u.map('o', 'ah', '<plug>(signify-motion-outer-pending)', {noremap = false})
u.map('x', 'ah', '<plug>(signify-motion-outer-visual)', {noremap = false})
