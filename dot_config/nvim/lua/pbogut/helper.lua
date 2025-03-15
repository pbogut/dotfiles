function _G.write_to_file(file, text)
  local f = io.open(file, 'w')
  if f == nil then
    return
  end
  f:write(text)
  f:close()
end

-- vim global helper functions
vim.h = {}

function vim.h.deep_get(t, k)
  local last_value = nil
  for _, i in ipairs(vim.split(k, '.', true)) do
    if t[i] == nil then
      return nil
    end
    t = t[i]
    last_value = t
  end
  return last_value
end

function vim.h.deep_set(t, k, v)
  local last_table = nil
  local last_index = nil
  for _, i in ipairs(vim.split(k, '.', true)) do
    if t[i] == nil then
      t[i] = {}
    end
    last_table = t
    last_index = i
    t = t[i]
  end
  if last_table and last_index then
    last_table[last_index] = v
  end
end

function vim.h.send_esc()
  local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'nx', false)
end

function vim.h.ls(directory)
  local i, t = 0, {}
  local pfile = io.popen('find "' .. directory .. '" -mindepth 1 -maxdepth 1 -type d')
  if pfile == nil then
    return {}
  end
  for filename in pfile:lines() do
    i = i + 1
    t[i] = filename
  end
  pfile:close()
  return t
end

function _G.mason_bin(file)
  if type(file) == 'string' then
    local bin = vim.fn.stdpath('data') .. '/mason/bin/' .. file
    if vim.fn.filereadable(bin) == 1 then
      return bin
    end
  end
  return nil
end

function _G.mason_pkg(path)
  return vim.fn.stdpath('data') .. '/mason/packages/' .. path
end

function _G.plugin_path(path)
  local result = vim.fn.stdpath('data') .. '/lazy/' .. path
  return result
end

function _G.gitpac_path(path)
  return os.getenv('HOME') .. '/.gitpac/' .. path
end

function _G.prequire(module_name)
  local success, module = pcall(require, module_name)
  local result = {}
  if success then
    result['done'] = function(callback)
      callback(module)
      return result
    end
    result['fail'] = function(_)
      return result
    end
  else
    result['done'] = function(_)
      return result
    end
    result['fail'] = function(callback)
      callback(module)
      return result
    end
  end

  return result
end

function _G.crequire(module_name, callback)
  callback = callback or {}
  local success, module = pcall(require, module_name)
  local result = {}
  if success then
    if type(callback.done) == 'function' then
      return callback.done(module)
    end
  else
    if type(callback.fail) == 'function' then
      return callback.fail(module)
    end
  end

  return result
end

function _G.rerequire(module_name)
  package.loaded[module_name] = nil
  return require(module_name)
end

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
