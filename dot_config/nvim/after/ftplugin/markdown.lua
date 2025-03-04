vim.cmd('setlocal spell spelllang=en_gb')

vim.keymap.set('n', ']o', [[<cmd>silent! s/\[ \]/[x]/<cr>]])
vim.keymap.set('n', '[o', [[<cmd>silent! s/\[.\]/[ ]/<cr>]])
