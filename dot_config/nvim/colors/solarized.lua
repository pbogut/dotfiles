vim.g.colors_name = 'solarized'

local colors = {
  ad_dark1 = '#00222b',
  ad_dark2 = '#001c26',

  ad_info = '#a68f46',
  ad_hint = '#9eab7d',
  ad_inlay = '#305677',

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
colors.sign_col_bg = colors.ad_dark1
vim.c = colors

vim.cmd([[
" Colorscheme initialization "{{{
" ---------------------------------------------------------------------
hi clear
if exists("syntax_on")
  syntax reset
endif

"}}}
" GUI & CSApprox hexadecimal palettes"{{{
" ---------------------------------------------------------------------
    let s:vmode       = "gui"
    let s:base03      = "#002b36"
    let s:base02      = "#073642"
    let s:base01      = "#586e75"
    let s:base00      = "#657b83"
    let s:base0       = "#839496"
    let s:base1       = "#93a1a1"
    let s:base2       = "#eee8d5"
    let s:base3       = "#fdf6e3"
    let s:yellow      = "#b58900"
    let s:orange      = "#cb4b16"
    let s:red         = "#dc322f"
    let s:magenta     = "#d33682"
    let s:violet      = "#6c71c4"
    let s:blue        = "#268bd2"
    let s:cyan        = "#2aa198"
    "let s:green       = "#859900" "original
    let s:green       = "#719e07" "experimental
"}}}
" Formatting options and null values for passthrough effect "{{{
" ---------------------------------------------------------------------
    let s:none            = "NONE"
    let s:none            = "NONE"
    let s:t_none          = "NONE"
    let s:n               = "NONE"
    let s:c               = ",undercurl"
    let s:r               = ",reverse"
    let s:s               = ",standout"
    let s:ou              = ""
    let s:ob              = ""
"}}}
" Background value based on termtrans setting "{{{
" ---------------------------------------------------------------------
    let s:back        = s:base03
" Overrides dependent on user specified values and environment "{{{
" ---------------------------------------------------------------------
    let s:b           = ",bold"
    let s:bb          = ""
    let s:u           = ",underline"
    let s:i           = ",italic"
"}}}
" Highlighting primitives"{{{
" ---------------------------------------------------------------------
exe "let s:bg_none      = ' ".s:vmode."bg=".s:none   ."'"
exe "let s:bg_back      = ' ".s:vmode."bg=".s:back   ."'"
exe "let s:bg_base03    = ' ".s:vmode."bg=".s:base03 ."'"
exe "let s:bg_base02    = ' ".s:vmode."bg=".s:base02 ."'"
exe "let s:bg_base01    = ' ".s:vmode."bg=".s:base01 ."'"
exe "let s:bg_base00    = ' ".s:vmode."bg=".s:base00 ."'"
exe "let s:bg_base0     = ' ".s:vmode."bg=".s:base0  ."'"
exe "let s:bg_base1     = ' ".s:vmode."bg=".s:base1  ."'"
exe "let s:bg_base2     = ' ".s:vmode."bg=".s:base2  ."'"
exe "let s:bg_base3     = ' ".s:vmode."bg=".s:base3  ."'"
exe "let s:bg_green     = ' ".s:vmode."bg=".s:green  ."'"
exe "let s:bg_yellow    = ' ".s:vmode."bg=".s:yellow ."'"
exe "let s:bg_orange    = ' ".s:vmode."bg=".s:orange ."'"
exe "let s:bg_red       = ' ".s:vmode."bg=".s:red    ."'"
exe "let s:bg_magenta   = ' ".s:vmode."bg=".s:magenta."'"
exe "let s:bg_violet    = ' ".s:vmode."bg=".s:violet ."'"
exe "let s:bg_blue      = ' ".s:vmode."bg=".s:blue   ."'"
exe "let s:bg_cyan      = ' ".s:vmode."bg=".s:cyan   ."'"

exe "let s:fg_none      = ' ".s:vmode."fg=".s:none   ."'"
exe "let s:fg_back      = ' ".s:vmode."fg=".s:back   ."'"
exe "let s:fg_base03    = ' ".s:vmode."fg=".s:base03 ."'"
exe "let s:fg_base02    = ' ".s:vmode."fg=".s:base02 ."'"
exe "let s:fg_base01    = ' ".s:vmode."fg=".s:base01 ."'"
exe "let s:fg_base00    = ' ".s:vmode."fg=".s:base00 ."'"
exe "let s:fg_base0     = ' ".s:vmode."fg=".s:base0  ."'"
exe "let s:fg_base1     = ' ".s:vmode."fg=".s:base1  ."'"
exe "let s:fg_base2     = ' ".s:vmode."fg=".s:base2  ."'"
exe "let s:fg_base3     = ' ".s:vmode."fg=".s:base3  ."'"
exe "let s:fg_green     = ' ".s:vmode."fg=".s:green  ."'"
exe "let s:fg_yellow    = ' ".s:vmode."fg=".s:yellow ."'"
exe "let s:fg_orange    = ' ".s:vmode."fg=".s:orange ."'"
exe "let s:fg_red       = ' ".s:vmode."fg=".s:red    ."'"
exe "let s:fg_magenta   = ' ".s:vmode."fg=".s:magenta."'"
exe "let s:fg_violet    = ' ".s:vmode."fg=".s:violet ."'"
exe "let s:fg_blue      = ' ".s:vmode."fg=".s:blue   ."'"
exe "let s:fg_cyan      = ' ".s:vmode."fg=".s:cyan   ."'"

exe "let s:fmt_none     = ' ".s:vmode."=NONE".          " term=NONE".    "'"
exe "let s:fmt_bold     = ' ".s:vmode."=NONE".s:b.      " term=NONE".s:b."'"
exe "let s:fmt_bldi     = ' ".s:vmode."=NONE".s:b.      " term=NONE".s:b."'"
exe "let s:fmt_undr     = ' ".s:vmode."=NONE".s:u.      " term=NONE".s:u."'"
exe "let s:fmt_undb     = ' ".s:vmode."=NONE".s:u.s:b.  " term=NONE".s:u.s:b."'"
exe "let s:fmt_undi     = ' ".s:vmode."=NONE".s:u.      " term=NONE".s:u."'"
exe "let s:fmt_uopt     = ' ".s:vmode."=NONE".s:ou.     " term=NONE".s:ou."'"
exe "let s:fmt_curl     = ' ".s:vmode."=NONE".s:c.      " term=NONE".s:c."'"
exe "let s:fmt_ital     = ' ".s:vmode."=NONE".s:i.      " term=NONE".s:i."'"
exe "let s:fmt_stnd     = ' ".s:vmode."=NONE".s:s.      " term=NONE".s:s."'"
exe "let s:fmt_revr     = ' ".s:vmode."=NONE".s:r.      " term=NONE".s:r."'"
exe "let s:fmt_revb     = ' ".s:vmode."=NONE".s:r.s:b.  " term=NONE".s:r.s:b."'"
" revbb (reverse bold for bright colors) is only set to actual bold in low
" color terminals (t_co=8, such as OS X Terminal.app) and should only be used
" with colors 8-15.
exe "let s:fmt_revbb    = ' ".s:vmode."=NONE".s:r.s:bb.   " term=NONE".s:r.s:bb."'"
exe "let s:fmt_revbbu   = ' ".s:vmode."=NONE".s:r.s:bb.s:u." term=NONE".s:r.s:bb.s:u."'"

exe "let s:sp_none      = ' guisp=".s:none   ."'"
exe "let s:sp_back      = ' guisp=".s:back   ."'"
exe "let s:sp_base03    = ' guisp=".s:base03 ."'"
exe "let s:sp_base02    = ' guisp=".s:base02 ."'"
exe "let s:sp_base01    = ' guisp=".s:base01 ."'"
exe "let s:sp_base00    = ' guisp=".s:base00 ."'"
exe "let s:sp_base0     = ' guisp=".s:base0  ."'"
exe "let s:sp_base1     = ' guisp=".s:base1  ."'"
exe "let s:sp_base2     = ' guisp=".s:base2  ."'"
exe "let s:sp_base3     = ' guisp=".s:base3  ."'"
exe "let s:sp_green     = ' guisp=".s:green  ."'"
exe "let s:sp_yellow    = ' guisp=".s:yellow ."'"
exe "let s:sp_orange    = ' guisp=".s:orange ."'"
exe "let s:sp_red       = ' guisp=".s:red    ."'"
exe "let s:sp_magenta   = ' guisp=".s:magenta."'"
exe "let s:sp_violet    = ' guisp=".s:violet ."'"
exe "let s:sp_blue      = ' guisp=".s:blue   ."'"
exe "let s:sp_cyan      = ' guisp=".s:cyan   ."'"
"}}}
" Basic highlighting"{{{
" ---------------------------------------------------------------------
exe "hi! Normal"         .s:fmt_none   .s:fg_base0  .s:bg_back
exe "hi! Comment"        .s:fmt_ital   .s:fg_base01 .s:bg_none
exe "hi! Constant"       .s:fmt_none   .s:fg_cyan   .s:bg_none
exe "hi! Identifier"     .s:fmt_none   .s:fg_blue   .s:bg_none
exe "hi! Statement"      .s:fmt_none   .s:fg_green  .s:bg_none
exe "hi! PreProc"        .s:fmt_none   .s:fg_orange .s:bg_none
exe "hi! Type"           .s:fmt_none   .s:fg_yellow .s:bg_none
exe "hi! Special"        .s:fmt_none   .s:fg_red    .s:bg_none
exe "hi! Underlined"     .s:fmt_none   .s:fg_violet .s:bg_none
exe "hi! Ignore"         .s:fmt_none   .s:fg_none   .s:bg_none
exe "hi! Error"          .s:fmt_bold   .s:fg_red    .s:bg_none
exe "hi! Todo"           .s:fmt_bold   .s:fg_magenta.s:bg_none
"}}}
" Extended highlighting "{{{
" ---------------------------------------------------------------------
exe "hi! SpecialKey" .s:fmt_bold   .s:fg_base00 .s:bg_base02
exe "hi! NonText"    .s:fmt_bold   .s:fg_base00 .s:bg_none
exe "hi! StatusLine"     .s:fmt_none   .s:fg_base1  .s:bg_base02 .s:fmt_revbb
exe "hi! StatusLineNC"   .s:fmt_none   .s:fg_base00 .s:bg_base02 .s:fmt_revbb
exe "hi! Visual"         .s:fmt_none   .s:fg_base01 .s:bg_base03 .s:fmt_revbb
exe "hi! Directory"      .s:fmt_none   .s:fg_blue   .s:bg_none
exe "hi! ErrorMsg"       .s:fmt_revr   .s:fg_red    .s:bg_none
exe "hi! IncSearch"      .s:fmt_stnd   .s:fg_orange .s:bg_none
exe "hi! Search"         .s:fmt_revr   .s:fg_yellow .s:bg_none
exe "hi! MoreMsg"        .s:fmt_none   .s:fg_blue   .s:bg_none
exe "hi! ModeMsg"        .s:fmt_none   .s:fg_blue   .s:bg_none
exe "hi! LineNr"         .s:fmt_none   .s:fg_base01 .s:bg_base02
exe "hi! Question"       .s:fmt_bold   .s:fg_cyan   .s:bg_none
exe "hi! VertSplit"  .s:fmt_none   .s:fg_base00 .s:bg_base00
exe "hi! Title"          .s:fmt_bold   .s:fg_orange .s:bg_none
exe "hi! VisualNOS"      .s:fmt_stnd   .s:fg_none   .s:bg_base02 .s:fmt_revbb
exe "hi! WarningMsg"     .s:fmt_bold   .s:fg_red    .s:bg_none
exe "hi! WildMenu"       .s:fmt_none   .s:fg_base2  .s:bg_base02 .s:fmt_revbb
exe "hi! Folded"         .s:fmt_undb   .s:fg_base0  .s:bg_base02  .s:sp_base03
exe "hi! FoldColumn"     .s:fmt_none   .s:fg_base0  .s:bg_base02
exe "hi! DiffAdd"        .s:fmt_bold   .s:fg_green  .s:bg_base02 .s:sp_green
exe "hi! DiffChange"     .s:fmt_bold   .s:fg_yellow .s:bg_base02 .s:sp_yellow
exe "hi! DiffDelete"     .s:fmt_bold   .s:fg_red    .s:bg_base02
exe "hi! DiffText"       .s:fmt_bold   .s:fg_blue   .s:bg_base02 .s:sp_blue
hi! link SignColumn LineNr
exe "hi! Conceal"        .s:fmt_none   .s:fg_blue   .s:bg_none
exe "hi! SpellBad"       .s:fmt_curl   .s:fg_none   .s:bg_none    .s:sp_red
exe "hi! SpellCap"       .s:fmt_curl   .s:fg_none   .s:bg_none    .s:sp_violet
exe "hi! SpellRare"      .s:fmt_curl   .s:fg_none   .s:bg_none    .s:sp_cyan
exe "hi! SpellLocal"     .s:fmt_curl   .s:fg_none   .s:bg_none    .s:sp_yellow
exe "hi! Pmenu"          .s:fmt_none   .s:fg_base0  .s:bg_base02  .s:fmt_revbb
exe "hi! PmenuSel"       .s:fmt_none   .s:fg_base01 .s:bg_base2   .s:fmt_revbb
exe "hi! PmenuSbar"      .s:fmt_none   .s:fg_base2  .s:bg_base0   .s:fmt_revbb
exe "hi! PmenuThumb"     .s:fmt_none   .s:fg_base0  .s:bg_base03  .s:fmt_revbb
exe "hi! TabLine"        .s:fmt_undr   .s:fg_base0  .s:bg_base02  .s:sp_base0
exe "hi! TabLineFill"    .s:fmt_undr   .s:fg_base0  .s:bg_base02  .s:sp_base0
exe "hi! TabLineSel"     .s:fmt_undr   .s:fg_base01 .s:bg_base2   .s:sp_base0  .s:fmt_revbbu
exe "hi! CursorColumn"   .s:fmt_none   .s:fg_none   .s:bg_base02
exe "hi! CursorLine"     .s:fmt_uopt   .s:fg_none   .s:bg_base02  .s:sp_base1
exe "hi! CursorLineNr"   .s:fmt_uopt   .s:fg_none   .s:bg_base02
exe "hi! ColorColumn"    .s:fmt_none   .s:fg_none   .s:bg_base02
exe "hi! Cursor"         .s:fmt_none   .s:fg_base03 .s:bg_base0
hi! link lCursor Cursor
exe "hi! MatchParen"     .s:fmt_bold   .s:fg_red    .s:bg_base01

"}}}
" vim syntax highlighting "{{{
" ---------------------------------------------------------------------
hi! link vimVar Identifier
hi! link vimFunc Function
hi! link vimUserFunc Function
hi! link helpSpecial Special
hi! link vimSet Normal
hi! link vimSetEqual Normal
exe "hi! vimCommentString"  .s:fmt_none    .s:fg_violet .s:bg_none
exe "hi! vimCommand"        .s:fmt_none    .s:fg_yellow .s:bg_none
exe "hi! vimCmdSep"         .s:fmt_bold    .s:fg_blue   .s:bg_none
exe "hi! helpExample"       .s:fmt_none    .s:fg_base1  .s:bg_none
exe "hi! helpOption"        .s:fmt_none    .s:fg_cyan   .s:bg_none
exe "hi! helpNote"          .s:fmt_none    .s:fg_magenta.s:bg_none
exe "hi! helpVim"           .s:fmt_none    .s:fg_magenta.s:bg_none
exe "hi! helpHyperTextJump" .s:fmt_undr    .s:fg_blue   .s:bg_none
exe "hi! helpHyperTextEntry".s:fmt_none    .s:fg_green  .s:bg_none
exe "hi! vimIsCommand"      .s:fmt_none    .s:fg_base00 .s:bg_none
exe "hi! vimSynMtchOpt"     .s:fmt_none    .s:fg_yellow .s:bg_none
exe "hi! vimSynType"        .s:fmt_none    .s:fg_cyan   .s:bg_none
exe "hi! vimHiLink"         .s:fmt_none    .s:fg_blue   .s:bg_none
exe "hi! vimHiGroup"        .s:fmt_none    .s:fg_blue   .s:bg_none
exe "hi! vimGroup"          .s:fmt_undb    .s:fg_blue   .s:bg_none
 "}}}
]])

local c = vim.c
local groups = {
  NonAscii = { gui = 'undercurl', guisp = 'red', guibg = c.ad_dark2 },

  Folded = { term = 'NONE', cterm = 'NONE', gui = 'NONE' },
  VertSplit = { guibg = c.base02, guifg = 'fg' },
  WinSeparator = { guibg = 'none', guifg = 'fg' },
  NonText = { gui = 'none', guifg = c.ad_inlay },
  SpecialKey = { gui = 'none', guifg = c.ad_inlay },
  Whitespace = { gui = 'none', guifg = c.ad_inlay },

  MyTodo = { gui = 'bold', guifg = c.magenta },
  MyFixme = { gui = 'bold', guifg = c.magenta },
  MyDebug = { gui = 'bold', guifg = c.red },

  IndentBlanklineChar = { gui = 'none', guifg = c.base02 },

  ['@punctuation.bracket'] = { guifg = c.red },
  ['@punctuation.delimiter'] = { guifg = c.alt_base0 },
  ['@punctuation.special'] = { guifg = c.alt_base0 },
  ['@tag.delimiter'] = { guifg = c.alt_base0 },

  ['@constant.builtin'] = { guifg = c.yellow }, -- true/false/null
  ['@function.builtin'] = { guifg = c.base1, gui = 'none' },
  ['@variable.builtin'] = { guifg = c.magenta }, -- $this/parent/static
  ['@constructor'] = { guifg = c.base1, gui = 'italic' },
  ['@namespace'] = { gui = 'italic' },

  ['@variable'] = { guifg = c.blue }, -- $variable, function $param
  ['@constant'] = { guifg = c.violet },

  ['@number'] = { guifg = c.yellow },
  ['@float'] = { guifg = c.yellow },
  ['@boolean'] = { guifg = c.yellow },

  ['@function'] = { gui = 'italic', guifg = c.base1 },
  ['@method'] = { gui = 'italic', guifg = c.base1 },

  ['@method.call'] = { guifg = c.base1 },
  ['@function.call'] = { guifg = c.base1 },

  ['@property'] = { guifg = c.blue },

  ['@keyword'] = { guifg = c.alt_green }, -- public, function, class, extends, $, as
  ['@keyword.function'] = { guifg = c.orange },
  ['@symbol'] = { guifg = c.violet, gui = 'italic' },

  ['@todo'] = { link = 'MyTodo' },
  ['@debug'] = { link = 'MyDebug' },

  -- lsp tokens
  ['@lsp.type.function'] = { guifg = c.base1 },
  ['@lsp.type.method'] = { guifg = c.base1 },
  ['@lsp.type.property'] = { guifg = c.blue },
  ['@lsp.type.variable'] = { guifg = c.blue },
  -- ['@lsp.type.decorator'] = { guifg = c.red },
  -- ['@lsp.mod.deprecated']= { guifg = c.red },
  -- ['@lsp.typemod.function.async']= { guifg = c.red },

  -- Inlay Hints
  LspInlayHint = {
    guifg = c.ad_inlay,
    guibg = c.base03,
    gui = 'italic',
  },

  -- TreeSitter
  -- ["@constant.macro"] = { guifg = c.orange },
  ['@string'] = { guifg = c.cyan },
  -- ["@string.regex"] = { guifg = c.orange },
  -- ["@string.escape"] = { guifg = c.orange },
  -- ["@string.special"] = { guifg = c.orange },
  -- ["@character"] = { guifg = c.orange },
  -- ["@character.special"] = { guifg = c.orange },
  -- ["@function.macro"] = { guifg = c.red },
  -- ["@parameter"] = { guifg = c.red },
  -- ["@field"] = { guifg = c.red },
  -- ["@parameter.reference"] = { guifg = c.red },
  -- ["@annotation"] = { guifg = c.red },
  -- ["@attribute"] = { guifg = c.red },
  ['@include'] = { guifg = c.orange },
  ['@conditional'] = { guifg = c.green },
  ['@repeat'] = { guifg = c.green },
  -- ["@label"] = { guifg = c.red },
  -- ["@tag"] = { guifg = c.red },
  -- ["@tag.attribute"] = { guifg = c.red },
  ['@operator'] = { guifg = c.alt_green },
  ['@keyword.operator'] = { guifg = c.green },
  -- ["@keyword.return"] = { guifg = c.red },
  -- ["@comment"] = {},
  -- ["@define"] = {},
  -- ["@error"] = {},
  -- ["@exception"] = {},
  -- ["@none"] = {},
  -- ["@preproc"] = {},
  -- ["@symbol"] = {},
  -- ["@text"] = {},
  -- ["@text.strong"] = {},
  -- ["@text.emphasis"] = {},
  -- ["@text.underline"] = {},
  -- ["@text.strike"] = {},
  -- ["@text.title"] = {},
  -- ["@text.literal"] = {},
  -- ["@text.uri"] = {},
  -- ["@text.math"] = {},
  -- ["@text.reference"] = {},
  -- ["@text.environment"] = {},
  -- ["@text.environment.name"] = {},
  -- ["@text.note"] = {},
  -- ["@text.warning"] = {},
  -- ["@text.danger"] = {},
  -- ['@type'] = {},
  ['@typeme'] = { guifg = c.red },
  -- ["@type.builtin"] = {},
  -- ["@type.qualifier"] = {},
  -- ["@type.definition"] = {},

  -- Kurwa wie

  ['Function'] = { guifg = c.base1 },
  ['String'] = { guifg = c.cyan },
  -- ['String'] = { link = '@string' },

  -- Context
  TSContext = { guibg = c.ad_dark1 },
  TreesitterContext = { link = 'TSContext' },
  TreesitterContextLineNumber = { link = 'TSContext' },

  -- MatchParen ctermbg=blue guibg=lightblue cterm=italic gui=italic
  MatchParen = { guifg = c.orange, guibg = c.base02 },
  NormalFloat = { guibg = c.ad_dark1 },

  -- rrethy/vim-illuminate
  IlluminatedWordText = { gui = 'none', guibg = c.base02 },
  IlluminatedWordRead = { gui = 'none', guibg = c.base02 },
  IlluminatedWordWrite = { gui = 'none', guibg = c.base02 },

  -- Pmenu
  Pmenu = { gui = 'none', guibg = c.ad_dark1 },

  -- cmp
  CmpItemAbbr = { gui = 'none', guifg = c.base1, guibg = c.ad_dark1 },
  CmpItemKind = { gui = 'italic', guifg = c.base0, guibg = c.ad_dark1 },
  CmpItemMenu = { gui = 'none', guifg = c.base0, guibg = c.ad_dark1 },
  CmpItemAbbrMatch = { gui = 'bold', guifg = c.base1, guibg = c.ad_dark1 },
  CmpItemAbbrMatchFuzzy = { gui = 'italic', guifg = c.base1, guibg = c.ad_dark1 },
  CmpItemAbbrDeprecated = { gui = 'none', guifg = c.base00, guibg = c.ad_dark1 },

  -- broken after introducing different highlight for different kind
  CmpItemKindDefault = { gui = 'italic', guifg = c.base02, guibg = c.ad_dark1 },

  CursorIM = { gui = 'none', cterm = 'none', guifg = c.base1, guibg = c.base02 },
  TermCursor = { gui = 'none', cterm = 'none', guifg = c.base1, guibg = c.base02 },
  lCursor = { gui = 'none', cterm = 'none', guifg = c.base1, guibg = c.base02 },

  FloatBorder = { guifg = c.base1, guibg = c.ad_dark1 },
  FloatTitle = { guifg = c.base1, guibg = c.ad_dark1 },
  FloatNormal = { guifg = c.base1, guibg = c.ad_dark1 },

  SignColumn = { guifg = c.base01, guibg = c.sign_col_bg },
  LineNr = { guifg = c.base01, guibg = c.sign_col_bg },
  CursorLineNr = { guifg = c.base1, guibg = c.sign_col_bg },

  TelescopeNormal = { guifg = c.base1, guibg = c.ad_dark1 },
  FlashLabel = { guifg = c.base03, guibg = c.violet },

  GitSignsAddLn = { guifg = c.green },
  GitSignsDeleteLn = { guifg = c.red },
  GitSignsChangeLn = { guifg = c.yellow },

  -- Gitsigns
  GitSignsAdd = { guifg = c.green, guibg = c.sign_col_bg },
  GitSignsDelete = { guifg = c.red, guibg = c.sign_col_bg },
  GitSignsChange = { guifg = c.yellow, guibg = c.sign_col_bg },
}
local u = require('pbogut.utils')
u.highlights(groups)
-- for group, hl in pairs(groups) do
--     vim.api.nvim_set_hl(0, group, hl)
-- end
vim.h.load_theme_plugins('solarized')
