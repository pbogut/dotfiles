---@type LazyPluginSpec
return {
  enabled = true,
  'olimorris/codecompanion.nvim',
  config = true,
  opts = {
    strategies = {
      chat = {
        adapter = 'copilot',
      },
    },
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
}
