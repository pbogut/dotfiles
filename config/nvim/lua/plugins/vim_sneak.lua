local u = require('utils')

-- 1-character enhanced 'f'
u.map('n', 'f', '<plug>Sneak_f', {noremap = false, silent = false})
u.map('n', 'F', '<plug>Sneak_F', {noremap = false, silent = false})
-- visual-mode
u.map('x', 'f', '<plug>Sneak_f', {noremap = false, silent = false})
u.map('x', 'F', '<plug>Sneak_F', {noremap = false, silent = false})
-- operator-pending-mode
u.map('o', 'f', '<plug>Sneak_f', {noremap = false, silent = false})
u.map('o', 'F', '<plug>Sneak_F', {noremap = false, silent = false})

-- 1-character enhanced 't'
u.map('n', 't', '<plug>Sneak_t', {noremap = false, silent = false})
u.map('n', 'T', '<plug>Sneak_T', {noremap = false, silent = false})
-- visual-mode
u.map('x', 't', '<plug>Sneak_t', {noremap = false, silent = false})
u.map('x', 'T', '<plug>Sneak_T', {noremap = false, silent = false})
-- operator-pending-mode
u.map('o', 't', '<plug>Sneak_t', {noremap = false, silent = false})
u.map('o', 'T', '<plug>Sneak_T', {noremap = false, silent = false})

u.map('n', '<esc>', ':call sneak#util#removehl() | set nohls<cr>')

u.augroup('x_sneak', {
  VimEnter = { '*', function()
    u.highlights({
      Sneak = {link = 'Search'},
    })
  end}
})
