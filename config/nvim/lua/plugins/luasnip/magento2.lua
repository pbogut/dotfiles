local h = require('plugins.luasnip.helper')
local ls = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local i = ls.i
local s = ls.s
local d = ls.d
local sn = ls.sn

local ph = require('projector.templates.placeholders.magento2')

local snips = {
  Mod = s('Mod', {
    ls.f(function(_, _)
      return ph.module_name()
    end),
  }),
  mod =
  s('mod', {
    ls.f(function(_, _)
      return ph.module_name():lower()
    end),
  }),
}

ls.add_snippets('php', {
  snips.Mod,
  snips.mod,
}, { default_priority = 2000 })
ls.add_snippets('xml', {
  snips.Mod,
  snips.mod,
}, { default_priority = 2000 })
