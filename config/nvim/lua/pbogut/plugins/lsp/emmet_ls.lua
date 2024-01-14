local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    cmd = {'node', gitpac_path('pbogut/emmet-ls/out/server.js'), '--stdio'},
    filetypes = {'xml', 'php', 'html', 'blade', 'vue', 'eelixir', 'css'},
    settings = {
      html_filetypes = {'xml', 'html', 'php'},
      css_filetypes = {'css', 'html', 'php'},
    }
  })
  lspconfig.emmet_ls.setup(opts)
end

return me
