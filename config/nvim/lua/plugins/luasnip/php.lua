local h = require('plugins.luasnip.helper')
local ls = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local i = ls.i
local s = ls.s
local d = ls.d
local sn = ls.sn

local function get_next_variable(_, _)
  local line = h.get_relative_line(1)
  if line:match('.-(%$[%w%_]+).*') then
    local var_name = line:gsub('.-(%$[%w%_]+).*', '%1')
    return sn(nil, { i(1, var_name) })
  else
    return sn(nil, { i(1, '$variable') })
  end
end

local function maybe_get_objmgr_class(_, _)
  local line = h.get_relative_line(1)
  local pattern = [[.*%-%>get%(['"](.+)['"]%).*]]
  if line:match(pattern) then
    local class_name = line:gsub([[.*%-%>get%(['"](.+)['"]%).*]], '%1')
    return sn(nil, { i(1, '\\' .. class_name) })
  else
    return sn(nil, { ls.c(1, require('plugins.luasnip.treesitter').php.get_classes()) })
  end
end

ls.add_snippets('php', {
  s(
    'var',
    fmt('/** @var {class} {variable} */{done}', {
      class = d(1, maybe_get_objmgr_class),
      variable = d(2, get_next_variable),
      done = i(0),
    })
  ),
}, { default_priority = 2000 })
