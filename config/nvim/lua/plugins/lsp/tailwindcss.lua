local lspconfig = require('lspconfig')
local color_provider = require('plugins.lsp.color_provider')
local me = {}

function me.setup(opts)
  local _on_attach = opts.on_attach
  opts.on_attach = function(client, bufnr)
    _on_attach(client, bufnr)
    color_provider.buf_attach(bufnr)
  end
  -- opts = vim.tbl_deep_extend('keep', opts, {
  --   filetype = {}
  -- })

  lspconfig.tailwindcss.setup(opts)
end

return me
