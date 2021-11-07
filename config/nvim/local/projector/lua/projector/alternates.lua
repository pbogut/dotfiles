local shared = require('projector.shared')
local u = require('utils')
local fn = vim.fn
local cmd = vim.cmd

local M = {}

local function ask(list)
  local options = {
    source = list,
    options = '--prompt "Select Alternate> " ' .. vim.g.fzf_preview,
    sink = 'e',
  }
  fn['fzf#run'](fn['fzf#wrap'](options))
end

local function select_alternate(files)
  if #files == 1 then
    cmd('e ' .. files[1])
    return true
  elseif #files > 1 then
    ask(files)
    return true
  end
end

function M.go_alternate()
  local cwd = fn.getcwd()
  local filename = fn.expand('%:p')
  local relative = filename:gsub('^' .. cwd .. '/', '')
  local file_configs = shared.get_file_config(true)
  local result = {}

  for _, cfg in u.spairs(file_configs) do
    if type(cfg.alternate) == 'string' then
      local file, _ = relative:gsub(cfg.pattern, cfg.alternate)
      result[#result+1] = file
    elseif type(cfg.alternate) == 'table' then
      for _, alternate_item in ipairs(cfg.alternate) do
        local file, _ = relative:gsub(cfg.pattern, alternate_item)
        result[#result+1] = file
      end
    elseif type(cfg.alternate) == 'function' then
      local match = {relative:match(cfg.pattern)}
      result = u.merge_tables(result, cfg.alternate(relative, {
        match = match, file = filename, dir = cwd
      }))
    end
  end

  result = u.unique(result)

  -- only existing files if any --
  local existing = {}
  for _, file in ipairs(result) do
    if fn.filereadable(fn.getcwd() .. '/' .. file) > 0 then
      existing[#existing+1] = file
    end
  end

  existing = u.unique(existing)

  if #existing > 0 then
    select_alternate(existing)
  else
    select_alternate(result)
  end
end

return M