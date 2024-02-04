local ls = require('luasnip')
local i = ls.i
local t = ls.t
local s = ls.s
local c = ls.choice_node

ls.add_snippets('go', {
  s('er', {
    t({ 'if err != nil {', '\t' }),
    c(1, {
      t('fmt.Println(err)'),
      t('return err'),
      t('io.WriteString(w, err)'),
      i(nil, ''),
    }),
    t({ '', '}' }),
    i(0),
  }),
}, { default_priority = 2000 })
