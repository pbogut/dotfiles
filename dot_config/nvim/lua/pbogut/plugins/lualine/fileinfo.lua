return function()
  local encode = vim.bo.fenc ~= '' and vim.bo.fenc or vim.o.enc
  local format = vim.bo.fileformat
  local filetype = vim.bo.filetype or vim.fn.expand('%:e') or ''
  local result = encode .. '[' .. format .. ']'
  if filetype ~= '' then
    result = result .. '[' .. filetype .. ']'
  end
  return result
end
