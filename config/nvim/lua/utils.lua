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

function u.call_command(no)
  command_callbacs[no]()
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
      definition = {definition}
    end
    for _, def in pairs(definition) do
      local callback = table.remove(def, #def)

      table.insert(def, 1, 'autocmd')
      table.insert(def, 2, event_type)
      local command = table.concat(def, ' ')
      if type(callback) == 'function' then
        table.insert(autocmd_callbacs, callback)
        callback = 'lua require("utils").call_autocmd(' .. #autocmd_callbacs  .. ')'
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
  local command = 'command! '
  if (opts.nargs) then
    command = command .. '-nargs=' .. opts.nargs .. ' '
  end
  if (opts.bang) then
    command = command .. '-bang '
  end
  command = command .. command_name .. ' '
  if type(action) == 'function' then
    table.insert(command_callbacs, action)
    action = 'lua require("utils").call_command(' .. #command_callbacs  .. ')'
  end
  command = command .. action
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
    local command = 'highlight ' .. group_name
    for key, value in pairs(definition) do
      command = command .. ' ' .. key .. '=' .. value
    end
    cmd(command)
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
    expr = false
  })
  if type(result) == 'function' then
    table.insert(mapping_callbacs, result)
    result = ':lua require("utils").call_mapping(' .. #mapping_callbacs  .. ')<cr>'
  end
  if opts.buffer then
    local buffer_nr = opts.buffer
    opts.buffer = nil
    api.nvim_buf_set_keymap(buffer_nr, mode, key, result, opts)
  else
    api.nvim_set_keymap(mode, key, result, opts)
  end

end

function u.buf_map(buffer_nr, mode, key, result, opts)
  opts.buffer = buffer_nr or 0
  u.map(mode, key, result, opts)
end

function u.pp(var)
  print(vim.inspect(var))
end

return u
