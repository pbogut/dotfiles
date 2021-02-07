local u = require('utils')
local g = vim.g
local b = vim.b
local cmd = vim.cmd

g.strip_whitespace_on_save = 0

u.augroup('x_whitespace', {
  BufWritePost = {
    {
      '*',
      function()
        if not b.whitespace_trim_disabled then
          cmd('StripWhitespace')
        end
      end
    }
  },
  FileType = {
    {
      'markdown',
      function()
        b.whitespace_trim_disabled = true
      end
    },
  },
  BufEnter = {
    {
      '.i3blocks.conf',
      function()
        b.whitespace_trim_disabled = true
      end
    },
  }
})
