local u = require('utils')

local fn = vim.fn

local function highlights()
  u.highlights({
    Folded = { term = 'NONE', cterm = 'NONE',  gui = 'NONE' },
    VertSplit = {guibg = '#073642', guifg = 'fg'},
    NonText = {gui = 'none', guifg = '#586e75'},
    MyTodo = {gui = 'bold', guifg = '#d33682'},
    MyFixme = {gui = 'bold', guifg = '#d33682'},
    MyDebug = {gui = 'bold', guifg = '#dc322f'},
  })
end

u.augroup('x_highlights', {
  VimEnter = { '*', function()
    highlights()
  end}
})

highlights()
