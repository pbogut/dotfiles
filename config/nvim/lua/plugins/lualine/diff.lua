return function()
  if vim.fn.exists('*sy#repo#get_stats') == 1 then
    local diff_add = vim.fn['sy#repo#get_stats']()[1]
    local diff_mod = vim.fn['sy#repo#get_stats']()[2]
    local diff_rem = vim.fn['sy#repo#get_stats']()[3]
    if diff_add ~= -1 then
      return '+' .. diff_add .. '~' .. diff_mod .. '-' .. diff_rem
    end
  end
  return ''
end
