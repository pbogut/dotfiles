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

return u
