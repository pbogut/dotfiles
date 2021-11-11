local mkdnflow = require('mkdnflow')
local u = require('utils')

mkdnflow.setup({
  default_mappings = false,
  links_relative_to = 'current'
})

u.augroup('x_mkdnflow', {
  FileType = {'markdown', function()
    u.buf_map(0, 'n', '<bs>', function()
      if not mkdnflow.files.goBack() then
        vim.cmd('Dirvish %:p')
      end
    end)
    u.buf_map(0, 'n', '<Tab>', [[<cmd>:MkdnNextLink<CR>]])
    u.buf_map(0, 'n', '<S-Tab>', [[<cmd>:MkdnPrevLink<CR>]])
    u.buf_map(0, 'n', '<CR>', [[<cmd>:MkdnFollowPath<CR>]])
    u.buf_map(0, 'v', '<CR>', [[<cmd>:MkdnFollowPath<CR>]])
  end}
})
