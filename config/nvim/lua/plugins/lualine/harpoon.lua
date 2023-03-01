return function()
  local has_harpoon, mark = pcall(require, 'harpoon.mark')
  if not has_harpoon then
    return ''
  end

  local result = mark.get_index_of(vim.fn.expand('%'))
  if result then
    return '󰇇' .. result
  end

  return ''
end
