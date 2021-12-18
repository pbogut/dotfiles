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
  if vim.fn.glob(result) == '' then
    result = vim.fn.stdpath('data') .. '/site/pack/packer/opt/' .. path
  end

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
    if type(callback.done) == "function" then
      return callback.done(module)
    end
  else
    if type(callback.fail) == "function" then
      return callback.fail(module)
    end
  end

  return result
end
