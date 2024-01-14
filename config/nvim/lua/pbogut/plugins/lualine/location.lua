return function()
  local current_line = vim.fn.line('.')
  local total_line = vim.fn.line('$')
  local line = vim.fn.line('.')
  local column = vim.fn.col('.')
  local percent = 0
  if current_line ~= 1 then
    percent, _ = math.modf((current_line / total_line) * 100)
  end
  return percent .. '%% :' .. line .. '/' .. total_line .. ' :' .. column
end
