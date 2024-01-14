---@type string|nil
local starship_cache = ''

local augroup = vim.api.nvim_create_augroup('x_lualine', { clear = true })
vim.api.nvim_create_autocmd('BufLeave', {
  group = augroup,
  callback = function()
    starship_cache = nil
  end,
})

return function()
  if starship_cache ~= nil then
    return starship_cache
  end
  starship_cache = vim.fn
    .system([[
      STARSHIP_SHELL="sh" starship prompt |
        head -n1 |
        sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g'
    ]])
    :gsub('%s*\n$', '')
    :gsub('^%[.-%] ', '')
    :gsub('%%', '󱉸')

  return starship_cache
end
