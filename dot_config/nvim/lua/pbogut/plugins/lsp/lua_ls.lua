local config = require('pbogut.config')
local lspconfig = require('lspconfig')
local util = require('lspconfig/util')
local me = {}

function me.setup(opts)
  local libraries = {}
  local globals = {}
  if vim.fn.filereadable('vim.toml') == 1 then
    libraries = vim.h.ls(vim.fn.stdpath('data') .. '/lazy')
    globals = { 'vim' }
  end

  opts = vim.tbl_deep_extend('keep', opts, {
    root_dir = function(fname)
      local cwd = vim.loop.cwd()
      local root = util.root_pattern('.git', 'init.lua')(fname)
      -- prefer cwd if root is a descendant
      return util.path.is_descendant(cwd, root) and cwd or root
    end,
    settings = {
      Lua = {
        workspace = {
          maxPreload = 2000,
          preloadFileSize = 1000,
          library = libraries,
        },
        diagnostics = {
          globals = globals,
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
