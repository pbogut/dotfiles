local cmd = vim.cmd
local o = vim.o
local wo = vim.wo
local bo = vim.bo

cmd('syntax on')
cmd("filetype plugin indent on")
cmd('set invlist')
cmd('set fillchars=fold:\\ ,vert:\\│')
cmd('set shortmess+=c')
cmd('set runtimepath+=~/.vim')

o.signcolumn = 'yes'
wo.signcolumn = 'yes'
o.showmode = false
o.ttimeoutlen = 0   -- eliminate esc timeout
o.report = 0
o.hlsearch = false
o.cursorline = true
wo.cursorline = true
o.cursorcolumn = true
wo.cursorcolumn = true
o.completeopt = 'menuone,noselect,noinsert'
o.cmdheight = 2
o.tabstop = 2
bo.tabstop = 2
o.shiftwidth = 2
bo.shiftwidth = 2
o.expandtab = true
bo.expandtab = true
o.scrolloff = 3
wo.scrolloff = 3
o.number = true
wo.number = true
o.relativenumber = true
wo.relativenumber = true
o.lazyredraw = true
o.wildmenu = true
o.showcmd = true
o.undodir = os.getenv("HOME") .. '/.vim/undofiles//'
o.undofile = true
o.listchars = 'tab:▸ ,eol:¬,trail:⋅,extends:❯,precedes:❮,nbsp:%'
o.showbreak = '↪'
o.history = 10000
o.undolevels = 1000
o.wildignore = '*.swp,*.bak,*.pyc,*.class'
o.hidden = true
o.clipboard = 'unnamedplus'

o.colorcolumn = '81' -- line 80 limit 81 is colored
wo.colorcolumn = '81' -- line 80 limit 81 is colored
o.foldmethod = 'manual'
wo.foldmethod = 'manual'
o.foldnestmax = 10
wo.foldnestmax = 10
o.foldlevelstart = 99

o.termguicolors = true
o.background = 'dark'
o.guicursor = 'n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor'
o.shell='/bin/bash'

o.inccommand = 'split'
-- rip grep as default grep program
o.grepprg = 'rg --vimgrep --no-heading'
bo.grepprg = 'rg --vimgrep --no-heading'
o.grepformat = '%f:%l:%c:%m,%f:%l:%m'
