local a = vim.cmd.Alias

vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('x_alias', { clear = true }),
  callback = function()
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
})
