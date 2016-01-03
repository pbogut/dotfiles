syntax on

set number

set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'tpope/vim-fugitive'

Plugin 'tpope/vim-git'

Plugin 'scrooloose/syntastic'

Plugin 'bling/vim-airline'

Plugin 'scrooloose/nerdtree'

Plugin 'ctrlpvim/ctrlp.vim'

Plugin 'nanotech/jellybeans.vim'

Bundle 'jistr/vim-nerdtree-tabs'

Plugin 'Shougo/unite.vim'

Plugin 'tyru/open-browser.vim'

Plugin 'lambdalisue/vim-gista'

Plugin 'Valloric/YouCompleteMe'

Plugin 'mkusher/padawan.vim'

Plugin 'tpope/vim-rails'

Plugin 'tpope/vim-obsession'

Plugin 'dhruvasagar/vim-prosession'

Plugin 'airblade/vim-gitgutter'

Plugin 'terryma/vim-multiple-cursors'

Plugin 'MarcWeber/vim-addon-mw-utils'

Plugin 'tomtom/tlib_vim'

Plugin 'garbas/vim-snipmate'

Plugin 'Raimondi/delimitMate'



" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" Show panel only if open without file
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
" Close if only panel left
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" ctr+n shortcut
let mapleader = ","
map <Leader>s :NERDTreeFocusToggle<cr>
map <Leader>t :NERDTreeTabsToggle<cr>
map <Leader>r :NERDTreeFind<cr>
map <Leader>n :bn!<cr>
map <Leader>p :bp!<cr>
map <Leader>l :bn!<cr>
map <Leader>h :bp!<cr>
map <Leader>k <C-W>k<C-W>_
map <Leader>j <C-W>j<C-W>_
nnoremap <leader>d "_d
vnoremap <leader>d "_d
nnoremap ; :
" air-line
set laststatus=2
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
" color scheme
colorscheme jellybeans
" Padawan
let g:ycm_semantic_triggers = {}
let g:ycm_semantic_triggers.php = ['->', '::', '(', 'use ', 'namespace ', '\']

" space instead of tab
filetype plugin indent on
" show existing tab with 4 spaces width
set tabstop=2
" when indenting with '>', use 4 spaces width
set shiftwidth=2
" On pressing tab, insert 4 spaces
set expandtab
" tab size for php and html
autocmd FileType html :setlocal tabstop=4 shiftwidth=4
autocmd FileType php :setlocal tabstop=4 shiftwidth=4
" line 80 limit
set colorcolumn=81
" multicoursor

" white characters
" toggle invisible characters
set invlist
set listchars=tab:▸\ ,eol:¬,trail:⋅,extends:❯,precedes:❮
" make the highlighting of tabs less annoying
highlight SpecialKey ctermbg=none 
set showbreak=↪
nmap <leader>l :set list!<cr>


