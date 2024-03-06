local config = require('pbogut.config')
local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    filetypes = { 'sh', 'zsh' },
  })
  config.apply_to(opts.settings, 'bashls', 'lsp.bashls')
  lspconfig.bashls.setup(opts)
end

return me
