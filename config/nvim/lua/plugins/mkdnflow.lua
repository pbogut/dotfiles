local mkdnflow = require('mkdnflow')
local u = require('utils')
local k = vim.keymap

mkdnflow.setup({
  default_mappings = false,
  links_relative_to = 'current'
})

u.augroup('x_mkdnflow', {
  FileType = {'markdown', function()
    k.set('n', '<Tab>', [[<cmd>:MkdnNextLink<CR>]], { buffer = true })
    k.set('n', '<S-Tab>', [[<cmd>:MkdnPrevLink<CR>]], { buffer = true })
    k.set('n', '<CR>', [[<cmd>:MkdnFollowPath<CR>]], { buffer = true })
    k.set('v', '<CR>', [[<cmd>:MkdnFollowPath<CR>]], { buffer = true })
  end}
})
