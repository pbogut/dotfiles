local u = require('pbogut.utils')

local function highlights()
  local c = require('pbogut.settings.themes.tokyonight-night.colors')
  u.highlights({
    NonAscii = { gui = 'undercurl', guisp = 'red', guibg = c.ad_dark2 },

    Normal = { guifg = c.base3 },
    Visual = { guibg = c.blue },

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
    ['@function.builtin'] = { guifg = c.base3, gui = 'none' },
    ['@variable.builtin'] = { guifg = c.magenta }, -- $this/parent/static
    ['@constructor'] = { guifg = c.base3, gui = 'italic' },
    ['@namespace'] = { gui = 'italic' },

    ['@variable'] = { guifg = c.base0 }, -- $variable, function $param
    ['@constant'] = { guifg = c.violet },

    ['@number'] = { guifg = c.yellow },
    ['@float'] = { guifg = c.yellow },
    ['@boolean'] = { guifg = c.yellow },

    ['@function'] = { gui = 'italic', guifg = c.base3 },
    ['@method'] = { gui = 'italic', guifg = c.base3 },

    ['@method.call'] = { guifg = c.base3 },
    ['@function.call'] = { guifg = c.base3 },

    ['@property'] = { guifg = c.base0 },

    ['@keyword'] = { guifg = c.alt_green }, -- public, function, class, extends, $, as
    ['@keyword.function'] = { guifg = c.orange },
    ['@symbol'] = { guifg = c.violet, gui = 'italic' },

    ['@todo'] = { link = 'MyTodo' },
    ['@debug'] = { link = 'MyDebug' },

    -- lsp tokens
    ['@lsp.type.function'] = { guifg = c.base3 },
    ['@lsp.type.method'] = { guifg = c.base3 },
    ['@lsp.type.property'] = { guifg = c.base0 },
    ['@lsp.type.variable'] = { guifg = c.base0 },
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
    -- ['@comment'] = { guifg = c.base2 },
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

    Function = { guifg = c.base3 },
    String = { guifg = c.cyan },
    Comment = { guifg = c.base2 },

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
    CmpItemAbbr = { gui = 'none', guifg = c.base3, guibg = c.ad_dark1 },
    CmpItemKind = { gui = 'italic', guifg = c.base3, guibg = c.ad_dark1 },
    CmpItemMenu = { gui = 'none', guifg = c.base3, guibg = c.ad_dark1 },
    CmpItemAbbrMatch = { gui = 'bold', guifg = c.base3, guibg = c.ad_dark1 },
    CmpItemAbbrMatchFuzzy = { gui = 'italic', guifg = c.base3, guibg = c.ad_dark1 },
    CmpItemAbbrDeprecated = { gui = 'none', guifg = c.base00, guibg = c.ad_dark1 },

    -- broken after introducing different highlight for different kind
    CmpItemKindDefault = { gui = 'italic', guifg = c.base02, guibg = c.ad_dark1 },

    CursorIM = { gui = 'none', cterm = 'none', guifg = c.base3, guibg = c.base02 },
    TermCursor = { gui = 'none', cterm = 'none', guifg = c.base3, guibg = c.base02 },
    lCursor = { gui = 'none', cterm = 'none', guifg = c.base3, guibg = c.base02 },

    FloatBorder = { guifg = c.base3, guibg = c.ad_dark1 },
    FloatTitle = { guifg = c.base3, guibg = c.ad_dark1 },
    FloatNormal = { guifg = c.base3, guibg = c.ad_dark1 },

    SignColumn = { guifg = c.base01, guibg = c.sign_col_bg },
    LineNr = { guifg = c.base01, guibg = c.sign_col_bg },
    CursorLineNr = { guifg = c.base3, guibg = c.sign_col_bg },

    CursorLine = { guibg = c.ad_dark0 },
    ColorColumn = { guibg = c.ad_dark0 },

    TelescopeNormal = { guifg = c.base3, guibg = c.ad_dark1 },
    -- TelescopeSelection = { guifg = c.base03, guibg = c.blue },
    TelescopePromptBorder = { guifg = c.yellow },
    FlashLabel = { guifg = c.base03, guibg = c.violet },

    GitSignsAddLn = { guifg = c.green },
    GitSignsDeleteLn = { guifg = c.red },
    GitSignsChangeLn = { guifg = c.yellow },

    -- Gitsigns
    GitSignsAdd = { guifg = c.green, guibg = c.sign_col_bg },
    GitSignsDelete = { guifg = c.red, guibg = c.sign_col_bg },
    GitSignsChange = { guifg = c.yellow, guibg = c.sign_col_bg },
  })
end

local group = vim.api.nvim_create_augroup('x_highlights', { clear = true })

vim.api.nvim_create_autocmd('VimEnter', {
  group = group,
  callback = function()
    highlights()
  end,
})

highlights()
