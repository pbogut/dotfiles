vim.api.nvim_set_hl(0, 'lualine_chezmoi_icon', {
  bg = vim.c.green,
  fg = vim.c.green,
})
vim.api.nvim_set_hl(0, 'lualine_chezmoi_actual_icon', {
  fg = vim.c.green,
  bg = vim.c.base02,
})
vim.api.nvim_set_hl(0, 'lualine_chezmoi_after_icon', {
  fg = vim.c.base02,
  bg = vim.c.green,
})

return function()
  if vim.b.chezmoi then
    return '%#lualine_chezmoi_icon#%#lualine_chezmoi_actual_icon# %#lualine_chezmoi_after_icon#%#lualine_c_normal#'
  else
    return ''
  end
end
