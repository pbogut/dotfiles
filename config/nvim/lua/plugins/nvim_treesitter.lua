local parser_config = require('nvim-treesitter.parsers').get_parser_configs()

parser_config.blade = {
    install_info = {
        url = "https://github.com/EmranMR/tree-sitter-blade",
        files = {"src/parser.c"},
        branch = "main",
    },
    filetype = "blade"
}

for ft, lang in pairs({
  dotenv = 'bash',
}) do
  vim.treesitter.language.register(lang, ft)
end

require('nvim-treesitter.configs').setup({
  -- ensure_installed = 'all', -- very slow (>20% of start time), dont use it
  highlight = {
    enable = true,
    disable = { 'markdown' },
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
