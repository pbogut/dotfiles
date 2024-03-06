local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    filetypes = { 'php', 'blade' },
  })
  -- config.apply_to(opts.settings, 'intelephense', 'lsp.intelephense')
  lspconfig.psalm.setup(opts)
end

return me
