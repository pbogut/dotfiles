local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    cmd = { 'elixir-ls' },
  })
  lspconfig.elixirls.setup(opts)
end

return me
