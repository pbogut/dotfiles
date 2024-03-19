local config = require('pbogut.config')
local lspconfig = require('lspconfig')
local util = require('lspconfig/util')
local me = {}

function me.setup(opts)
  local root_dir = function(fname)
    local cwd = vim.loop.cwd()
    local root = util.root_pattern('.sqllsrc.json', '.git')(fname)
    return root or cwd
  end

  opts = vim.tbl_deep_extend('keep', opts, {
    root_dir = root_dir,
    settings = {},
  })
  config.apply_to(opts.settings, 'sqlLanguageServer', 'lsp.sqlLanguageServer')
  lspconfig.sqlls.setup(opts)
end

return me
