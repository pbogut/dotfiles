local lspconfig = require('lspconfig')
local color_provider = require('plugins.lsp.color_provider')
local me = {}

function me.setup(opts)
  local _on_attach = opts.on_attach
  opts.on_attach = function(client, bufnr)
    _on_attach(client, bufnr)
    color_provider.buf_attach(bufnr, {
      mode = "virt_text",
      color_indicator = "▣ ",
    })
  end
  local fts = lspconfig.tailwindcss.document_config.default_config.filetypes;
  fts[#fts+1] = 'rust'
  opts = vim.tbl_deep_extend('keep', opts, {
    init_options = {
      userLanguages = {
        eelixir = 'html-eex',
        elixir = 'phoenix-heex',
        heex = 'phoenix-heex',
        surface = 'phoenix-heex',
        svelte = 'html',
        eruby = 'erb',
        rust = 'html',
      },
    },
  })

  lspconfig.tailwindcss.setup(opts)
end

return me
