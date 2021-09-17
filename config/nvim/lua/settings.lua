require('settings.indents')
require('settings.title')
require('settings.terminal')
require('settings.icons')
require('settings.highlights')

local cmd = vim.cmd
local o = vim.opt
local wo = vim.wo
local bo = vim.bo

cmd('syntax on')
cmd("filetype plugin indent on")
cmd('set fillchars=fold:\\ ,vert:\\│')
cmd('set shortmess+=c')
cmd('set runtimepath+=~/.vim')
cmd('silent! colorscheme solarized')

o.list = true
o.updatetime = 100
o.signcolumn = 'yes'
o.showmode = false
o.ttimeoutlen = 0   -- eliminate esc timeout
o.report = 0
o.hlsearch = false
o.cursorline = true
o.cursorcolumn = true
o.completeopt = 'menuone,noselect,noinsert'
o.cmdheight = 2
o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.scrolloff = 3
o.number = true
o.relativenumber = true
o.lazyredraw = true
o.wildmenu = true
o.showcmd = true
o.undodir = os.getenv("HOME") .. '/.vim/undofiles//'
o.undofile = true
o.listchars = 'tab:▸,eol:¬,trail:⋅,extends:❯,precedes:❮,nbsp:%'
o.showbreak = '↪'
o.history = 10000
o.undolevels = 1000
o.wildignore = '*.swp,*.bak,*.pyc,*.class'
o.hidden = true
o.clipboard = 'unnamedplus'

o.colorcolumn = '81' -- line 80 limit 81 is colored
o.foldmethod = 'manual'
o.foldnestmax = 10
o.foldlevelstart = 99

o.termguicolors = true
o.background = 'dark'
o.guicursor = 'n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor'
o.shell='/bin/bash'

o.inccommand = 'split'
-- rip grep as default grep program
o.grepprg = 'rg --vimgrep --no-heading'
-- bo.grepprg = 'rg --vimgrep --no-heading'
o.grepformat = '%f:%l:%c:%m,%f:%l:%m'

-- set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175
