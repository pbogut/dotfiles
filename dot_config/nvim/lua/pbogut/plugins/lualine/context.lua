local c = require('pbogut.settings.colors')

return function()
  vim.api.nvim_set_hl(0, 'sl_context', {
    fg = c.base3,
    bg = c.base02,
    bold = true,
  })

  if vim.b._x_context  then
    return '%#sl_context#' .. vim.b._x_context
  end
  return ''
end
