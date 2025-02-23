---@type LazyPluginSpec
return {
  enabled = true,
  -- lazy = false, -- Recommended
  'oxy2dev/markview.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  ft = "markdown", -- If you decide to lazy-load anyway
}
