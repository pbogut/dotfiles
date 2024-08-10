---@type LazyPluginSpec
return {
  enabled = true,
  'will133/vim-dirdiff',
  cmd = 'DirDiff',
  config = function()
    vim.g.DirDiffAddArgs = '-w'
  end,
}
