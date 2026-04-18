---@type LazyPluginSpec[]
return {
  {
    enabled = true,
    'nvim-treesitter/nvim-treesitter-context',
    event = { 'BufWritePre', 'BufReadPre', 'FileType' },
    opts = {
      enable = true,
      max_lines = 10,
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
    branch = 'main',
    event = { 'BufWritePre', 'BufReadPre', 'FileType' },
    build = function()
      vim.cmd.TSUpdate()
      vim.cmd.TSInstallMy()
    end,
    init = function()
      local no_highlight = { 'markdown' }
      local no_indent = { 'blade' }

      -- enable highlighting for all buffers
      vim.api.nvim_create_autocmd('FileType', {
        pattern =  '*' ,
        callback = function()
          if not no_indent[vim.bo.filetype] then
            local ok, err = pcall(vim.treesitter.start)
            if ok and not no_highlight[vim.bo.filetype] then
              vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
          end
        end,
      })

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
            -- 'jsonc',
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
            -- 'org',
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
            -- 'robots',
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
    -- config = function(_, opts)
    --   for ft, lang in pairs({
    --     dotenv = 'bash',
    --   }) do
    --     vim.treesitter.language.register(lang, ft)
    --   end
    -- end,
    cond = true,
  },
}
