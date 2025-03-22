local M = {}

---@param opts ProjectConfigOpts
function M.get_config(opts)
  return opts.helper.exists(opts.path .. '/go.mod')
    and {
      lsp = {
        autoformat_on_save = {
          enabled = true,
        },
      },
    }
end

return M
