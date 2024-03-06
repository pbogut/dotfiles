local u = require('pbogut.utils')
local fn = vim.fn

local c = {}
local h = {}

function h.starts_with(str, start)
  return str:sub(1, #start) == start
end

function h.contains(str, pattern)
  return str:find(pattern, nil, true) ~= nil
end

local modules = {}
local config = {}

local function read_file(file)
  local has_file, content = pcall(fn.readfile, file)
  if not has_file then
    return {}
  end

  local can_decode, config = pcall(fn.json_decode, content)
  if not can_decode then
    vim.notify('Config found but it is invalid! [' .. file .. ']', vim.log.levels.WARN)
    return {}
  end

  return config
end

function c.load_modules()
  modules = {}
  local files = {}
  for _, path in pairs(vim.split(vim.o.runtimepath, ',')) do
    files = u.merge_tables(files, u.glob(path .. '/lua/pbogut/config/*.lua'))
  end
  for _, file in pairs(files) do
    local mod_name = file:gsub('.*/pbogut/config/(.*).lua', 'pbogut.config.%1')
    local ok, module = pcall(require, mod_name)
    if ok == true then
      modules[#modules + 1] = module
    end
  end
end

function c.load_for_cwd()
  config = {}
  if #modules == 0 then
    c.load_modules()
  end
  local cwd = vim.fn.getcwd()
  for _, module in pairs(modules) do
    if module.should_apply(cwd, h) then
      config = u.merge_tables(module.get_config(cwd), config)
    end
  end
end

c.load_for_cwd()

function c.reload_config()
  c.load_modules()
  c.load_for_cwd()
end

function c.dump()
  print(vim.inspect(config))
end

-- apply config on top of provided table and key
function c.apply_to(data, data_key, config_keys)
  local cfg = c.get(config_keys)
  if type(cfg) == 'table' then
    data[data_key] = u.merge_tables(data[data_key], cfg)
  end
end

function c.merge(data, config_keys)
  local cfg = c.get(config_keys)
  if type(cfg) == 'table' then
    return u.merge_tables(data, cfg)
  end
  return data
end

function c.get(keys, default)
  default = default or nil
  keys = fn.split(keys, '\\.')
  local val = config
  for _, key in ipairs(keys) do
    if val[key] then
      val = val[key]
    else
      return default
    end
  end
  return val or default
end

return c
