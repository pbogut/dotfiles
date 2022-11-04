local ls = require('luasnip')
local i = ls.i
local t = ls.t
local s = ls.s

ls.add_snippets('js', {
  s('fn', {
    t('function() {'),
    i(1),
    t('}'),
    i(0),
  }),
}, { default_priority = 2000 })
