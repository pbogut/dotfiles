local u = {}
local cmd = vim.cmd
local fn = vim.fn
local b = vim.b
local bo = vim.bo
local api = vim.api

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

-- definitions = {
--   EventName = {
--     {"*", function() print('test') end };
--   }
-- }
function u.augroup(group_name, definitions)
  cmd('augroup ' .. group_name)
  cmd('autocmd!')
  for event_type, definition in pairs(definitions) do
    if type(definition[1]) ~= 'table' then
      definition = { definition }
    end
    for _, def in pairs(definition) do
      local callback = table.remove(def, #def)

      table.insert(def, 1, 'autocmd')
      table.insert(def, 2, event_type)
      local command = table.concat(def, ' ')
      if type(callback) == 'function' then
        table.insert(autocmd_callbacs, callback)
        callback = 'lua require("utils").call_autocmd('
          .. #autocmd_callbacs
          .. ')'
      end
      command = command .. ' ' .. callback
      cmd(command)
    end
  end
  cmd('augroup END')
end

-- its incomplete, dont have most things that one would want
function u.command(command_name, action, opts)
  opts = opts or {}
  local args = {}
  local command = 'command! '
  if opts.nargs then
    command = command .. '-nargs=' .. opts.nargs .. ' '
  end
  if opts.complete then
    command = command .. '-complete=' .. opts.complete .. ' '
  end
  if opts.bang then
    args[#args + 1] = '<bang>0?v:true:v:false'
    command = command .. '-bang '
  end
  if opts.qargs then
    args[#args + 1] = '<q-args>'
  end
  command = command .. command_name .. ' '
  if type(action) == 'function' then
    table.insert(command_callbacs, action)
    local call = [[call luaeval('require("utils").call_command(]]
      .. #command_callbacs
    for i, j in ipairs(args) do
      call = call .. ',_A[' .. i .. ']'
    end
    call = call .. [[)']]
    local opened = false
    for _, arg in ipairs(args) do
      if not opened then
        call = call .. ',['
        opened = true
      end
      call = call .. arg .. ','
    end
    if opened then
      call = call .. ']'
    end
    call = call .. [[)]]
    command = command .. call
    -- print(command)
  else
    command = command .. action
  end
  cmd(command)
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

function u.map(mode, key, result, opts)
  opts = vim.tbl_extend('keep', opts or {}, {
    noremap = true,
    silent = mode ~= 'c',
    expr = false,
  })
  if type(result) == 'function' then
    table.insert(mapping_callbacs, result)
    result = ':lua require("utils").call_mapping('
      .. #mapping_callbacs
      .. ')<cr>'
  end
  if opts.buffer then
    local buffer_nr = opts.buffer
    opts.buffer = nil
    api.nvim_buf_set_keymap(buffer_nr, mode, key, result, opts)
  else
    api.nvim_set_keymap(mode, key, result, opts)
  end
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
  for _=1,length do
    table.remove(list, start)
  end
  return list
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
  local fresh_one = nil
  if
    type(val1) == 'table'
    and type(val2) == 'table'
    and vim.tbl_islist(val1)
    and vim.tbl_islist(val2)
  then
    local uniqueness = {}
    fresh_one = {}
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
    fresh_one = {}
    for key1, subval1 in pairs(val1) do
      fresh_one[key1] = u.merge_tables(subval1, val2[key1])
    end
    for key2, subval2 in pairs(val2) do
      fresh_one[key2] = u.merge_tables(val1[key2], subval2)
    end
  elseif val1 == nil and val2 == nil then
    fresh_one = nil
  elseif val1 == nil then
    fresh_one = val2
  elseif val2 == nil then
    fresh_one = val1
  else
    fresh_one = val2 -- override with second
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

function u.buf_map(buffer_nr, mode, key, result, opts)
  opts = opts or {}
  opts.buffer = buffer_nr or 0
  u.map(mode, key, result, opts)
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
        msg = msg
          .. ' ('
          .. errors
          .. ' '
          .. (errors > 1 and 'errors' or 'error')
          .. ')'
      end
      vim.notify(msg)

      if type(callback) == 'function' then
        callback()
      end
      return
    end
    local command = table.remove(to_process, 1)
    local progress = '[' .. #commands - #to_process .. '/' .. #commands .. '] '

    vim.notify((messages.prefix or '[Running]') .. progress .. command)
    vim.fn.jobstart(command, {
      on_stdout = function(_, lines)
        for _, line in pairs(lines) do
          if line:len() > 1 then
            vim.notify(
              (messages.prefix or '[Running]')
                .. progress
                .. command
                .. ' | '
                .. line
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

return u
