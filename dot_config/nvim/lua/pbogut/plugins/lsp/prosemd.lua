local lsp_util = require('lspconfig/util')
local lsp_config = require('lspconfig/configs')

lsp_config.prosemd = { default_config = {} }

local opts = {
  filetypes = { 'markdown', 'mail' },
  root_dir = function(fname)
    return vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
  end,
  settings = {},
}

return opts
