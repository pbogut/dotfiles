local config = require('pbogut.config')
local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    settings = {
      xml = {
        server = {
          workDir = os.getenv('HOME') .. '/.cache/lemminx',
        },
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
