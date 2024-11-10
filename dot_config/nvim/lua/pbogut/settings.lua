require('pbogut.settings.indents')
require('pbogut.settings.title')
require('pbogut.settings.terminal')
require('pbogut.settings.icons')
require('pbogut.settings.colors')
require('pbogut.settings.highlights')

local o = vim.opt

vim.g.matchparen_timeout = 2
vim.g.matchparen_insert_timeout = 2

vim.cmd.filetype({ args = { 'plugin', 'indent', 'off' } })
vim.cmd.colorscheme('solarized')

o.fillchars = { fold = ' ', vert = '│' }
o.shortmess:append('c')
o.syntax = 'off'
o.list = true
o.updatetime = 100
o.signcolumn = 'yes'
o.showmode = false
o.ttimeoutlen = 0 -- eliminate esc timeout
o.timeoutlen = 1000
o.report = 0
o.hlsearch = false
o.cursorline = true
o.cursorcolumn = false
o.completeopt = { 'menu', 'menuone', 'noinsert', 'noselect' }
o.cmdheight = 1
o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.scrolloff = 8
o.number = true
o.wrap = false
o.relativenumber = true
o.lazyredraw = true
o.wildmenu = true
o.showcmd = true
o.swapfile = false
o.dir = os.getenv('HOME') .. '/.vim/swapfiles//'
o.undodir = os.getenv('HOME') .. '/.vim/undofiles//'
o.undofile = true
o.listchars = {
  tab = '╶─╴',
  eol = '↩',
  trail = '⋅',
  nbsp = '·',
  extends = '',
  precedes = '',
}
o.showbreak = '↪'
o.history = 10000
o.undolevels = 1000
o.wildignore = { '*.swp', '*.bak', '*.pyc', '*.class' }
o.hidden = true
o.clipboard = 'unnamedplus'
o.laststatus = 3
o.colorcolumn = '81' -- line 80 limit 81 is colored
o.foldmethod = 'manual'
o.foldnestmax = 10
o.foldlevelstart = 99
o.termguicolors = true
o.background = 'dark'
o.shell = '/bin/bash'
o.inccommand = 'nosplit'
o.grepprg = 'rg --vimgrep --no-heading'
o.grepformat = '%f:%l:%c:%m,%f:%l:%m'
