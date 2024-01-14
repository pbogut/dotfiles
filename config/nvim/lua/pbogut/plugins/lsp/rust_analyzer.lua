local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    cmd = { 'rust-analyzer' },
  })
  lspconfig.rust_analyzer.setup(opts)
  lspconfig.rust_analyzer.setup = function(_) end
end

return me
