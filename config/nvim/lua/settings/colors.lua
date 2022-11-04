-- run :luafile % - to highlight colors
local u = require('utils')
local g = vim.g
local fn = vim.fn
local cmd = vim.cmd

g.colors = {
  ad_dark1 = '#001c26',

  ad_info = '#a68f46',
  ad_hint = '#9eab7d',

  base03 = '#002b36',
  base02 = '#073642',
  base01 = '#586e75',
  base00 = '#657b83',
  base0 = '#839496',
  base1 = '#93a1a1',
  base2 = '#eee8d5',
  base3 = '#fdf6e3',
  yellow = '#af8700',
  orange = '#cb4b16',
  red = '#dc322f',
  magenta = '#d33682',
  violet = '#6c71c4',
  blue = '#268bd2',
  cyan = '#2aa198',
  green = '#5f8700',

  alt_base03 = '#1c1c1c',
  alt_base02 = '#262626',
  alt_base01 = '#4e4e4e',
  alt_base00 = '#585858',
  alt_base0 = '#808080',
  alt_base1 = '#8a8a8a',
  alt_base2 = '#d7d7af',
  alt_base3 = '#ffffd7',
  alt_orange = '#d75f00',
  alt_red = '#d70000',
  alt_magenta = '#af005f',
  alt_violet = '#5f5faf',
  alt_blue = '#0087ff',
  alt_cyan = '#00afaf',
  alt_green = '#859900',
}

u.highlights({
  ClTestAdDark1 = { guifg = g.colors.ad_dark1 },
  ClTestAdInfo = { guifg = g.colors.ad_info },
  ClTestAdHint = { guifg = g.colors.ad_hint },

  ClTestBase03 = { guifg = g.colors.base03 },
  ClTestBase02 = { guifg = g.colors.base02 },
  ClTestBase01 = { guifg = g.colors.base01 },
  ClTestBase00 = { guifg = g.colors.base00 },
  ClTestBase0 = { guifg = g.colors.base0 },
  ClTestBase1 = { guifg = g.colors.base1 },
  ClTestBase2 = { guifg = g.colors.base2 },
  ClTestBase3 = { guifg = g.colors.base3 },
  ClTestOrange = { guifg = g.colors.orange },
  ClTestRed = { guifg = g.colors.red },
  ClTestMagenta = { guifg = g.colors.magenta },
  ClTestViolet = { guifg = g.colors.violet },
  ClTestBlue = { guifg = g.colors.blue },
  ClTestCyan = { guifg = g.colors.cyan },
  ClTestYellow = { guifg = g.colors.yellow },
  ClTestGreen = { guifg = g.colors.green },

  ClTestAltBase03 = { guifg = g.colors.alt_base03 },
  ClTestAltBase02 = { guifg = g.colors.alt_base02 },
  ClTestAltBase01 = { guifg = g.colors.alt_base01 },
  ClTestAltBase00 = { guifg = g.colors.alt_base00 },
  ClTestAltBase0 = { guifg = g.colors.alt_base0 },
  ClTestAltBase1 = { guifg = g.colors.alt_base1 },
  ClTestAltBase2 = { guifg = g.colors.alt_base2 },
  ClTestAltBase3 = { guifg = g.colors.alt_base3 },
  ClTestAltOrange = { guifg = g.colors.alt_orange },
  ClTestAltRed = { guifg = g.colors.alt_red },
  ClTestAltMagenta = { guifg = g.colors.alt_magenta },
  ClTestAltViolet = { guifg = g.colors.alt_violet },
  ClTestAltBlue = { guifg = g.colors.alt_blue },
  ClTestAltCyan = { guifg = g.colors.alt_cyan },
  ClTestAltGreen = { guifg = g.colors.alt_green },
})

vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('x_colors', { clear = true }),
  pattern = 'colors.lua',
  callback = function()
    cmd.TSBufDisable('highlight')
    fn.matchadd('ClTestAdDark1', 'ClTestAdDark1\\>')
    fn.matchadd('ClTestAdInfo', 'ClTestAdInfo\\>')
    fn.matchadd('ClTestAdHint', 'ClTestAdHint\\>')
    fn.matchadd('ClTestBase03', 'ClTestBase03\\>')
    fn.matchadd('ClTestBase02', 'ClTestBase02\\>')
    fn.matchadd('ClTestBase01', 'ClTestBase01\\>')
    fn.matchadd('ClTestBase00', 'ClTestBase00\\>')
    fn.matchadd('ClTestBase0', 'ClTestBase0\\>')
    fn.matchadd('ClTestBase1', 'ClTestBase1\\>')
    fn.matchadd('ClTestBase2', 'ClTestBase2\\>')
    fn.matchadd('ClTestBase3', 'ClTestBase3\\>')
    fn.matchadd('ClTestOrange', 'ClTestOrange\\>')
    fn.matchadd('ClTestAltOrange', 'ClTestAltOrange\\>')
    fn.matchadd('ClTestRed', 'ClTestRed\\>')
    fn.matchadd('ClTestMagenta', 'ClTestMagenta\\>')
    fn.matchadd('ClTestViolet', 'ClTestViolet\\>')
    fn.matchadd('ClTestAltViolet', 'ClTestAltViolet\\>')
    fn.matchadd('ClTestBlue', 'ClTestBlue\\>')
    fn.matchadd('ClTestAltBlue', 'ClTestAltBlue\\>')
    fn.matchadd('ClTestCyan', 'ClTestCyan\\>')
    fn.matchadd('ClTestAltCyan', 'ClTestAltCyan\\>')
    fn.matchadd('ClTestYellow', 'ClTestYellow\\>')
    fn.matchadd('ClTestGreen', 'ClTestGreen\\>')
    fn.matchadd('ClTestAltGreen', 'ClTestAltGreen\\>')
    fn.matchadd('ClTestAltBase03', 'ClTestAltBase03\\>')
    fn.matchadd('ClTestAltBase02', 'ClTestAltBase02\\>')
    fn.matchadd('ClTestAltBase01', 'ClTestAltBase01\\>')
    fn.matchadd('ClTestAltBase00', 'ClTestAltBase00\\>')
    fn.matchadd('ClTestAltBase0', 'ClTestAltBase0\\>')
    fn.matchadd('ClTestAltBase1', 'ClTestAltBase1\\>')
    fn.matchadd('ClTestAltBase2', 'ClTestAltBase2\\>')
    fn.matchadd('ClTestAltBase3', 'ClTestAltBase3\\>')
    fn.matchadd('ClTestAltRed', 'ClTestAltRed\\>')
    fn.matchadd('ClTestAltMagenta', 'ClTestAltMagenta\\>')
  end,
})
