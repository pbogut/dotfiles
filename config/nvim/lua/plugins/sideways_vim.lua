local k = vim.keymap

k.set('n', 'ga<', ':SidewaysLeft<cr>')
k.set('n', 'ga>', ':SidewaysRight<cr>')
k.set('o', 'aa', '<plug>SidewaysArgumentTextobjA', { remap = true })
k.set('x', 'aa', '<plug>SidewaysArgumentTextobjA', { remap = true })
k.set('o', 'ia', '<plug>SidewaysArgumentTextobjI', { remap = true })
k.set('x', 'ia', '<plug>SidewaysArgumentTextobjI', { remap = true })
