local ls = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local h = require('pbogut.plugins.luasnip.helper')
local s = ls.s
local i = ls.i

local htmlsnippets = {
  s('=', fmt([[<%= {visual}{done} %>]], { visual = h.visual(), done = i(0) })),
}

ls.add_snippets('elixir', htmlsnippets)
ls.add_snippets('eelixir', htmlsnippets)
ls.add_snippets('heex', htmlsnippets)
