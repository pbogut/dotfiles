return {
  'folke/flash.nvim',
  event = 'VeryLazy',
  ---@type Flash.Config
  opts = {
    modes = {
      search = {
        enabled = false,
      },
    },
    label = {
      after = false,
      before = true,
    },
    keys = {},
  },
  keys = {
    {
      's',
      function()
        vim.o.ignorecase = true
        require('flash').jump()
        vim.o.ignorecase = false
      end,
      mode = { 'n', 'x', 'o' },
      desc = 'Flash',
    },
    {
      '<c-s>',
      function()
        require('flash').toggle()
      end,
      mode = { 'c' },
      desc = 'Toggle Flash Search',
    },
  },
}
