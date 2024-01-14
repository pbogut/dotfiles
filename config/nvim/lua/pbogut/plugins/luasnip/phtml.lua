local ls = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local h = require('pbogut.plugins.luasnip.helper')
local i = ls.i
local s = ls.s
local f = ls.f

local function get_variables(default)
  local variables = require('pbogut.plugins.luasnip.treesitter').php.get_variables()
  if default then
    table.insert(variables, 1, ls.i(nil, default))
  end
  return ls.sn(nil, { ls.c(1, variables) })
end

ls.add_snippets('phtml', {
  ls.parser.parse_snippet('echo', '<?php echo $TM_SELECTED_TEXT$0 ?>'),
  ls.parser.parse_snippet('=', [[<?= $TM_SELECTED_TEXT$0 ?>]]),
  s(
    'if',
    fmt(
      [[
        <?php if ({condition}): ?>
        	{visual}{done}
        <?php endif ?>
      ]],
      { condition = i(1), visual = h.visual(), done = i(0) }
    )
  ),
  ls.parser.parse_snippet(
    'for',
    [[
      <?php for (${1:\$i} = 0; $1++; $1 ${2:< 10}): ?>
      $TM_SELECTED_TEXT$0
      <?php endfor ?>
    ]]
  ),
  s(
    'each',
    fmt(
      [[
        <?php foreach ({collection} as {key} => {value}): ?>
        	{visual}{done}
        <?php endforeach ?>
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
}, { default_priority = 2000 })
