require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  highlight = {
    enable = true, -- its buggy, I'm on fence with it
  },
  indent = {
    enable = true, -- like it better in php/html so far, but its shit in pure php
  }
}

-- vim.cmd([[set foldmethod=expr]])
-- vim.cmd([[set foldexpr=nvim_treesitter#foldexpr()]])
