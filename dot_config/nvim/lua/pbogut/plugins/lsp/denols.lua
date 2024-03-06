local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    filetypes = {
      'javascript',
      'javascriptreact',
      'javascript.jsx',
    },
  })
  lspconfig.denols.setup(opts)
end

return me
