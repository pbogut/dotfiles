local u = require('utils')

vim.g.gitblame_message_template = '     <author> • <summary> • <date> [<sha>]'
vim.g.gitblame_date_format = '%d-%m-%Y %H:%M'
vim.g.gitblame_highlight_group = "GitBlame"


u.highlights({
  GitBlame = { 
    gui = 'none', guibg = vim.g.colors.base02, guifg = vim.g.colors.base01 
  }
})
