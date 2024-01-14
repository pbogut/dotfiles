local has_icons, devicons = pcall(require, 'nvim-web-devicons')

return function()
  local icon = ''
  local modified = ''
  local name = vim.fn.expand('%:t')

  if has_icons then
    local f_name, f_extension = vim.fn.expand('%:t'), vim.fn.expand('%:e')
    f_extension = f_extension ~= '' and f_extension or vim.bo.filetype
    local f_icon, _ = devicons.get_icon(f_name, f_extension)
    if f_icon then
      icon = f_icon .. ' '
    end
  end

  if vim.o.modified then
    modified = ' '
  end

  return icon .. name .. modified
end
