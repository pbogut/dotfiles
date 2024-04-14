---@type LazyPluginSpec[]
return {
  {
    'stevearc/oil.nvim',
    keys = {
      { '<bs>', '<cmd>Oil<cr>', desc = 'Oil' },
    },
    opts = {
      win_options = {
        signcolumn = 'yes:2',
      },
      view_options = {
        show_hidden = true,
      },
    },
    config = true,
  },
  {
    'refractalize/oil-git-status.nvim',
    dependencies = { 'stevearc/oil.nvim' },
    config = true,
  },
}
