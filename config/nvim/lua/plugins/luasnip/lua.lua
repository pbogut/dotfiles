local ls = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local i = ls.i
local s = ls.s
local t = ls.t

ls.add_snippets('lua', {
  s(' end', {
    t({ '', '\t' }),
    i(0),
    t({ '', 'end' }),
  }),
  s(' end,', {
    t({ '', '\t' }),
    i(0),
    t({ '', 'end,' }),
  }),
  s(' end)', {
    t({ '', '\t' }),
    i(0),
    t({ '', 'end)' }),
  }),
}, { default_priority = 2000 })
