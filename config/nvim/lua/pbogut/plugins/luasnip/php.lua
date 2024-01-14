local h = require('pbogut.plugins.luasnip.helper')
local ls = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local ph_php = require('projector.templates.placeholders.php')
local i = ls.i
local t = ls.t
local f = ls.f
local s = ls.s
local d = ls.d
local sn = ls.sn

local function get_variables(default)
  local variables = require('pbogut.plugins.luasnip.treesitter').php.get_variables()
  if default then
    table.insert(variables, 1, ls.i(nil, default))
  end
  return ls.sn(nil, { ls.c(1, variables) })
end

local function get_next_variable(_, _)
  local line = h.get_relative_line(1)
  if line:match('.-(%$[%w%_]+).*') then
    local var_name = line:gsub('.-(%$[%w%_]+).*', '%1')
    return sn(nil, { i(1, var_name) })
  else
    return sn(nil, { i(1, '$variable') })
  end
end

local function get_classes(default)
  local classes = require('pbogut.plugins.luasnip.treesitter').php.get_classes()
  if default then
    table.insert(classes, 1, ls.i(nil, default))
  end
  return classes
end

local function maybe_get_objmgr_class(_, _)
  local line = h.get_relative_line(1)
  local pattern = [[.*%-%>get%(['"](.+)['"]%).*]]
  if line:match(pattern) then
    local class_name = line:gsub([[.*%-%>get%(['"](.+)['"]%).*]], '%1')
    return sn(nil, { i(1, '\\' .. class_name) })
  else
    return sn(nil, { ls.c(1, get_classes('Type')) })
  end
end

ls.add_snippets('php', {
  s('php', {
    t('<?php '),
    h.visual(),
    i(0),
    t(' ?>'),
  }),
  s('ns', {
    t('namespace '),
    f(ph_php.namespace, {}),
    t(';'),
  }),
  s(
    'var',
    fmt('/** @var {class} {variable} */{done}', {
      class = d(1, maybe_get_objmgr_class),
      variable = d(2, get_next_variable),
      done = i(0),
    })
  ),
  s(
    'each',
    fmt(
      [[
        foreach ({collection} as {key} => {value}) {{
        	{visual}{done}
        }}
      ]],
      {
        collection = ls.d(1, function()
          return get_variables('$collection')
        end),
        key = i(2, '$key'),
        value = i(3, '$value'),
        visual = h.visual(),
        done = i(0),
      }
    )
  ),
  s(
    'funu',
    fmt(
      [[
        function ({args}) use({use}) {{
        	{visual}{done}
        }}
      ]],
      {
        args = i(1, ''),
        use = i(2, ''),
        visual = h.visual(),
        done = i(0),
      }
    )
  ),
  s(
    'fun',
    fmt(
      [[
        function ({args}) {{
        	{visual}{done}
        }}
      ]],
      {
        args = i(1, ''),
        visual = h.visual(),
        done = i(0),
      }
    )
  ),
}, { default_priority = 2000 })
