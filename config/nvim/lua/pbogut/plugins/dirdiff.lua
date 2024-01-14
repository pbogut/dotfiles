---@type LazyPluginSpec
return {
  'will133/vim-dirdiff',
  cmd = 'DirDiff',
  config = function()
    vim.g.DirDiffAddArgs = '-w'
  end,
}
