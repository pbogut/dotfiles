---@type LazyPluginSpec
return {
  'simrat39/rust-tools.nvim',
  ft = { 'rust' },
  config = function()
    ---@type any
    local dap = require('dap')

    local extension_path = mason_pkg('codelldb/extension')
    local codelldb_path = extension_path .. '/adapter/codelldb'
    local liblldb_path = extension_path .. '/lldb/lib/liblldb.so'

    local opts = {
      dap = {
        adapter = require('rust-tools.dap').get_codelldb_adapter(codelldb_path, liblldb_path),
      },
      tools = {
        inlay_hints = {
          parameter_hints_prefix = '    <- ',
          other_hints_prefix = '     => ',
        },
      },
    }

    vim.keymap.set('n', '<space>rr', "<cmd>lua require('rust-tools').runnables.runnables()<cr>")
    -- override dap contine for rust files
    vim.keymap.set('n', '<plug>(dap-continue)', function()
      if dap.status() ~= '' then
        dap.continue()
      else
        require('rust-tools').debuggables.debuggables()
      end
    end)

    local rusttools = require('rust-tools')
    rusttools.setup(opts)
  end,
}
