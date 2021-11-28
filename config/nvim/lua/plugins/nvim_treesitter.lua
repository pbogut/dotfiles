require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  highlight = {
    enable = true, -- its buggy, I'm on fence with it
    additional_vim_regex_highlighting = {'php'}
  },
  indent = {
    enable = true, -- like it better in php/html so far, but its shit in pure php
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
}

-- vim.cmd([[set foldmethod=expr]])
-- vim.cmd([[set foldexpr=nvim_treesitter#foldexpr()]])
