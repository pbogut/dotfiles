local ph_php = require('projector.templates.placeholders.php')
local ph_m2 = require('projector.templates.placeholders.magento2')
local h = require('pbogut.plugins.luasnip.helper')
local ls = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local s = ls.s

local ph = require('projector.templates.placeholders.magento2')

local snips = {
  Mod = s('Mod', {
    ls.f(function(_, _)
      return ph.module_name()
    end),
  }),
  mod = s('mod', {
    ls.f(function(_, _)
      return ph.module_name():lower()
    end),
  }),
}

ls.add_snippets('phtml', {
  snips.Mod,
  snips.mod,
  ls.parser.parse_snippet('=ne', [[<?= /* @noEscape */ $TM_SELECTED_TEXT$0 ?>]]),
  s(
    'block',
    fmt(
      [[
        /**
         * @var {block} $block
         * @var \Magento\Framework\Escaper $escaper
         */
      ]],
      {
        block = h.df(1, function()
          return '\\' .. ph_php.namespace() .. '\\Block\\' .. ph_m2.block_class()
        end),
      }
    )
  ),
}, { default_priority = 2000 })
ls.add_snippets('php', {
  snips.Mod,
  snips.mod,
}, { default_priority = 2000 })
ls.add_snippets('xml', {
  snips.Mod,
  snips.mod,
}, { default_priority = 2000 })
ls.add_snippets('js', {
  snips.Mod,
  snips.mod,
}, { default_priority = 2000 })
