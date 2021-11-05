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
  local to_update = u.clone_table(update_cmds)

  vim.cmd('echo "Updating packages..."')
  local function update_next()
    for idx, command in pairs(to_update) do
      to_update[idx] = nil
      vim.fn.jobstart(command, {
        on_exit = function(_, exit_code)
          if exit_code == 0 then
            vim.cmd('echo "[Updated] ' .. command .. '"')
          else
            vim.cmd('echohl ErrorMsg')
            vim.cmd('echom "[Error:' .. exit_code .. '] ' .. command .. '"')
            vim.cmd('echohl NONE')
          end
          update_next()
        end,
      })
      break
    end
  end

  update_next()
end)

u.command('InstallExternalPackages', function()
  local to_install = u.clone_table(install_cmds)

  vim.cmd('echo "Installing packages..."')
  local function install_next()
    for idx, command in pairs(to_install) do
      to_install[idx] = nil
      vim.fn.jobstart(command, {
        on_exit = function(_, exit_code)
          if exit_code == 0 then
            vim.cmd('echo "[Installed] ' .. command .. '"')
          else
            vim.cmd('echohl ErrorMsg')
            vim.cmd('echom "[Error:' .. exit_code .. '] ' .. command .. '"')
            vim.cmd('echohl NONE')
          end
          install_next()
        end,
      })
      break
    end
  end

  install_next()
end)

return {
  startup = startup
}
