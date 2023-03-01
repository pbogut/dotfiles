local builtin = require('telescope.builtin')
local conf = require('telescope.config').values
local k = vim.keymap

local last_query = ''

local ripgrep = function(opt)
  local query = opt.args
  local vimgrep_arguments = conf.vimgrep_arguments
  if query == '' then
    query = last_query
  else
    last_query = query
  end
  local dirs = { vim.fn.getcwd() }
  if query:match('%/$') then
    local dir = query:gsub('(.-) ([^%s]+%/)$', '%2')
    if dir:byte(1) ~= 47 then
      local sep = '/./'
      if dir:byte(1) == 46 then
        sep = '/'
      end
      dir = vim.fn.getcwd() .. sep .. query:gsub('(.-) ([^%s]+%/)$', '%2')
    end
    dirs = { dir }
    query = query:gsub('(.-) ([^%s]+%/)$', '%1')
  end

  local options = ''
  if query:match('^%-s ') then
    query = query:sub(4)
    vimgrep_arguments[#vimgrep_arguments + 1] = '-s'
    options = '[-s] '
  end
  if query:match('^%-i ') then
    query = query:sub(4)
    vimgrep_arguments[#vimgrep_arguments + 1] = '-i'
    options = '[-i] '
  end

  local message = options .. '"' .. query .. '"'
  local short_dirs = {}
  for _, dir in pairs(dirs) do
    if dir ~= vim.fn.getcwd() then
      short_dirs[#short_dirs + 1] = dir:gsub('^.*%.%/', '')
    end
  end
  if #short_dirs > 0 then
    message = message .. ' in ' .. table.concat(short_dirs, ', ')
  end
  print(message)
  builtin.grep_string({
    search = query,
    use_regex = opt.regex,
    search_dirs = dirs,
    vimgrep_arguments = vimgrep_arguments,
  })
end

function _G.ripgrep_in_dir_complete(text)
  local result = {}

  local dirs = vim.fn.globpath('.', '**/')

  local lead = text:gsub('.*%s', '')
  local query = text:sub(1, text:len() - lead:len())

  for name, _ in dirs:gmatch('.-\n') do
    name, _ = name:gsub('^%.%/(.-)\n$', '%1')
    if name:sub(1, lead:len()) == lead then
      table.insert(result, query .. name)
    end
  end

  table.sort(result, function(val1, val2)
    if val1:gsub('[^%/]', ''):len() ~= val2:gsub('[^%/]', ''):len() then
      return val1:gsub('[^%/]', ''):len() < val2:gsub('[^%/]', ''):len()
    else
      return val1 < val2
    end
  end)

  return result
end

k.set('n', '<space>gg', function()
  vim.ui.input({
    prompt = 'Rg: ',
    default = '',
    completion = 'customlist,v:lua.ripgrep_in_dir_complete',
  }, function(query)
    if query then
      ripgrep({ args = query, regex = false })
    end
  end)
end)

-- grep with regexp
k.set('n', '<space>gr', function()
  local query = vim.fn.input({
    prompt = 'Rg!: ',
    default = '',
    cancelreturn = 0,
  })
  if type(query) == 'string' then
    ripgrep({ args = query, regex = true })
  end
end)
