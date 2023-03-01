local lspconfig = require('lspconfig')
local lsp_util = require('lspconfig/util')
local lsp_config = require('lspconfig/configs')
local me = {}

lsp_config.prosemd = { default_config = {} }

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    filetypes = { 'markdown', 'mail' },
    root_dir = function(fname)
      return lsp_util.find_git_ancestor(fname) or vim.fn.getcwd()
    end,
    settings = {},
  })
  lspconfig.prosemd.setup(opts)
end

return me
