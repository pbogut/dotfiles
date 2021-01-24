local U = {}
local cmd = vim.cmd
local fn = vim.fn
local b = vim.b
local bo = vim.bo

Lua_augroups_callbacks = Lua_augroups_callbacks or {}

-- definitions = {
--   VimEnter = {
--     {"*", function() print('test') end };
--   }
-- }
function U.augroups(group_name, definitions)
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
        table.insert(Lua_augroups_callbacks, callback)
        callback = 'lua Lua_augroups_callbacks[' .. #Lua_augroups_callbacks .. ']()'
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
function U.set_indent(width, hardtab, force)
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

return U