local colors = require('pbogut.settings.colors')
vim.api.nvim_set_hl(0, 'lualine_chezmoi_icon', {
  fg = colors.base02,
  bg = colors.green,
})

return function()
  if vim.b.chezmoi then
    return '%#lualine_chezmoi_icon# %#lualine_c_normal#'
  else
    return ''
  end
end
