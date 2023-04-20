local dap = require('dap')

local extension_path = mason_pkg('codelldb/extension')
local codelldb_path = extension_path .. '/adapter/codelldb'
local liblldb_path = extension_path .. '/lldb/lib/liblldb.so'

local opts = {
  dap = {
    adapter = require('rust-tools.dap').get_codelldb_adapter(codelldb_path, liblldb_path),
  },
}

vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('x_rust_tools', { clear = true }),
  pattern = '*.rs',
  callback = function()
    vim.keymap.set('n', '<space>dc', function()
      if not dap.adapters.rt_lldb then
        require('rust-tools.dap').setup_adapter()
      end
      if dap.status() ~= '' then
        dap.continue()
      else
        require('rust-tools').debuggables.debuggables()
      end
    end)
  end,
})

require('rust-tools').setup(opts)
