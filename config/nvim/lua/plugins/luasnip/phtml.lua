local ls = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local i = ls.i
local s = ls.s
local f = ls.f

local visual = f(function(_, snip)
  return snip.env.TM_SELECTED_TEXT or {}
end)

ls.add_snippets('phtml', {
  ls.parser.parse_snippet('=', '<?php echo ${VISUAL}$0 ?>'),
  s(
    '?if',
    fmt(
      [[
        <?php if ({condition}): ?>
        	{visual}{done}
        <?php endif ?>
      ]],
      { condition = i(1), visual = visual, done = i(0) }
    )
  ),
  ls.parser.parse_snippet(
    '?for',
    [[
      <?php for (${1:$i = 0; $i++; $i < 0}): ?>
      ${VISUAL}$0
      <?php endfor ?>
    ]]
  ),
})
