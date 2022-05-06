local u = require('utils')
local k = vim.keymap

-- 1-character enhanced 'f'
k.set('n', 'f', '<plug>Sneak_f', { remap = true, silent = false})
k.set('n', 'F', '<plug>Sneak_F', { remap = true, silent = false})
-- visual-mode
k.set('x', 'f', '<plug>Sneak_f', { remap = true, silent = false})
k.set('x', 'F', '<plug>Sneak_F', { remap = true, silent = false})
-- operator-pending-mode
k.set('o', 'f', '<plug>Sneak_f', { remap = true, silent = false})
k.set('o', 'F', '<plug>Sneak_F', { remap = true, silent = false})

-- 1-character enhanced 't'
k.set('n', 't', '<plug>Sneak_t', { remap = true, silent = false})
k.set('n', 'T', '<plug>Sneak_T', { remap = true, silent = false})
-- visual-mode
k.set('x', 't', '<plug>Sneak_t', { remap = true, silent = false})
k.set('x', 'T', '<plug>Sneak_T', { remap = true, silent = false})
-- operator-pending-mode
k.set('o', 't', '<plug>Sneak_t', { remap = true, silent = false})
k.set('o', 'T', '<plug>Sneak_T', { remap = true, silent = false})

k.set('n', '<esc>', ':call sneak#util#removehl() | set nohls<cr>')

u.augroup('x_sneak', {
  VimEnter = { '*', function()
    u.highlights({
      Sneak = {link = 'Search'},
    })
  end}
})
