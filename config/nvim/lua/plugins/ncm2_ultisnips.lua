local u = require('utils')
local cmd = vim.cmd
local buf_map = vim.api.nvim_buf_set_keymap

u.augroup('x_ncm2_ultisnip', {
  ['BufRead,BufNewFile'] = {
    '*', function()
      buf_map(0, 'i', '<cr>', 'ncm2_ultisnips#expand_or("<CR>", "n")', {
          noremap = true, silent = true, expr = true
        })
      cmd('setfiletype php.phtml')
    end
  }
})
