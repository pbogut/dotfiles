local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    settings = {
      tailwindCSS = {
        experimental = {
          classRegex = {
            [[class:\s\"([^"]+)\"]],
            [[cls:\s\"([^"]+)\"]],
            [[[a-z]+_class=\"([^"]+)\"]],
          }
        },
        includeLanguages = {
          plaintext = "html",
          elixir = 'phoenix-heex',
          eelixir = 'html-eex',
          heex = 'phoenix-heex',
          surface = 'phoenix-heex',
          svelte = 'html',
          eruby = 'erb',
          rust = 'html',
          templ = 'html',
        },
      },
    },
  })

  lspconfig.tailwindcss.setup(opts)
end

return me
