---@type LazyPluginSpec[]
return {
  {
    enabled = true,
    'nvim-treesitter/nvim-treesitter-context',
    event = { 'BufWritePre', 'BufReadPre', 'FileType' },
    opts = {
      enable = true,
      max_lines = 5,
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
    enabled = true,
    'nvim-treesitter/nvim-treesitter',
    event = { 'BufWritePre', 'BufReadPre', 'FileType' },
    build = function()
      vim.cmd.TSUpdate()
      vim.cmd.TSInstallMy()
    end,
    opts = {
      -- ensure_installed = 'all', -- very slow (>20% of start time), dont use it
      highlight = {
        enable = true,
        disable = function(lang, bufnr)
          -- Disable for large files
          local lines_limit = 10000
          if lang == 'markdown' then
            -- Fuck this piece of shit pile of crap
            return true
          end
          return vim.api.nvim_buf_line_count(bufnr) > lines_limit
        end,
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
    init = function()
      local command = vim.api.nvim_create_user_command
      command('TSInstallMy', function()
        vim.cmd.TSInstall({
          args = {
            'php_only',
            'angular',
            'arduino',
            'asm',
            'awk',
            'bash',
            'blade',
            'c',
            'clojure',
            'cmake',
            'comment',
            'commonlisp',
            'cpp',
            'css',
            'csv',
            'cue',
            'dart',
            'devicetree',
            'diff',
            'disassembly',
            'dockerfile',
            'dot',
            'dtd',
            'editorconfig',
            'eex',
            'elixir',
            'elm',
            'erlang',
            'gdscript',
            'gdshader',
            'gitattributes',
            'gitcommit',
            'gitignore',
            'gleam',
            'go',
            'goctl',
            'gomod',
            'gosum',
            'gotmpl',
            'gowork',
            'gpg',
            'graphql',
            'haskell',
            'hcl',
            'heex',
            'html',
            'htmldjango',
            'http',
            'hyprlang',
            'ini',
            'java',
            'javascript',
            'jq',
            'jsdoc',
            'json',
            'json5',
            'jsonc',
            'just',
            'kconfig',
            'kdl',
            'kotlin',
            'llvm',
            'lua',
            'luadoc',
            'luap',
            'luau',
            'make',
            'markdown',
            'matlab',
            'menhir',
            'mermaid',
            'meson',
            'muttrc',
            'nginx',
            'nickel',
            'ninja',
            'nix',
            'ocaml',
            'odin',
            'org',
            'pascal',
            'passwd',
            'pem',
            'perl',
            'php',
            'phpdoc',
            'printf',
            'properties',
            'python',
            'query',
            'readline',
            'regex',
            'robots',
            'rst',
            'ruby',
            'rust',
            'scss',
            'sql',
            'squirrel',
            'starlark',
            'surface',
            'svelte',
            'templ',
            'terraform',
            'tmux',
            'todotxt',
            'toml',
            'tsv',
            'tsx',
            'twig',
            'typescript',
            'typespec',
            'typoscript',
            'udev',
            'ungrammar',
            'vim',
            'vimdoc',
            'vue',
            'xml',
            'yaml',
            'zig',
          },
          bang = true,
        })
      end, {})
    end,
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
    enabled = true,
    'nvim-treesitter/playground',
    cmd = {
      'TSInstallMy',
      'TSInstall',
      'TSUninstall',
      'TSCaptureUnderCursor',
      'TSPlaygroundToggle',
    },
  },
}
