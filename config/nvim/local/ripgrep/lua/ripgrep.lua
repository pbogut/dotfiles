local k = vim.keymap
local conf = require('telescope.config').values
local builtin = require('telescope.builtin')

local last_query = ''
local rip_grep_mode = false
local rip_grep_options = {}
local opt_def = { s = 1, i = 1, u = 3 }

_G.lazy_loaded.ripgrep = true

local toggle_option = function(opt_name)
  local count = 0
  for _, v in ipairs(rip_grep_options) do
    if v == '-' .. opt_name then
      count = count + 1
    end
  end
  if count >= opt_def[opt_name] then
    local to_remove = {}
    for i, v in ipairs(rip_grep_options) do
      if v == '-' .. opt_name then
        to_remove[#to_remove + 1] = i
      end
    end
    table.sort(to_remove, function(x, y)
      return x > y
    end)
    for _, i in ipairs(to_remove) do
      table.remove(rip_grep_options, i)
    end
  else
    rip_grep_options[#rip_grep_options + 1] = '-' .. opt_name
  end
  require('lualine').refresh()
  vim.cmd.redrawstatus()
end

local get_options = function()
  local options = {}
  for _, opt in ipairs(conf.vimgrep_arguments) do
    options[#options + 1] = opt
  end
  for _, opt in ipairs(rip_grep_options) do
    options[#options + 1] = opt
  end

  return options
end

local statusline = function()
  if rip_grep_mode then
    local res = {}
    for i, v in ipairs(rip_grep_options) do
      res[#res + 1] = v:gsub('^%-(.)$', '%1')
    end
    if #res > 0 then
      return 'rg [' .. table.concat(res, '') .. ']'
    else
      return 'rg'
    end
  end
  return ''
end

local ripgrep = function(opt)
  local query = opt.args
  local vimgrep_arguments = conf.vimgrep_arguments
  dump(vimgrep_arguments)
  if query == '' then
    query = last_query
  else
    last_query = query
  end
  local dirs = { vim.fn.getcwd() }

  if query:match('%s[%w%p]*%/$') then
    local dir = query:gsub('(.-) ([^%s]*%/)$', '%2')
    if dir:byte(1) ~= 47 then -- /
      dir = query:gsub('(.-) ([^%s]+%/)$', '%2')
    end
    dirs = { dir }
    query = query:gsub('(.-) ([^%s]+%/)$', '%1')
  elseif query:match('%s%%$') then
    dirs = { vim.fn.expand('%') }
    query = query:gsub('(.-) %%$', '%1')
  end

  if query:match([[^!(.*)$]]) then
    query = query:gsub([[^!(.*)$]], '%1')
    opt.regex = true
  end

  local options = ''
  if query:match('^%-s ') then
    query = query:sub(4)
    vimgrep_arguments[#vimgrep_arguments + 1] = '-s'
    options = options .. 's'
  end
  if query:match('^%-i ') then
    query = query:sub(4)
    vimgrep_arguments[#vimgrep_arguments + 1] = '-i'
    options = options .. 'i'
  end
  if query:match('^%-u ') then
    query = query:sub(4)
    vimgrep_arguments[#vimgrep_arguments + 1] = '-u'
    options = options .. 'u'
  end

  if options:len() > 0 then
    options = '[' .. options .. '] '
  end

  local message = ''
  if opt.regex then
    message = options .. 'r/' .. query .. '/'
  else
    message = options .. '"' .. query .. '"'
  end

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
    vimgrep_arguments = get_options(),
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

k.set('n', '<plug>(ripgrep-search)', function()
  rip_grep_mode = true

  k.set('c', '<c-i>', function()
    toggle_option('i')
  end, { noremap = false })

  k.set('c', '<c-s>', function()
    toggle_option('s')
  end, { noremap = false })

  k.set('c', '<c-u>', function()
    toggle_option('u')
  end, { noremap = false })
  vim.ui.input({
    prompt = 'Rg: ',
    default = '',
    completion = 'customlist,v:lua.ripgrep_in_dir_complete',
  }, function(query)
    rip_grep_mode = false
    k.del('c', '<c-i>')
    k.del('c', '<c-s>')
    k.del('c', '<c-u>')
    if query then
      ripgrep({ args = query, regex = false })
    end
  end)
end)

-- grep with regexp
k.set('n', '<plug>(ripgrep-with-regex)', function()
  local query = vim.fn.input({
    prompt = 'Rg!: ',
    default = '',
    cancelreturn = 0,
  })
  if type(query) == 'string' then
    ripgrep({ args = query, regex = true })
  end
end)

vim.cmd([[
  nmap <silent> <plug>(ripgrep-op) :set opfunc=Ripgrep_from_motion<cr>g@
  function! Ripgrep_from_motion(type, ...)
    let l:tmp = @a
    if a:0  " Invoked from Visual mode, use '< and '> marks.
      silent exe("normal! `<" . a:type . "`>\"ay")
    elseif a:type == 'line'
      silent exe "normal! '[V']\"ay"
    elseif a:type == 'block'
      silent exe "normal! `[\<C-V>`]\"ay"
    else
      silent exe "normal! `[v`]\"ay"
    endif
    call v:lua.require('ripgrep').ripgrep({"args": trim(@a)})
    " exe("Rg " . trim(@a))
    let @a = l:tmp
  endfunction
]])

return { ripgrep = ripgrep, statusline = statusline }
