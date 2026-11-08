local config = require('pbogut.config')
local util = require('lspconfig/util')

local root_dir = function(bufnr, on_dir)
  local cwd = vim.fn.getcwd()
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local root = util.root_pattern('.luarc.json', '.git')(fname)
  on_dir(root or cwd)
end

local opts = {
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
}
config.apply_to(opts.settings, 'Lua', 'lsp.lua_ls')

return opts
