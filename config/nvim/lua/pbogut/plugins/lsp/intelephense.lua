local config = require('pbogut.config')
local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  -- keep licenceKey in ~/.config/intelephense/licence.txt
  local fake_home = os.getenv('HOME') .. '/.config'

  opts = vim.tbl_deep_extend('keep', opts, {
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
