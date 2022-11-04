local u = require('utils')
require('settings.colors')

local c = vim.g.colors

local function highlights()
  u.highlights({
    Folded = { term = 'NONE', cterm = 'NONE', gui = 'NONE' },
    VertSplit = { guibg = '#073642', guifg = 'fg' },
    WinSeparator = { guibg = 'none', guifg = 'fg' },
    NonText = { gui = 'none', guifg = '#586e75' },
    SpecialKey = { gui = 'none', guifg = '#586e75' },
    Whitespace = { gui = 'none', guifg = '#586e75' },

    MyTodo = { gui = 'bold', guifg = '#d33682' },
    MyFixme = { gui = 'bold', guifg = '#d33682' },
    MyDebug = { gui = 'bold', guifg = '#dc322f' },

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

    ['@function'] = { guifg = c.base1 },
    ['@method'] = { guifg = c.base1 },

    ['@property'] = { guifg = c.blue },

    ['@keyword'] = { guifg = c.alt_green }, -- public, function, class, extends, $, as
    ['@keyword.function'] = { guifg = c.orange },
    ['@symbol'] = { guifg = c.violet, gui = 'italic' },

    ['@todo'] = { link = 'MyTodo' },
    ['@debug'] = { link = 'MyDebug' },

    -- TreeSitter
    -- ["@constant.macro"] = { guifg = c.orange },
    -- ["@string"] = { guifg = c.orange },
    -- ["@string.regex"] = { guifg = c.orange },
    -- ["@string.escape"] = { guifg = c.orange },
    -- ["@string.special"] = { guifg = c.orange },
    -- ["@character"] = { guifg = c.orange },
    -- ["@character.special"] = { guifg = c.orange },
    -- ["@method.call"] = { guifg = c.red },
    -- ["@function.macro"] = { guifg = c.red },
    -- ["@function.call"] = { guifg = c.red },
    -- ["@parameter"] = { guifg = c.red },
    -- ["@field"] = { guifg = c.red },
    -- ["@parameter.reference"] = { guifg = c.red },
    -- ["@annotation"] = { guifg = c.red },
    -- ["@attribute"] = { guifg = c.red },
    -- ["@include"] = { guifg = c.red },
    -- ["@conditional"] = { guifg = c.red },
    -- ["@repeat"] = { guifg = c.red },
    -- ["@label"] = { guifg = c.red },
    -- ["@tag"] = { guifg = c.red },
    -- ["@tag.attribute"] = { guifg = c.red },
    -- ["@operator"] = { guifg = c.red },
    -- ["@keyword.operator"] = { guifg = c.red },
    -- ["@keyword.return"] = { guifg = c.red },
    -- ["@comment"] = {},
    -- ["@define"] = {},
    -- ["@error"] = {},
    -- ["@exception"] = {},
    -- ["@include"] = {},
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

    -- Context
    TSContext = { guibg = c.base02 },
    TreesitterContext = { link = 'TSContext' },

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

    -- Gitsigns
    GitSignsAdd = { link = 'DiffAdd' },
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
