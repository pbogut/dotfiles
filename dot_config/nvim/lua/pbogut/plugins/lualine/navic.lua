local has_navic, navic = pcall(require, 'nvim-navic')
return function()
  local bufnr = vim.fn.bufnr()
  if has_navic and navic.is_available(bufnr) then
    return navic.get_location({}, bufnr)
  end

  return ''
end
