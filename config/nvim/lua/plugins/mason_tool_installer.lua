require('mason-tool-installer').setup({

  -- a list of all tools you want to ensure are installed upon
  -- start; they should be the names Mason uses for each tool
  ensure_installed = {
    'bash-language-server',
    'clang-format',
    'codelldb',
    'css-lsp',
    'deno',
    'dockerfile-language-server',
    'editorconfig-checker',
    'elixir-ls',
    'eslint-lsp',
    'golangci-lint',
    'gopls',
    'html-lsp',
    'intelephense',
    'isort',
    'jedi-language-server',
    'json-lsp',
    'jsonlint',
    'lemminx',
    'lua-language-server',
    'openscad-lsp',
    'php-cs-fixer',
    'php-debug-adapter',
    'phpcbf',
    'phpcs',
    'phpmd',
    'prosemd-lsp',
    'psalm',
    'pyright',
    'python-lsp-server',
    'selene',
    'shellcheck',
    'shfmt',
    'solargraph',
    'stylua',
    'tailwindcss-language-server',
    'typescript-language-server',
    'vim-language-server',
    'vls',
  },

  -- if set to true this will check each tool for updates. If updates
  -- are available the tool will be updated. This setting does not
  -- affect :MasonToolsUpdate or :MasonToolsInstall.
  -- Default: false
  auto_update = false,

  -- automatically install / update on startup. If set to false nothing
  -- will happen on startup. You can use :MasonToolsInstall or
  -- :MasonToolsUpdate to install tools and check for updates.
  -- Default: true
  run_on_start = true,

  -- set a delay (in ms) before the installation starts. This is only
  -- effective if run_on_start is set to true.
  -- e.g.: 5000 = 5 second delay, 10000 = 10 second delay, etc...
  -- Default: 0
  start_delay = 3000, -- 3 second delay
})
