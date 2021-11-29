local u = require('utils')

-- NON PLUGINS --
-- Things that are used by neovim but are not plugins (language servers,
-- linters, etc)
-- This script uses external tools to install and update them
-- usage:
-- :exec('luafile ' . expand('%')) | UpdateExternalPackages
--
local packages = {
  yarn = {
    '@tailwindcss/language-server',
    'vim-language-server',
    'vls',
    'bash-language-server',
    'pyright',
    'dockerfile-language-server-nodejs',
    'typescript-language-server',
    '@tailwindcss/language-server',
    'intelephense',
    'vscode-langservers-extracted',
  },
  gem = {
    'solargraph',
  },
  go = {
    'golang.org/x/tools/gopls@latest'
  },
  cargo = {
    'stylua',
    'prosemd'
  },
  gitpac = {
    'sumneko/lua-language-server',
    'pbogut/emmet-ls',
    'elixir-lsp/elixir-ls',
    'xdebug/vscode-php-debug',
  },
}

local managers = {
  yarn = {
    install = 'yarn global add {}',
    update = 'yarn global upgrade {}'
  },
  gem = {
    install = 'gem install {}',
    update = 'gem update {}'
  },
  go = {
    install = 'go install {}',
    update = 'go install {}'
  },
  cargo = {
    install = 'cargo install {}',
    update = 'cargo install {}'
  },
  aur = {
    install = 'paru -S {}',
    update = 'paru -Sy {}'
  },
  gitpac = {
    install = 'gitpac {}',
    update = 'gitpac {}'
  }
}

u.command('UpdateExternalPackages', function()
  local cmds = {}
  for manager, package_list in pairs(packages) do
    for _, package in pairs(package_list) do
      cmds[#cmds+1] = managers[manager].update:gsub('%{%}', package)
    end
  end
  u.process_shell_commands(cmds, {
    done = 'done',
    prefix = '[Update]',
  })
end)

u.command('InstallExternalPackages', function()
  local cmds = {}
  for manager, package_list in pairs(packages) do
    for _, package in pairs(package_list) do
      cmds[#cmds+1] = managers[manager].install:gsub('%{%}', package)
    end
  end
  u.process_shell_commands(cmds, {
    done = 'done',
    prefix = '[Install]',
  })
end)
