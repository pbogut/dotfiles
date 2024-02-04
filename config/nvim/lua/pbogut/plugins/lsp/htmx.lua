local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    filetypes = { 'html', 'php', 'blade', 'templ' },
  })
  lspconfig.htmx.setup(opts)
end

return me
