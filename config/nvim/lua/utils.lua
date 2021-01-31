local u = {}
local cmd = vim.cmd
local fn = vim.fn
local b = vim.b
local bo = vim.bo
local api = vim.api

local autocmd_callbacs = {}

function u.call_autocmd(no)
  autocmd_callbacs[no]()
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
        callback = 'lua require("utils").call_autocmd(' .. #autocmd_callbacs  .. ')'
      end
      command = command .. ' ' .. callback
      cmd(command)
    end
  end
  cmd('augroup END')
end

-- Set indent for current buffer
-- @param width Width in characters
-- @param[opt=false] hardtab Use hard tab character
-- @param[opt=false] force   Force indent even if already set
function u.set_indent(width, hardtab, force)
  -- Skip if already set
  if not force and b.Set_indent_initiated then
    return
  end
  -- Skip if .editorconfig is available (@todo implement project root search)
  if not force and fn.filereadable('.editorconfig') > 0 then
    return
  end
  -- optional params
  hardtab = hardtab or false
  force = force or false
  b.Set_indent_initiated = true

  bo.tabstop = width
  bo.shiftwidth = width
  bo.expandtab = not hardtab
end

-- Set up highlight
-- @param groups { HlGroup = { guibg = '#123456', guifg='#654321' } }
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
-- @param groups { SignGroup = { text = 'X', texthl='#654321' } }
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
  local opts = vim.tbl_extend('keep', opts or {}, {
    noremap = true,
    silent = mode ~= 'c',
    expr = false
  })
  api.nvim_set_keymap(mode, key, result, opts)
end

function u.buf_map(buffer_nr, mode, key, result, opts)
  local opts = vim.tbl_extend('keep', opts or {}, {
    noremap = true,
    silent = mode ~= 'c',
    expr = false
  })
  api.nvim_buf_set_keymap(buffer_nr, mode, key, result, opts)
end

function u.pp(var)
  if type(var) == 'table' then
    io.write('{ ')
    for i, v in pairs(var) do
      io.write(i .. ' = ')
      io.write(u.pp(v))
      io.write('; ')
    end
    io.write('}')
  elseif type(var) == 'number' then
    io.write(var)
  elseif type(var) == 'string' then
    io.write('[[' .. var .. ']]')
  elseif type(var) == 'function' then
    io.write('function()')
  elseif type(var) == 'boolean' then
    if var then
      io.write('true')
    else
      io.write('false')
    end
  else
    io.write(type(var))
  end
end

return u
