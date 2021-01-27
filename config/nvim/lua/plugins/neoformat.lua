local g = vim.g

g.neoformat_only_msg_on_error = 1
g.neoformat_vimwiki_prettier = {
      exe = 'prettier',
      args = {'--stdin', '--stdin-filepath', '%:p'},
      stdin = 1,
}
g.neoformat_disable_on_save = 1
g.neoformat_enabled_vimwiki = {'prettier'}
