local colors = require('pbogut.settings.colors')
vim.api.nvim_set_hl(0, 'lualine_chezmoi_icon', {
  bg = colors.green,
  fg = colors.green,
})
vim.api.nvim_set_hl(0, 'lualine_chezmoi_actual_icon', {
  fg = colors.green,
  bg = colors.base02,
})

return function()
  if vim.b.chezmoi then
    return '%#lualine_chezmoi_icon#%#lualine_chezmoi_actual_icon# %#lualine_c_normal#'
  else
    return ''
  end
end
