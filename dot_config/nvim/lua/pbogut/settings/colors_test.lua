-- run :source % - to highlight colors
local u = require('pbogut.utils')
local fn = vim.fn
local cmd = vim.cmd

u.highlights({
  ClTestAdDark1 = { guifg = vim.c.ad_dark1 },
  ClTestAdDark2 = { guifg = vim.c.ad_dark2 },

  ClTestAdInfo = { guifg = vim.c.ad_info },
  ClTestAdHint = { guifg = vim.c.ad_hint },
  ClTestAdInlay = { guifg = vim.c.ad_inlay },

  ClTestBase03 = { guifg = vim.c.base03 },
  ClTestBase02 = { guifg = vim.c.base02 },
  ClTestBase01 = { guifg = vim.c.base01 },
  ClTestBase00 = { guifg = vim.c.base00 },
  ClTestBase0 = { guifg = vim.c.base0 },
  ClTestBase1 = { guifg = vim.c.base1 },
  ClTestBase2 = { guifg = vim.c.base2 },
  ClTestBase3 = { guifg = vim.c.base3 },
  ClTestOrange = { guifg = vim.c.orange },
  ClTestRed = { guifg = vim.c.red },
  ClTestMagenta = { guifg = vim.c.magenta },
  ClTestViolet = { guifg = vim.c.violet },
  ClTestBlue = { guifg = vim.c.blue },
  ClTestCyan = { guifg = vim.c.cyan },
  ClTestYellow = { guifg = vim.c.yellow },
  ClTestGreen = { guifg = vim.c.green },

  ClTestAltBase03 = { guifg = vim.c.alt_base03 },
  ClTestAltBase02 = { guifg = vim.c.alt_base02 },
  ClTestAltBase01 = { guifg = vim.c.alt_base01 },
  ClTestAltBase00 = { guifg = vim.c.alt_base00 },
  ClTestAltBase0 = { guifg = vim.c.alt_base0 },
  ClTestAltBase1 = { guifg = vim.c.alt_base1 },
  ClTestAltBase2 = { guifg = vim.c.alt_base2 },
  ClTestAltBase3 = { guifg = vim.c.alt_base3 },
  ClTestAltOrange = { guifg = vim.c.alt_orange },
  ClTestAltRed = { guifg = vim.c.alt_red },
  ClTestAltMagenta = { guifg = vim.c.alt_magenta },
  ClTestAltViolet = { guifg = vim.c.alt_violet },
  ClTestAltBlue = { guifg = vim.c.alt_blue },
  ClTestAltCyan = { guifg = vim.c.alt_cyan },
  ClTestAltGreen = { guifg = vim.c.alt_green },

})

cmd.TSBufDisable('highlight')
fn.matchadd('ClTestAdDark1', 'ClTestAdDark1\\>')
fn.matchadd('ClTestAdDark2', 'ClTestAdDark2\\>')
fn.matchadd('ClTestAdInfo', 'ClTestAdInfo\\>')
fn.matchadd('ClTestAdHint', 'ClTestAdHint\\>')
fn.matchadd('ClTestAdInlay', 'ClTestAdInlay\\>')
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
