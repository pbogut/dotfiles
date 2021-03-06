local u = require('utils')
require('settings.colors')

local fn = vim.fn
local g = vim.g
local c = g.colors

local function highlights()
  u.highlights({
    Folded = { term = 'NONE', cterm = 'NONE',  gui = 'NONE' },
    VertSplit = {guibg = '#073642', guifg = 'fg'},
    NonText = {gui = 'none', guifg = '#586e75'},
    MyTodo = {gui = 'bold', guifg = '#d33682'},
    MyFixme = {gui = 'bold', guifg = '#d33682'},
    MyDebug = {gui = 'bold', guifg = '#dc322f'},

    IndentBlanklineChar = {gui = 'none', guifg = g.colors.base02},

    TSPunctBracket      = { guifg = c.red },
    TSPunctDelimiter  = { guifg = c.alt_base0 },
    TSPunctSpecial     = { guifg = c.alt_base0 },
    TSTagDelimiter    = { guifg = c.alt_base0 },

    TSConstBuiltin  = { guifg = g.colors.cyan }, -- true/false/null
    TSFuncBuiltin        = { guifg = g.colors.alt_magenta },
    TSVariableBuiltin    = { guifg = g.colors.magenta }, -- $this/parent/static
    TSConstructor        = { guifg = g.colors.base1 }, -- class name, namespace, const name

    TSVariable    = { guifg = g.colors.blue }, -- $variable, function $param
    -- TSConstant           = { guifg = c.orange },
    -- TSConstMacro         = { guifg = c.orange },
    -- TSString             = { guifg = c.orange },
    -- TSStringRegex        = { guifg = c.orange },
    -- TSLiteral            = { guifg = c.orange },
    -- TSStringEscape       = { guifg = c.orange },
    -- TSCharacter          = { guifg = c.orange },
    -- TSNumber             = { guifg = c.orange },
    -- TSFloat              = { guifg = c.orange },
    -- TSBoolean            = { guifg = c.orange },

    TSFunction            = { guifg = c.base1 },
    TSMethod             = { guifg = c.base1 },
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

    TSKeyword           = { guifg = g.colors.alt_green }, -- public, function, class, extends, $, as
    TSKeywordFunction   = { guifg = g.colors.orange },
  })
end

u.augroup('x_highlights', {
  VimEnter = { '*', function()
    highlights()
  end}
})

highlights()
