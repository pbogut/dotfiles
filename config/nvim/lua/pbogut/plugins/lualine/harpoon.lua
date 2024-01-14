return function()
  -- dont really need that module, its only nice to have, so if its not loaded
  -- yet then dont bother with loading it, speeds startup time a bit
  if not require('lazy.core.config').plugins['harpoon']._.loaded then
    return ''
  end

  local has_harpoon, harpoon = pcall(require, 'harpoon')
  if not has_harpoon then
    return ''
  end

  local result = harpoon:list():get_by_display(vim.fn.expand('%'))
  if result then
    for i, item in ipairs(harpoon:list().items) do
      if item == result then
        return '󰣉' .. i
      end
    end
  end

  return ''
end
