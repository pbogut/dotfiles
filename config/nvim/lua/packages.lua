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

local install_cmds = {
  'yarn global add @tailwindcss/language-server',
  'yarn global add vim-language-server',
  'yarn global add vls',
  'yarn global add bash-language-server',
  'yarn global add pyright',
  'yarn global add dockerfile-language-server-nodejs',
  'yarn global add typescript-language-server',
  'yarn global add @tailwindcss/language-server',
  'yarn global add intelephense',
  'yarn global add vscode-langservers-extracted',
  'go install golang.org/x/tools/gopls@latest',
  -- 'paru -S deno',
}

local update_cmds = {
  'yarn global upgrade',
  'go install golang.org/x/tools/gopls@latest',
  -- 'paru -Syu deno',
}

u.command('UpdateExternalPackages', function()
  u.process_shell_commands(update_cmds, {
    done = 'done',
    prefix = '[Update]',
  })
end)

u.command('InstallExternalPackages', function()
  u.process_shell_commands(install_cmds, {
    done = 'done',
    prefix = '[Install]',
  })
end)

return {
  startup = startup
}
