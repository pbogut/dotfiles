local u = require('utils')
local k = vim.keymap

k.set('n', '<esc>', ':call sneak#util#removehl() | set nohls<cr>', { silent = true })

-- disable s mappings
k.set('n', '<plug>SneakTrash_s', '<plug>Sneak_s', { remap = true })
k.set('n', '<plug>SneakTrash_S', '<plug>Sneak_S', { remap = true })
k.set('x', '<plug>SneakTrash_s', '<plug>Sneak_s', { remap = true })
k.set('x', '<plug>SneakTrash_S', '<plug>Sneak_S', { remap = true })
k.set('o', '<plug>SneakTrash_s', '<plug>Sneak_s', { remap = true })
k.set('o', '<plug>SneakTrash_S', '<plug>Sneak_S', { remap = true })

u.highlights({ Sneak = { link = 'Search' } })
