require('nvim-treesitter.configs').setup({
  -- ensure_installed = 'all', -- very slow (>20% of start time), dont use it
  highlight = {
    enable = true,
  },
  matchup = {
    enable = true,
  },
  indent = {
    enable = true,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = '<cr>',
      scope_incremental = '<c-cr>',
      node_incremental = '<cr>',
      node_decremental = '<bs>',
    },
  },
  context_commentstring = {
    enable_autocmd = false, -- we will use nvim-ts-context-commentstring
    enable = true,
  },
})

vim.cmd([[set foldmethod=expr]])
vim.cmd([[set foldexpr=nvim_treesitter#foldexpr()]])
