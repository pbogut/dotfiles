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

    TSPunctBracket = { guifg = c.red },
    TSPunctDelimiter = { guifg = c.alt_base0 },
    TSPunctSpecial = { guifg = c.alt_base0 },
    TSTagDelimiter = { guifg = c.alt_base0 },

    TSConstBuiltin = { guifg = c.yellow }, -- true/false/null
    TSFuncBuiltin = { guifg = c.base1, gui = 'none' },
    TSVariableBuiltin = { guifg = c.magenta }, -- $this/parent/static
    TSConstructor = { guifg = c.base1, gui = 'italic' }, -- class name, namespace, const name

    TSVariable = { guifg = c.blue }, -- $variable, function $param
    TSConstant = { guifg = c.violet },
    -- TSConstMacro         = { guifg = c.orange },
    -- TSString             = { guifg = c.orange },
    -- TSStringRegex        = { guifg = c.orange },
    -- TSLiteral            = { guifg = c.orange },
    -- TSStringEscape       = { guifg = c.orange },
    -- TSCharacter          = { guifg = c.orange },
    TSNumber = { guifg = c.yellow },
    TSFloat = { guifg = c.yellow },
    TSBoolean = { guifg = c.yellow },

    TSFunction = { guifg = c.base1 },
    TSMethod = { guifg = c.base1 },
    -- TSFuncMacro = { guifg = c.red },
    -- TSParameter = { guifg = c.red },
    -- TSField = { guifg = c.red },
    TSProperty = { guifg = c.blue },
    -- TSParameterReference = { guifg = c.red },

    -- TSAnnotation = { guifg = c.red },
    -- TSAttribute = { guifg = c.red },
    -- TSNamespace = { guifg = c.red },
    -- TSInclude = { guifg = c.red },

    -- TSConditional = { guifg = c.red },
    -- TSRepeat = { guifg = c.red },
    -- TSLabel = { guifg = c.red },
    -- TSTag = { guifg = c.red },
    -- TSOperator = { guifg = c.red },
    -- TSKeywordOperator = { guifg = c.red },

    TSKeyword = { guifg = c.alt_green }, -- public, function, class, extends, $, as
    TSKeywordFunction = { guifg = c.orange },

    -- MatchParen ctermbg=blue guibg=lightblue cterm=italic gui=italic
    MatchParen = { guifg = c.orange, guibg = c.base02 },
    NormalFloat = { guibg = c.ad_dark1 },

    -- Context
    TSContext = { guibg = c.base02 },
    TreesitterContext = { link = 'TSContext' },

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

--[[ vim.api.nvim_create_autocmd('BufWinEnter', { ]]
--[[   group = group, ]]
--[[   callback = function() ]]
--[[     vim.fn.matchadd('MyTodo', 'TODO') ]]
--[[     vim.fn.matchadd('MyFixme', 'FIXME') ]]
--[[     vim.fn.matchadd('MyFixme', 'FIX') ]]
--[[     vim.fn.matchadd('MyDebug', 'DEBUG') ]]
--[[   end, ]]
--[[ TODO 'TODO' ]]

vim.api.nvim_create_autocmd('VimEnter', {
  group = group,
  callback = function()
    highlights()
  end,
})

highlights()
