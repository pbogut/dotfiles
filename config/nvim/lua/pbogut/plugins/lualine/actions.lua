return function()
  local status = vim.g._actions_status
  if status:len() > 0 then
    return 'ﰌ ' .. status .. ''
  end

  return ''
end
