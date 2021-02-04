local u = require('utils')
local fn = vim.fn

local c = {}

local function read_file(file)
  local has_file, content = pcall(fn.readfile, file)
  if not has_file then
    return {}
  end

  local can_decode, config = pcall(fn.json_decode, content)
  if not can_decode then
    print('Config found but it is invalid! [' .. file .. ']')
    return {}
  end

  return config
end

local function load_config()
  local user_config = {}
  local path_config = {}

  local user_file = os.getenv('HOME') .. '/.nvim-config.json';
  local path_file = fn.getcwd() .. '/.nvim-config.json';


  if fn.filereadable(user_file) > 0 then
    user_config = read_file(user_file)
  end
  if fn.filereadable(path_file) > 0 then
    path_config = read_file(path_file)
  end

  return u.merge_tables(user_config, path_config)
end

local config = load_config()

function c.reload_config()
  config = load_config()
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
