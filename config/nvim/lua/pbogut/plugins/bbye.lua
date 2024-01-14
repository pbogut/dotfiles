---@type LazyPluginSpec
return {
  'moll/vim-bbye',
  keys = {
    { '<c-w>d', '<cmd>silent! Bdelete<cr>' },
    { '<c-w>D', '<cmd>silent! Bdelete!<cr>' },
  },
  cmd = { 'Bdelete', 'Bwipeout' },
}
