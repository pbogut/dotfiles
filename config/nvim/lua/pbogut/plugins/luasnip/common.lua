local h = require('pbogut.plugins.luasnip.helper')
local ls = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local s = ls.s
local f = ls.f
local t = ls.t
local i = ls.i

ls.add_snippets('all', {
  ls.parser.parse_snippet({ trig = '""', wordTrig = false }, '"$TM_SELECTED_TEXT$1"$0'),
  ls.parser.parse_snippet({ trig = "''", wordTrig = false }, "'$TM_SELECTED_TEXT$1'$0"),
  ls.parser.parse_snippet({ trig = '"', wordTrig = false }, '"$TM_SELECTED_TEXT$1"$0'),
  ls.parser.parse_snippet({ trig = "'", wordTrig = false }, "'$TM_SELECTED_TEXT$1'$0"),
  ls.parser.parse_snippet({ trig = '(', wordTrig = false }, '($TM_SELECTED_TEXT$1)$0'),
  ls.parser.parse_snippet({ trig = '{', wordTrig = false }, '{$TM_SELECTED_TEXT$1}$0'),
  ls.parser.parse_snippet({ trig = '[', wordTrig = false }, '[$TM_SELECTED_TEXT$1]$0'),
  ls.parser.parse_snippet({ trig = '(;', wordTrig = false }, '($TM_SELECTED_TEXT$1);$0'),
  ls.parser.parse_snippet({ trig = '{;', wordTrig = false }, '{$TM_SELECTED_TEXT$1};$0'),
  ls.parser.parse_snippet({ trig = '[;', wordTrig = false }, '[$TM_SELECTED_TEXT$1];$0'),
  ls.parser.parse_snippet({ trig = '()', wordTrig = false }, '(\n\t$TM_SELECTED_TEXT$1\n)$0'),
  ls.parser.parse_snippet({ trig = '{}', wordTrig = false }, '{\n\t$TM_SELECTED_TEXT$1\n}$0'),
  ls.parser.parse_snippet({ trig = '[]', wordTrig = false }, '[\n\t$TM_SELECTED_TEXT$1\n]$0'),
  ls.parser.parse_snippet({ trig = '();', wordTrig = false }, '(\n\t$TM_SELECTED_TEXT$1\n);$0'),
  ls.parser.parse_snippet({ trig = '{};', wordTrig = false }, '{\n\t$TM_SELECTED_TEXT$1\n};$0'),
  ls.parser.parse_snippet({ trig = '[];', wordTrig = false }, '[\n\t$TM_SELECTED_TEXT$1\n];$0'),
  ls.parser.parse_snippet({ trig = '{},', wordTrig = false }, '{\n\t$TM_SELECTED_TEXT$1\n},$0'),
  ls.parser.parse_snippet({ trig = '[],', wordTrig = false }, '[\n\t$TM_SELECTED_TEXT$1\n],$0'),
  ls.parser.parse_snippet({ trig = '(),', wordTrig = false }, '(\n\t$TM_SELECTED_TEXT$1\n),$0'),
  ls.parser.parse_snippet({ trig = '{})', wordTrig = false }, '{\n\t$TM_SELECTED_TEXT$1\n})$0'),
  ls.parser.parse_snippet({ trig = '[])', wordTrig = false }, '[\n\t$TM_SELECTED_TEXT$1\n])$0'),
  ls.parser.parse_snippet({ trig = '{});', wordTrig = false }, '{\n\t$TM_SELECTED_TEXT$1\n});$0'),
  ls.parser.parse_snippet({ trig = '[]);', wordTrig = false }, '[\n\t$TM_SELECTED_TEXT$1\n]);$0'),
  ls.parser.parse_snippet({ trig = '[]);', wordTrig = false }, '[\n\t$TM_SELECTED_TEXT$1\n]);$0'),
  -- base name
  s(
    'bn',
    f(function()
      return vim.fn.expand('%:t:r')
    end)
  ),
  -- m-dash
  ls.parser.parse_snippet({ trig = '--', wordTrig = false }, '—$0'),
  -- placeholder form projector
  s(
    { trig = '%[%[(.*)%]%]', wordTrig = false, regTrig = true },
    fmt('{expand}{done}', {
      expand = ls.f(function(_, snip)
        local v = require('projector.templates').process_placeholder(snip.captures[1])
        return v
      end),
      done = i(0),
    })
  ),
  s(
    { trig = 't' },
    fmt('{todo}{input}{done}', {
      todo = ls.f(function(_, _)
        local str = require('ts_context_commentstring.internal').calculate_commentstring({
          key = '__default',
          location = require('ts_context_commentstring.utils').get_cursor_location(),
        })
        if str == nil then
          str = require('Comment.ft').lang(vim.o.ft)[1]
        end
        if str == nil then
          str = vim.bo.commentstring
        end
        return str:gsub('%%s', ' TODO: ')
      end),
      input = i(1),
      done = i(0),
    })
  ),
  s('fix', {
    ls.d(1, function(_, snip)
      return h.wrap_in_comment({ t('FIXME: '), i(1) })
    end),
    i(0),
  }),
  s('todo', {
    ls.d(1, function()
      return h.wrap_in_comment({ t('TODO: '), i(1) })
    end),
    i(0),
  }),
})
