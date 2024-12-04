---@type LazyPluginSpec[]
return {
  {
    enabled = true,
    'echasnovski/mini.nvim',
    version = false,
    config = function()
      require('mini.surround').setup({
        search_method = 'cover_or_next',
      })
    end,
  },
}
