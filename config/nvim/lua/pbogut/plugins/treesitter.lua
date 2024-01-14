---@type LazyPluginSpec[]
return {
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = { 'BufWritePre', 'BufReadPre', 'FileType' },
    opts = {
      enable = true,
      max_lines = 3,
      trim_scope = 'outer',
      patterns = {
        default = {
          'class',
          'table',
          'function',
          'method',
          'for', -- These won't appear in the context
          'while',
          'if',
          'switch',
          'case',
        },
      },
      exact_patterns = {},
      zindex = 20, -- The Z-index of the context window
      mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
      separator = nil, -- Separator between context and content. Should be a single character string, like '-'.
    },
    cond = true,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    event = { 'BufWritePre', 'BufReadPre', 'FileType' },
    build = function()
      vim.cmd.TSUpdate()
      vim.cmd.TSInstall('all')
    end,
    opts = {
      -- ensure_installed = 'all', -- very slow (>20% of start time), dont use it
      highlight = {
        enable = true,
        -- disable = { 'markdown' },
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
    },
    config = function(_, opts)
      local parser_config = require('nvim-treesitter.parsers').get_parser_configs()

      ---@diagnostic disable-next-line: inject-field
      parser_config.blade = {
        install_info = {
          url = 'https://github.com/EmranMR/tree-sitter-blade',
          files = { 'src/parser.c' },
          branch = 'main',
        },
        filetype = 'blade',
      }

      for ft, lang in pairs({
        dotenv = 'bash',
      }) do
        vim.treesitter.language.register(lang, ft)
      end

      ---@diagnostic disable-next-line: missing-fields
      require('nvim-treesitter.configs').setup(opts)
    end,
    cond = true,
  },
  {
    'nvim-treesitter/playground',
    cmd = { 'TSCaptureUnderCursor', 'TSPlaygroundToggle' },
  },
}
