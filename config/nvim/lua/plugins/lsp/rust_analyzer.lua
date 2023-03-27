local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  local cmd = vim.fn.system('rustup which rust-analyzer'):gsub('\n', '')
  opts = vim.tbl_deep_extend('keep', opts, {
    cmd = { cmd },
  })
  lspconfig.rust_analyzer.setup(opts)
  lspconfig.rust_analyzer.setup = function(_) end
end

return me
