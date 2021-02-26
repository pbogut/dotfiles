local lspconfig = require('lspconfig')
local util = require 'lspconfig/util'
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    cmd = {'lua-language-server'},
    root_dir = function(fname)
      local cwd  = vim.loop.cwd();
      local root = util.root_pattern(".git", "init.lua")(fname);

      -- prefer cwd if root is a descendant
      return util.path.is_descendant(cwd, root) and cwd or root;
    end,
    settings = {
      Lua = {
        workspace = {
          library = {
            [vim.fn.expand('$VIMRUNTIME/lua')] = true,
            [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
            [vim.fn.stdpath('data') .. '/share/nvim/site/pack/packer/opt/packer.nvim/lua'] = true,
          },
          maxPreload = 2000,
          preloadFileSize = 1000,
        },
        diagnostics = {
          globals = {'hs', 'vim', 'it', 'describe', 'before_each', 'after_each', 'use'},
          -- disable = {'lowercase-global'}
        }
      }
    }
  })

  lspconfig.sumneko_lua.setup(opts)
end

return me
