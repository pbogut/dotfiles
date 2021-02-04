local config = require('config')
local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    filetypes = {"php", "blade"},
    settings = {
      intelephense = {
        files = {
          associations = {
            "*.php", "*.phtml", "*.blade.php"
          }
        }
      }
    }
  })
  config.apply_to(opts.settings, 'intelephense', 'lsp.intelephense')
  lspconfig.intelephense.setup(opts)
end

return me
