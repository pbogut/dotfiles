local c = require('pbogut.settings.colors')

local function change()
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

local function mode()
  if vim.o.diff then
    return ''
  else
    return ''
  end
end

local function mode_green()
  if vim.o.diff then
    return '%#sl_diffmode#'
  else
    return ''
  end
end

vim.api.nvim_set_hl(0, 'sl_diffmode', {
  bg = c.green,
  fg = c.base3,
  bold = true,
})

return {
  change = change,
  mode = mode,
  mode_green = mode_green,
}
