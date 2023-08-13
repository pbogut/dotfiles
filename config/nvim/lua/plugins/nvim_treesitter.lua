local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
parser_config.blade = {
  install_info = {
    url = plugin_path('tree-sitter-blade'), -- local path or git repo
    -- files = { 'src/parser.c', 'src/scanner.cc' }, -- note that some parsers also require src/scanner.c or src/scanner.cc
    files = { 'src/parser.c' }, -- note that some parsers also require src/scanner.c or src/scanner.cc
    -- optional entries:
    generate_requires_npm = false, -- if stand-alone parser without npm dependencies
    requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
  },
  -- filetype = 'php', -- if filetype does not match the parser name
}

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
