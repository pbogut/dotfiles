local u = require('utils')

local function startup(use)
    -- NON PLUGINS --
    -- Things that are installed by packer but are not really plugins, just
    -- standalone dependencies that I like to have managed by vim as vim is
    -- one using them, they are installed as opt so hopefully should not
    -- affect vim load times
    use {'xdebug/vscode-php-debug',
      opt = true,
      run = {
        'npm install',
        'npm run build'
      }
    }
    use {'pbogut/emmet-ls',
      opt = true,
      run = {
        'npm install',
        'npm run build'
      },
    }
    use {'elixir-lsp/elixir-ls',
      opt = true,
      run = {
        'mix deps.get',
        'mix compile',
        'mix elixir_ls.release -o ./out'
      }
    }
    use {'sumneko/lua-language-server',
      opt = true,
      run = {
        'git submodule update --init --recursive',
        'cd 3rd/luamake && ./compile/install.sh',
        './3rd/luamake/luamake rebuild'
      },
    }
end

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
  }
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

return {
  startup = startup
}
