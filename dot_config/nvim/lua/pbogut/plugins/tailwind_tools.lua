--@type LazyPluginSpec
return {
  enabled = true,
  'luckasranarison/tailwind-tools.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim', -- optional
    'nvim-treesitter/nvim-treesitter',
  },
  build = ':UpdateRemotePlugins',
  ft = {
    'blade',
    'html',
    'php',
    'eelixir',
    'elixir',
    'handlebars',
    'templ',
    'template',
  },
  opts = {}, -- your configuration
  config = function(opts)
    require('tailwind-tools').setup(opts)
    vim.g.tailwind_tools_loaded = true
  end,
}
