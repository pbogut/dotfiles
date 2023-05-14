return function()
  -- dont really need that module, its only nice to have, so if its not loaded
  -- yet then dont bother with loading it, speeds startup time a bit
  if not require('lazy.core.config').plugins['harpoon']._.loaded then
    return ''
  end

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
