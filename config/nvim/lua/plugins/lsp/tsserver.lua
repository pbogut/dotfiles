local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    filetypes = {
      'typescript',
      'typescriptreact',
      'typescript.tsx',
      'javascript',
      'javascriptreact',
      'javascript.jsx',
    },
  })
  lspconfig.tsserver.setup(opts)
end

return me
