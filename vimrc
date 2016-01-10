syntax on

set nocompatible              " be iMproved, required
filetype off                  " required

set timeoutlen=1000 ttimeoutlen=0   " eliminate esc timeout

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'tpope/vim-fugitive'

Plugin 'tpope/vim-git'

Plugin 'tpope/vim-commentary'

Plugin 'scrooloose/syntastic'

Plugin 'bling/vim-airline'

Plugin 'edkolev/tmuxline.vim'

Plugin 'scrooloose/nerdtree'

Plugin 'scrooloose/nerdcommenter'

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

" Plugin 'tomtom/tcomment_vim'

"Plugin 'garbas/vim-snipmate'

Plugin 'Raimondi/delimitMate'

Plugin 'szw/vim-tags'

"Plugin 'tpope/vim-dispatch'
Plugin 'Smeagol07/vim-dispatch' " panel size

Plugin 'mileszs/ack.vim'

Plugin 'maxbrunsfeld/vim-yankstack'

Plugin 'gioele/vim-autoswap'

Plugin 'ntpeters/vim-better-whitespace'

Plugin 'sirver/ultisnips'

Plugin 'honza/vim-snippets'

Plugin 'majutsushi/tagbar'

Plugin 'mattn/emmet-vim'

Plugin 'christoomey/vim-tmux-navigator'

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

" yankstack mappings
call yankstack#setup()

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
map <Leader>l :bn!<cr>
map <Leader>h :bp!<cr>
map <Leader>q :b#<bar>bd#<bar>b<cr>
map <Leader>x :bd<cr>
map <Leader>X :bd!<cr>
map <Leader>k <C-W>k<C-W>_
map <Leader>j <C-W>j<C-W>_
nnoremap <leader>d "_d
vnoremap <leader>d "_d
nnoremap ; :
map <Leader>gp <Plug>GitGutterPreviewHunk
map <Leader>gr <Plug>GitGutterRevertHunk
map <Leader>gstage <Plug>GitGutterStageHunk
" Insert mode quick commands
inoremap <Leader><Leader>i <Esc>I
inoremap <Leader><Leader>I <Esc>I
inoremap <Leader><Leader>a <Esc>A
inoremap <Leader><Leader>A <Esc>A
inoremap II <Esc>I
inoremap AA <Esc>A
" inoremap OO <Esc>O
" inoremap CC <Esc>C
" inoremap SS <Esc>S
" inoremap DD <Esc>dd
" inoremap UU <Esc>u
" get rid of bad habbits :)
" Easy version for now
inoremap <Up> <nop>
inoremap <Down> <nop>
inoremap <Left> <nop>
inoremap <Right> <nop>
noremap <Up> <nop>
noremap <Down> <nop>
noremap <Left> <nop>
noremap <Right> <nop>
" CtrlP
let g:ctrlp_cmd = 'CtrlPMixed'
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
autocmd FileType xml :setlocal tabstop=4 shiftwidth=4
autocmd FileType sh :setlocal tabstop=4 shiftwidth=4
" line 80 limit
set colorcolumn=81
" line numering
set number
set relativenumber
map <Leader>m :set relativenumber!<cr>
map <Leader>w :set nowrap!<cr>
" white characters
" toggle invisible characters
set invlist
set listchars=tab:▸\ ,eol:¬,trail:⋅,extends:❯,precedes:❮
" make the highlighting of tabs less annoying
highlight SpecialKey ctermbg=none
set showbreak=↪
" nmap <leader>l :set list!<cr>

set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo
set wildignore=*.swp,*.bak,*.pyc,*.class

" delimitMate
let g:delimitMate_jump_expansion = 1
let g:delimitMate_expand_cr = 2
let g:delimitMate_expand_space = 1
" move text blocks up and down
" gnome-terminal, guake
" nnoremap j :m .+1<CR>==
" nnoremap k :m .-2<CR>==
" inoremap k <Esc>:m .-2<CR>==gi
" inoremap j <Esc>:m .+1<CR>==gi
vnoremap j :m '>+1<CR>gv=gv
vnoremap k :m '<-2<CR>gv=gv
" vim way, not working in some terminals
" nnoremap <A-j> :m .+1<CR>==
" nnoremap <A-k> :m .-2<CR>==
" inoremap <A-j> <Esc>:m .+1<CR>==gi
" inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv
" scroll
set scrolloff=3
" php linter
"let g:syntastic_quiet_messages = { "type": "style" }
let g:syntastic_php_checkers = ['php', 'phpmd', 'phpcs']
" vim tags
let g:vim_tags_use_language_field = 1
let g:vim_tags_use_vim_dispatch = 1
" ctrlp
let g:ctrlp_extensions = ['tag', 'mixed']
let g:ctrlp_user_command = {
   \ 'types': {
      \ 1: ['.git', 'cd %s && git ls-files'],
      \ 2: ['.hg', 'hg --cwd %s locate -I .'],
      \ },
    \ 'fallback': 'find %s -type f'
    \ }
" async ack
let g:ack_use_dispatch = 1
" yankstack
let g:yankstack_map_keys = 0
nmap <leader>p <Plug>yankstack_substitute_older_paste
nmap <leader>P <Plug>yankstack_substitute_newer_paste
" despatch hax to not cover half screen
let g:dispatch_quickfix_height = 10
let g:dispatch_tmux_height = 1
" autoswap tmux support
let g:autoswap_detect_tmux = 1
" snipMate
" inoremap <CR> <Plug>snipMateNextOrTrigger
" ultisnip
function! g:UltiSnips_Complete()
  call UltiSnips#ExpandSnippetOrJump()
  if g:ulti_expand_or_jump_res == 0
    if pumvisible()
      return "\<C-N>"
    else
      return "\<TAB>"
    endif
  endif

  return ""
endfunction

function! g:UltiSnips_Reverse()
  call UltiSnips#JumpBackwards()
  if g:ulti_jump_backwards_res == 0
    return "\<C-P>"
  endif

  return ""
endfunction

if !exists("g:UltiSnipsJumpForwardTrigger")
  let g:UltiSnipsJumpForwardTrigger = "<tab>"
endif

if !exists("g:UltiSnipsJumpBackwardTrigger")
  let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
endif


autocmd BufEnter * exec "inoremap <silent> " . g:UltiSnipsJumpBackwardTrigger . " <C-R>=g:UltiSnips_Reverse()<cr>"
autocmd BufEnter * exec "inoremap <silent> " . g:UltiSnipsExpandTrigger . " <C-R>=g:UltiSnips_Complete()<cr>"
let g:UltiSnipsJumpForwardTrigger="<cr>"
let g:UltiSnipsListSnippets="<c-e>"
" this mapping Enter key to <C-y> to chose the current highlight item
" and close the selection list, same as other IDEs.
" CONFLICT with some plugins like tpope/Endwise
" inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

let g:UltiSnipsExpandTrigger ="<C-Space>"
" If you prefer the Omni-Completion tip window to close when a selection is
" made, these lines close it on movement in insert mode or when leaving
" insert mode
autocmd CompleteDone * pclose
" custom commands
" close all buffers but current
command! BCloseOther execute "%bd | e#"
command! BCloseOtherForce execute "%bd! | e#"

" set a directory to store the undo history
set undodir=~/.vim/undofiles//
set undofile
" set a directory for swp files
set dir=~/.vim/swapfiles//
" set backup disr
set backupdir=~/.vim/backupfiles//
set backup


" copy to system clipboard
" alpha stage
function! g:ClipCopy()
  let selection = @"
  silent echo system('echo ' . shellescape(join(split(selection,'\n'),'\n')). '|xclip -i -selection c')
endfunction

