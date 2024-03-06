local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    filetypes = { 'html', 'php', 'blade', 'templ' },
    settings = {
      html = {
        validate = {
          scripts = true, -- some issues when mixed with PHP
        },
      },
    },
  })
  lspconfig.html.setup(opts)
end

return me
