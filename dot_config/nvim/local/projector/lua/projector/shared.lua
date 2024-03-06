local u = require('pbogut.utils')
local fn = vim.fn

local projector_setup = {}
local config_cache = {}
local projections = {}

local M = {}

-- Sort by priority ascending with nil's at the end
local function sort(tab, key1, key2)
  if not tab[key1].priority then
    return false
  end
  if not tab[key2].priority then
    return true
  end
  return tab[key1].priority > tab[key2].priority
end

-- Get deep value of table
local function get_value(tbl, keys, default)
  keys = keys or nil

  if type(keys) == 'string' then
    keys = fn.split(keys, '\\.')
  end
  if type(keys) == 'table' then
    for _, key in ipairs(keys) do
      if type(tbl) == 'table' then
        tbl = tbl[key]
      else
        tbl = nil
      end
    end
  end

  return tbl == nil and default or tbl
end

local function check_project(path, pattern)
  if pattern == '*' then
    return true
  end
  if pattern:match('%|') then
    local or_checks = u.split_string(pattern, '|')
    local check = nil
    for _, or_check in ipairs(or_checks) do
      if check == nil then
        check = check_project(path, or_check)
      else
        check = check or check_project(path, or_check)
      end
    end
    return check
  elseif pattern:match('%&') then
    local and_checks = u.split_string(pattern, '&')
    local check = true
    for _, and_check in ipairs(and_checks) do
      if check == nil then
        check = check_project(path, and_check)
      else
        check = check and check_project(path, and_check)
      end
    end
    return check
  end

  local check_fn = fn.filereadable
  if pattern:match('%/$') then
    check_fn = fn.isdirectory
  end
  if pattern:match('^%!') then
    return check_fn(path .. '/' .. pattern:gsub('^%!', '')) == 0
  else
    return check_fn(path .. '/' .. pattern) > 0
  end
end

local function check_file(relative, pattern)
  return relative:match(pattern)
end

function M.setup(opts)
  config_cache = {}
  projector_setup = opts
  projections = opts.projections or {}
end

function M.get_setup()
  return projector_setup
end

function M.get_config(keys, default)
  keys = keys or nil
  local cwd = fn.getcwd()
  local result = {}
  if config_cache[cwd] then
    result = config_cache[cwd]
  else
    for project_pattern, project_config in u.spairs(projections, sort) do
      if check_project(cwd, project_pattern) then
        -- first on the list has priority
        result = u.merge_tables(project_config, result)
      end
    end
    config_cache[cwd] = result
  end
  return get_value(result, keys, default)
end

function M.get_file_config(as_list)
  as_list = as_list or false
  local cwd = fn.getcwd()
  local filename = fn.expand('%:p')
  local relative = filename
  if filename:sub(1, #cwd) == cwd then
    relative = filename:sub(#cwd + 2)
  end
  local patterns = M.get_config('patterns', {})
  local result = {}
  for file_pattern, file_config in u.spairs(patterns, sort) do
    -- let match many file patterns, or should we - first come first win even without alternate file?
    if check_file(relative, file_pattern) then
      -- assign pattern as we dont pass key otherwise
      file_config.pattern = file_pattern
      -- collect all matching ones into list
      if as_list then
        result[#result + 1] = file_config
      else
        result = u.merge_tables(file_config, result)
      end
    end
  end

  return result
end

return M
