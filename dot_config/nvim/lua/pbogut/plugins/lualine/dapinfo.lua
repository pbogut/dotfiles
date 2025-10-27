vim.api.nvim_set_hl(0, 'sl_dap', {
  fg = vim.c.orange,
  bg = vim.c.base02,
})

return function()
  if not require('lazy.core.config').plugins['nvim-dap']._.loaded then
    return ''
  end
  local dap = require('dap')
  local status = dap.status()
  if status:len() > 0 then
    return '%#sl_dap# (' .. status .. ')'
  end

  return ''
end
