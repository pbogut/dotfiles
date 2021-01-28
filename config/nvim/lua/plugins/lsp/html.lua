local lspconfig = require('lspconfig')
local me = {}

--Enable (broadcasting) snippet capability for completion
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

function me.setup(on_attach)
  lspconfig.html.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { "html", "php", "blade" }
  }
end

return me
