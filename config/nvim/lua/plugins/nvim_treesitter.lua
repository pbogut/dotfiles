require('nvim-treesitter.configs').setup({
  ensure_installed = 'all', -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  highlight = {
    enable = true, -- its buggy, I'm on fence with it
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
