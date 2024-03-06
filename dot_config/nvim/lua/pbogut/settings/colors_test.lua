-- run :source % - to highlight colors
local colors = require('pbogut.settings.colors')
local u = require('pbogut.utils')
local fn = vim.fn
local cmd = vim.cmd

u.highlights({
  ClTestAdDark1 = { guifg = colors.ad_dark1 },
  ClTestAdDark2 = { guifg = colors.ad_dark2 },
  ClTestAdInfo = { guifg = colors.ad_info },
  ClTestAdHint = { guifg = colors.ad_hint },

  ClTestBase03 = { guifg = colors.base03 },
  ClTestBase02 = { guifg = colors.base02 },
  ClTestBase01 = { guifg = colors.base01 },
  ClTestBase00 = { guifg = colors.base00 },
  ClTestBase0 = { guifg = colors.base0 },
  ClTestBase1 = { guifg = colors.base1 },
  ClTestBase2 = { guifg = colors.base2 },
  ClTestBase3 = { guifg = colors.base3 },
  ClTestOrange = { guifg = colors.orange },
  ClTestRed = { guifg = colors.red },
  ClTestMagenta = { guifg = colors.magenta },
  ClTestViolet = { guifg = colors.violet },
  ClTestBlue = { guifg = colors.blue },
  ClTestCyan = { guifg = colors.cyan },
  ClTestYellow = { guifg = colors.yellow },
  ClTestGreen = { guifg = colors.green },

  ClTestAltBase03 = { guifg = colors.alt_base03 },
  ClTestAltBase02 = { guifg = colors.alt_base02 },
  ClTestAltBase01 = { guifg = colors.alt_base01 },
  ClTestAltBase00 = { guifg = colors.alt_base00 },
  ClTestAltBase0 = { guifg = colors.alt_base0 },
  ClTestAltBase1 = { guifg = colors.alt_base1 },
  ClTestAltBase2 = { guifg = colors.alt_base2 },
  ClTestAltBase3 = { guifg = colors.alt_base3 },
  ClTestAltOrange = { guifg = colors.alt_orange },
  ClTestAltRed = { guifg = colors.alt_red },
  ClTestAltMagenta = { guifg = colors.alt_magenta },
  ClTestAltViolet = { guifg = colors.alt_violet },
  ClTestAltBlue = { guifg = colors.alt_blue },
  ClTestAltCyan = { guifg = colors.alt_cyan },
  ClTestAltGreen = { guifg = colors.alt_green },
})

cmd.TSBufDisable('highlight')
fn.matchadd('ClTestAdDark1', 'ClTestAdDark1\\>')
fn.matchadd('ClTestAdDark2', 'ClTestAdDark2\\>')
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
