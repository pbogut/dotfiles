local config = require('pbogut.config')
local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  -- keep licenceKey in ~/.config/intelephense/licence.txt
  local fake_home = os.getenv('HOME') .. '/.config'

  opts = vim.tbl_deep_extend('keep', opts, {
    on_init = function(client)
      -- get php version from composer
      local project_path = client.workspace_folders[1].name
      local composer_json = project_path .. '/composer.json'
      local composer = nil
      if vim.fn.filereadable(composer_json) == 1 then
        composer = vim.json.decode(vim.h.read_file(composer_json))
      end
      local composerPhpVer = vim.h.deep_get(composer, 'config.platform.php')
      if vim.h.deep_get(composer, 'config.platform.php') then
        print('Configuring intelephense for php ' .. composerPhpVer)
        local settings = client.config.settings
        vim.h.deep_set(settings, 'intelephense.environment.phpVersion', composerPhpVer)
        client.notify('workspace/didChangeConfiguration', { settings = settings })
      end
      return true
    end,
    cmd = {
      'sh',
      '-c',
      'HOME=' .. fake_home .. ' intelephense --stdio',
    },
    filetypes = { 'php', 'blade', 'html' },
    settings = {
      intelephense = {
        files = {
          associations = {
            '*.php',
            '*.phtml',
            '*.blade.php',
          },
        },
      },
    },
  })
  config.apply_to(opts.settings, 'intelephense', 'lsp.intelephense')
  lspconfig.intelephense.setup(opts)
end

return me
