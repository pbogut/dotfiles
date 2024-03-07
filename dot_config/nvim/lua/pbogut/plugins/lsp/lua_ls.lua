local config = require('pbogut.config')
local lspconfig = require('lspconfig')
local util = require('lspconfig/util')
local me = {}

function me.setup(opts)
  local root_dir = function(fname)
    local cwd = vim.loop.cwd()
    local root = util.root_pattern('.luarc.json', '.git')(fname)
    return root or cwd
  end

  opts = vim.tbl_deep_extend('keep', opts, {
    root_dir = root_dir,
    settings = {
      Lua = {
        workspace = {
          maxPreload = 2000,
          preloadFileSize = 1000,
        },
        hint = {
          enable = true,
        },
      },
    },
  })
  config.apply_to(opts.settings, 'Lua', 'lsp.lua_ls')
  lspconfig.lua_ls.setup(opts)
end

return me
