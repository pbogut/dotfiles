local u = {}
local cmd = vim.cmd
local fn = vim.fn
local b = vim.b
local bo = vim.bo

local autocmd_callbacs = {}
local command_callbacs = {}
local mapping_callbacs = {}

function u.call_autocmd(no)
  autocmd_callbacs[no]()
end

function u.call_command(no, ...)
  command_callbacs[no](...)
end

function u.call_mapping(no)
  mapping_callbacs[no]()
end

-- Set indent for current buffer
-- @param width Width in characters
-- @param[opt=false] hardtab Use hard tab character
-- @param[opt=false] force   Force indent even if already set
function u.set_indent(width, hardtab, force)
  force = force or false
  -- Skip if already set
  if not force and b.set_indent_initiated then
    return
  end
  -- Skip if .editorconfig is available (@todo implement project root search)
  if not force and fn.filereadable('.editorconfig') > 0 then
    b.set_indent_skip_editorconfig = true
    return
  end
  -- optional params
  hardtab = hardtab or false

  b.set_indent_initiated = true
  b.set_indent_width = width
  b.set_indent_hardtab = hardtab
  b.set_indent_hardtab = hardtab

  bo.tabstop = width
  bo.shiftwidth = width
  bo.expandtab = not hardtab
end

-- Set up highlight
-- @param groups {HlGroup = {guibg = '#123456', guifg='#654321'}}
function u.highlights(groups)
  for group_name, definition in pairs(groups) do
    if definition.link then
      cmd('highlight link ' .. group_name .. ' ' .. definition.link)
    else
      local command = 'highlight ' .. group_name
      for key, value in pairs(definition) do
        command = command .. ' ' .. key .. '=' .. value
      end
      cmd(command)
    end
  end
end

-- Define signs
-- @param groups {SignGroup = {text = 'X', texthl='#654321'}}
function u.signs(groups)
  for group_name, definition in pairs(groups) do
    fn.sign_define(group_name, definition)
  end
end

function u.copy_table(tab)
  return fn.copy(tab)
end

function u.extend_table(tab1, tab2)
  return fn.extend(tab1, tab2)
end

function u.split_string(text, split)
  if split then
    return fn.split(text, split)
  else
    return fn.split(text)
  end
end

function u.sub_string(text, start, stop)
  start = start or 1
  stop = stop or text:len()
  return string.char(string.byte(text, start, stop))
end

function u.trim_string(text)
  text, _ = text:gsub('^%s*(.-)%s*$', '%1')
  return text
end

function u.string_under_coursor()
  local pos1 = fn.searchpos([["\|'\|\s\|^.]], 'bn')
  local pos2 = fn.searchpos([["\|'\|\s\|$]], 'n')
  local line = ''
  if pos1[1] == pos2[1] and pos1[2] < pos2[2] then
    line = fn.getline(fn.line('.'))
    line = u.sub_string(line, pos1[2], pos2[2])
    line = line:gsub('^%s*(.*)', '%1')
    line = line:gsub([[^['"](.*)['"]$]], '%1')
  end
  return line
end

function u.table_map(list, fun)
  local result = {}
  for k, v in pairs(list) do
    result[k] = fun(v, k)
  end
  return result
end

function u.table_keys(list)
  local result = {}
  u.table_map(list, function(_, k)
    result[#result + 1] = k
  end)
  return result
end

function u.table_remove(list, start, length)
  for _ = 1, length do
    table.remove(list, start)
  end
  return list
end

function u.combine(tabs)
  local result = {}
  for _, tab in pairs(tabs) do
    result = u.merge_tables(tab, result)
  end
  return result
end

-- merges tables recursively, if both values
-- are lists (see tbl_islist) then it merges
-- data from both tables into one (not replacing one with other)
-- for tables it is creating new ones (not passing refrence)
-- so changes should not affect input values
-- (although, functions will still go by reference, possibly
-- other data types that are passed by reference as well)
-- @param append[false] - if true and two lists are merged, elements from second
-- one will be appended to elements from the first one (by default its
-- other way around)
function u.merge_tables(val1, val2, append)
  append = append or false
  local fresh_one = {}
  if type(val1) == 'table' and type(val2) == 'table' and vim.tbl_islist(val1) and vim.tbl_islist(val2) then
    local uniqueness = {}
    local t1 = val2
    local t2 = val1
    if append then
      t1 = val1
      t2 = val2
    end
    for _, sub in ipairs(t1) do
      uniqueness[sub] = true
      table.insert(fresh_one, sub)
    end
    for _, sub in ipairs(t2) do
      if not uniqueness[sub] then
        table.insert(fresh_one, sub)
      end
    end
  elseif type(val1) == 'table' and type(val2) == 'table' then
    for key1, subval1 in pairs(val1) do
      fresh_one[key1] = u.merge_tables(subval1, val2[key1])
    end
    for key2, subval2 in pairs(val2) do
      fresh_one[key2] = u.merge_tables(val1[key2], subval2)
    end
  elseif val1 == nil then
    fresh_one = val2
  else
    fresh_one = val1
  end
  return fresh_one
end

function u.clone_table(val1)
  return u.merge_tables({}, val1)
end

function u.unique(tab)
  local result = {}
  local temp = {}
  for _, v in ipairs(tab) do
    temp[v] = true
  end
  for v, _ in pairs(temp) do
    result[#result + 1] = v
  end
  return result
end

function u.glob(pattern)
  local result = fn.glob(pattern)
  return u.split_string(result, '\n')
end

function u.termcodes(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function u.spairs(t, order)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do
    keys[#keys + 1] = k
  end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys
  if order then
    table.sort(keys, function(a, b)
      return order(t, a, b)
    end)
  else
    table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

function u.dedup(tab, keymaker)
  local key_index = {}
  local del_index = {}
  for index, element in ipairs(tab) do
    local key = element
    if keymaker then
      key = keymaker(element)
    end
    if key_index[key] then
      table.insert(del_index, 1, index)
    end
    key_index[key] = true
  end

  for _, index in ipairs(del_index) do
    table.remove(tab, index)
  end

  return tab
end

function u.profile_start()
  cmd([[profile start profile.log]])
  cmd([[profile func *]])
  cmd([[profile file *]])
end

function u.profile_stop()
  cmd([[profile pause]])
  cmd([[noautocmd qall!]])
end

function u.pp(var)
  print(vim.inspect(var))
end

function u.debounce_trailing(fun, ms, first)
  local timer = vim.loop.new_timer()
  local wrapped_fn

  if not first then
    function wrapped_fn(...)
      local argv = { ... }
      local argc = select('#', ...)

      timer:start(ms, 0, function()
        pcall(vim.schedule_wrap(fun), unpack(argv, 1, argc))
      end)
    end
  else
    local argv, argc
    function wrapped_fn(...)
      argv = argv or { ... }
      argc = argc or select('#', ...)

      timer:start(ms, 0, function()
        pcall(vim.schedule_wrap(fun), unpack(argv, 1, argc))
      end)
    end
  end
  return wrapped_fn, timer
end

function u.process_shell_commands(commands, messages, callback)
  local to_process = u.clone_table(commands)
  local errors = 0
  local success = 0
  local notify = nil
  local function process_next()
    if #to_process == 0 then
      local msg = messages.prefix
        .. '['
        .. success
        .. '/'
        .. #commands
        .. '] '
        .. (messages.done or 'Commands finished.')
      if errors > 0 then
        msg = msg .. ' (' .. errors .. ' ' .. (errors > 1 and 'errors' or 'error') .. ')'
      end
      notify = vim.notify(msg, vim.log.levels.INFO, { replace = notify })

      if type(callback) == 'function' then
        callback()
      end
      return
    end
    local command = table.remove(to_process, 1)
    local progress = '[' .. #commands - #to_process .. '/' .. #commands .. '] '

    notify =
      vim.notify((messages.prefix or '[Running]') .. progress .. command, vim.log.levels.INFO, { replace = notify })
    vim.fn.jobstart(command, {
      on_stdout = function(_, lines)
        for _, line in pairs(lines) do
          if line:len() > 1 then
            notify = vim.notify(
              (messages.prefix or '[Running]') .. progress .. command .. ' | ' .. line,
              vim.log.levels.INFO,
              { replace = notify }
            )
          end
        end
      end,
      on_exit = function(_, exit_code)
        if exit_code == 0 then
          success = success + 1
        else
          errors = errors + 1
          vim.cmd('echohl ErrorMsg')
          vim.cmd('echom "[Error:' .. exit_code .. '] ' .. command .. '"')
          vim.cmd('echohl NONE')
        end
        process_next()
      end,
    })
  end

  process_next()
end

function u.hostname()
  local f = io.popen('/bin/hostname')
  local hostname = f:read('*a') or ''
  f:close()
  hostname = string.gsub(hostname, '\n$', '')
  return hostname
end

return u
