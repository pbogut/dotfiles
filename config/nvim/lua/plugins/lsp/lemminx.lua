local config = require('config')
local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    settings = {
      xml = {
        catalogs = {
          '.lemminx.xml',
        },
      },
    },
  })
  config.apply_to(opts.settings, 'xml', 'lsp.lemminx')
  lspconfig.lemminx.setup(opts)
end

return me
