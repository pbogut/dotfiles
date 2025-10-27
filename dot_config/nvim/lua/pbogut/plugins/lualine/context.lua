return function()
  vim.api.nvim_set_hl(0, 'sl_context', {
    fg = vim.c.base3,
    bg = vim.c.base02,
    bold = true,
  })

  if vim.b._x_context  then
    return '%#sl_context#' .. vim.b._x_context
  end
  return ''
end
