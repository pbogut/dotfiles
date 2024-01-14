---@type LazyPluginSpec
return {
  'vim-scripts/cmdalias.vim',
  event = 'CmdlineEnter',
  config = function()
    local a = vim.cmd.Alias
    a('action', 'Action')
    a('h', 'Telescope help_tags')
    a('a', 'Action')
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
    a('todo', 'Todo')
    a('db', 'DB')
    a('lg', 'LazyGit')
  end,
}
