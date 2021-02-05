-- alternate file module --
local u = require('utils')

local g = vim.g
local fn = vim.fn
local cmd = vim.cmd

local a = {}
local l = {}

u.map('n', '<space>ta', ':lua require"alternate".go_alternate()<cr>', { silent = true })

-- how many lines from botton and top to search for alternate annotation
local fallback = ':A'

local configuration = {
    ["composer.json&bin/magento"] = { -- magento2 project
      ['.*/web/templates?/.*/[^/]*%.html$'] = {
        alternate = function(relative, _)
          local glob = relative:gsub('(.*)/web/templates?/.*/(.-)%.html', '%1/web/%*%*/%2.js')
          return u.glob(glob)
        end
      },
      ['.*/web/js/.*/[^/]*%.js$'] = {
        alternate = function(relative, _)
          local glob = relative:gsub('(.*)/web/js/.*/(.-)%.js', '%1/web/%*%*/%2.html')
          return u.glob(glob)
        end
      },
    }
}

-- member functions
function a.go_alternate()
  local cwd = fn.getcwd()

  for project_pattern, project_config in pairs(configuration) do
    if l.check_project(cwd, project_pattern) and l.handle_project(project_config)then
      return true
    end
  end

  local res, _ = pcall(cmd,fallback)
  if not res then
    cmd([[echo "No alternate file found."]])
  end
  return res
end

-- local functions
function l.ask(list)
  local options = {
    source = list,
    options = '--prompt "Select Alternate> " ' .. g.fzf_preview,
    sink = 'e',
  }
  fn['fzf#run'](fn['fzf#wrap'](options))
end

function l.check_project(path, pattern)
  if pattern:match('%|') then
    local or_checks = u.split_string(pattern, '|')
    local check = nil
    for _, or_check in ipairs(or_checks) do
      if check == nil then
        check = l.check_project(path, or_check)
      else
        check = check or l.check_project(path, or_check)
      end
    end
    return check
  elseif pattern:match('%&') then
    local and_checks = u.split_string(pattern, '&')
    local check = true
    for _, and_check in ipairs(and_checks) do
      if check == nil then
        check = l.check_project(path, and_check)
      else
        check = check and l.check_project(path, and_check)
      end
    end
    return check
  end

  if pattern:match('^%!') then
    return fn.filereadable(path .. '/' .. pattern:gsub('^%!', '')) == 0
  else
    return fn.filereadable(path .. '/' .. pattern) > 0
  end
end

function l.check_file(relative, pattern)
  return relative:match(pattern)
end

function l.handle_alternate(config)
  local cwd = fn.getcwd()
  local filename = fn.expand('%:p')
  local relative = filename:gsub('^' .. cwd .. '/', '')
  local result = config.alternate(relative, {file = filename, dir = cwd})

  if not config.alternate then
    result = {}
  end

  if #result == 1 then
    cmd('e ' .. result[1])
    return true
  elseif #result > 1 then
    l.ask(result)
    return true
  end

  return false
end

function l.handle_project(project_patterns)
  local cwd = fn.getcwd()
  local filename = fn.expand('%:p')
  local relative = filename:gsub('^' .. cwd .. '/', '')

  for file_pattern, file_config in pairs(project_patterns) do
    -- let match many file patterns, or should we - first come first win even without alternate file?
    if l.check_file(relative, file_pattern) and l.handle_alternate(file_config) then
      return true
    end
  end

  return false
end

return a
