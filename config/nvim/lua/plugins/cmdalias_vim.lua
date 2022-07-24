local u = require('utils')
local a = vim.cmd.Alias

u.augroup('x_alias', {
  VimEnter = {
    '*',
    function()
      a('ag', 'Ag')
      a('agg', 'Agg')
      a('rg', 'Rg')
      a('rgg', 'Rgg')
      a('art', 'Artisan')
      a('artisan', 'Artisan')
      a('git', 'Git')
      a('gan', 'Gan')
      a('gst', 'Gst')
      a('gap', 'Gap')
      a('ge', 'Gedit')
      a('gedit', 'Gedit')
      a('mix', 'Mix')
      a('repl', 'Repl')
      a('skel', 'Skel')
      a('db', 'DB')
      a('lg', 'LazyGit')
    end,
  },
})
