function _G.dump(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  local width = vim.fn.winwidth(0)
  local separator = ''
  for _ = 2, width, 1 do
    separator = separator .. '─'
  end
  print(table.concat(objects, '\n' .. separator .. '\n'))
  return ...
end


function _G.plugin_path(path)
  local result = vim.fn.stdpath('data') .. '/site/pack/packer/start/' .. path
  if vim.fn.glob(result) == "" then
    result = vim.fn.stdpath('data') .. '/site/pack/packer/opt/' .. path
  end

  return result
end
