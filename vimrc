syntax on

set nocompatible              " be iMproved, required
filetype off                  " required

set timeoutlen=500 ttimeoutlen=0   " eliminate esc timeout
set report=0
set nohlsearch
set mouse= "disable mouse support

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
Plugin 'tpope/vim-rvm'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-obsession'
" Plugin 'tpope/vim-dispatch'
Plugin 'pbogut/vim-dispatch' " panel size
Plugin 'terryma/vim-expand-region'
Plugin 'scrooloose/syntastic'
Plugin 'scrooloose/nerdtree'
" Plugin 'scrooloose/nerdcommenter'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'edkolev/tmuxline.vim'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'nanotech/jellybeans.vim'
" Bundle 'jistr/vim-nerdtree-tabs'
Plugin 'Shougo/unite.vim'
" Plugin 'tyru/open-browser.vim'
" Plugin 'lambdalisue/vim-gista'
" Plugin 'Valloric/YouCompleteMe'
" Plugin 'mkusher/padawan.vim'
Plugin 'dhruvasagar/vim-prosession'
Plugin 'airblade/vim-gitgutter'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
" Plugin 'tomtom/tcomment_vim'
" Plugin 'garbas/vim-snipmate'
Plugin 'Raimondi/delimitMate'
" Plugin 'szw/vim-tags'
Plugin 'craigemery/vim-autotag'
Plugin 'mileszs/ack.vim'
Plugin 'maxbrunsfeld/vim-yankstack'
Plugin 'gioele/vim-autoswap'
Plugin 'ntpeters/vim-better-whitespace'
Plugin 'honza/vim-snippets'
" Plugin 'majutsushi/tagbar'
Plugin 'Shougo/echodoc.vim'
Plugin 'Shougo/vimproc.vim'
Plugin 'mattn/emmet-vim'
Plugin 'christoomey/vim-tmux-navigator'
Plugin 'moll/vim-bbye'
" Plugin 'jelera/vim-javascript-syntax'
" Plugin 'hail2u/vim-css3-syntax'
" Plugin 'Shougo/neosnippet'
" Plugin 'Shougo/neosnippet-snippets'
if has('nvim')
  " nvim only plugins
  Plugin 'Shougo/deoplete.nvim'
else
  " vim only plugins
  Plugin 'Shougo/neocomplete.vim'
  Plugin 'sirver/ultisnips'
  Plugin 'jaxbot/browserlink.vim'
endif
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" yankstack mappings
call yankstack#setup()

" Close if only panel left
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" ctr+n shortcut
" nerdtree
let NERDTreeQuitOnOpen=1
function! ToggleNERDTree()
  if &buftype == 'nofile'
    :NERDTreeClose
  else
    :NERDTreeFind
  endif
endfunction
let mapleader = "\<space>" " test if that will work better
" nnoremap <leader>s :NERDTreeToggle<cr>
nnoremap <leader>t :TagbarToggle<cr>
nnoremap <leader>r :call ToggleNERDTree()<cr>
nnoremap <leader>l :bn!<cr>
nnoremap <leader>h :bp!<cr>
nnoremap <leader>b :CtrlPBuffer<cr>
nnoremap <leader>m :CtrlPMRUFiles<cr>
nnoremap <leader>w :w<cr>
map <C-n> :bn!<cr>
map <C-p> :bp!<cr>
map <C-w>d :Bdelete<cr>
map <C-w>D :Bdelete!<cr>
map <C-w>p :bp!<cr>
map <C-w>n :bn!<cr>
map <C-w>x :Bdelete <bar>q<cr>
map <C-w>X :Bdelete! <bar> q<cr>
nnoremap <leader>d "_d
vnoremap <leader>d "_d
nnoremap <leader>D "_D
vnoremap <leader>D "_D
nnoremap <leader>c "_c
vnoremap <leader>c "_c
nnoremap <leader>C "_C
vnoremap <leader>C "_C
nnoremap <leader>x "_x
vnoremap <leader>x "_x
nnoremap <leader>y "+y
vnoremap <leader>Y "+Y
nnoremap <leader>p "+p
vnoremap <leader>P "+P
" case insensitive search by default
nnoremap / /\c
nnoremap ? ?\c
inoremap jk <Esc>
" nnoremap ; :
" nnoremap : ;
noremap q: :q
noremap q; :q
nnoremap <leader>== migg=G'i
nnoremap <leader>gp <Plug>GitGutterPreviewHunk
nnoremap <leader>gr <Plug>GitGutterRevertHunk
nnoremap <leader>gstage <Plug>GitGutterStageHunk
" Insert mode quick commands
inoremap II <Esc>I
inoremap AA <Esc>A
" inoremap OO <Esc>O
" inoremap CC <Esc>C
" inoremap SS <Esc>S
" inoremap DD <Esc>dd
" inoremap UU <Esc>u
" get rid of bad habbits :)
" Easy version for now
" noremap  <Up> ""
map <Up> <C-k>
map! <Up> <C-k>
" noremap  <Down> ""
map <Down> <C-j>
map! <Down> <C-j>
" noremap  <Left> ""
map <Left> <C-h>
map! <Left> <C-h>
" noremap  <Right> ""
map <Right> <C-l>
map! <Right> <C-l>
noremap  <Del> ""
noremap! <Del> <Esc>
noremap  <Ins> ""
noremap! <Ins> <Esc>
noremap  <Home> ""
noremap! <Home> <Esc>
noremap  <End> ""
noremap! <End> <Esc>
noremap  <PageUp> ""
noremap! <PageUp> <Esc>
noremap  <PageDown> ""
noremap! <PageDown> <Esc>
" Reload Browser
map <F5> :BLReloadPage<cr>
map <F6> :BLReloadCSS<cr>
" CtrlPset splitbelow
let g:ctrlp_cmd = 'CtrlPMixed'
let g:ctrlp_map = '<leader>f'
" air-line
set laststatus=2
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
" color scheme
colorscheme jellybeans
" Padawan
" let g:ycm_semantic_triggers = {}
" let g:ycm_semantic_triggers.php = ['->', '::', '(', 'use ', 'namespace ', '\']
" neocomplete
let g:echodoc_enable_at_startup = 1
set completeopt-=preview
set cmdheight=2
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
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
" let g:UltiSnipsJumpForwardTrigger="<cr>"
let g:UltiSnipsListSnippets="<c-e>"
let g:UltiSnipsExpandTrigger ="<c-@>"
" neocomplete
if 0 == 1
  xmap <expr><cr> pumvisible() ? "\<plug>(neosnippet_expand)" : "\<cr>"
  imap <expr><cr> pumvisible() ? "\<plug>(neosnippet_expand)" : "\<cr>"
  smap <expr><cr> pumvisible() ? "\<plug>(neosnippet_expand)" : "\<cr>"
  " SuperTab like snippets behavior.
  imap <expr><TAB> neosnippet#jumpable() ? "\<Plug>(neosnippet_jump)" : pumvisible() ? "\<C-n>" : "\<TAB>"
  " For snippet_complete marker.
  if has('conceal')
    set conceallevel=2 concealcursor=i
  endif
endif
if has('nvim')
  let g:deoplete#enable_at_startup = 1
  " <C-h>, <BS>: close popup and delete backword char.
  inoremap <expr><C-h>  deoplete#mappings#smart_close_popup()."\<C-h>"
  inoremap <expr><BS> deoplete#mappings#smart_close_popup()."\<C-h>"
  " if !exists('g:neocomplete#force_omni_input_patterns')
  "   let g:deoplete#omni#input_patterns = {}
  " endif
  " let g:deoplete#omni#input_patterns.php = '[^. \t]->\%(\h\w*\)\?\|\h\w*::\%(\h\w*\)\?'
else
  let g:neocomplete#enable_at_startup = 1
  " <C-h>, <BS>: close popup and delete backword char.
  inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
  inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
  " if !exists('g:neocomplete#sources#omni#input_patterns')
  "   let g:neocomplete#sources#omni#input_patterns = {}
  " endif
  " let g:neocomplete#sources#omni#input_patterns.php = '\h\w*\|[^. \t]->\%(\h\w*\)\?\|\h\w*::\%(\h\w*\)\?'
  if !exists('g:neocomplete#force_omni_input_patterns')
    let g:neocomplete#force_omni_input_patterns = {}
  endif
  let g:neocomplete#force_omni_input_patterns.php = '[^. \t]->\%(\h\w*\)\?\|\h\w*::\%(\h\w*\)\?'
endif
let g:EclimCompletionMethod = 'omnifunc'
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
" map <leader>w :set nowrap!<cr>
" multiple-cursors'
let g:multi_cursor_use_default_mapping = 0
let g:multi_cursor_next_key='<C-m>'
let g:multi_cursor_prev_key='<C-p>'
let g:multi_cursor_skip_key='<C-x>'
let g:multi_cursor_quit_key='<Esc>'
" white characters
" toggle invisible characters
set invlist
set listchars=tab:▸\ ,eol:¬,trail:⋅,extends:❯,precedes:❮
let g:strip_whitespace_on_save = 1
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
let g:delimitMate_matchpairs = "(:),[:],{:}"
let g:delimitMate_jump_expansion = 0
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
" eclim
let g:EclimFileTypeValidate = 0
" php linter
let g:syntastic_mode_map = {
      \ "mode": "active",
      \ "active_filetypes": ["ruby", "php"],
      \ "passive_filetypes": ["puppet"] }
"let g:syntastic_quiet_messages = { "type": "style" }
let g:syntastic_php_checkers = ['php', 'phpmd', 'phpcs']
let g:syntastic_aggregate_errors = 1
let g:syntastic_enable_signs = 0
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
" r like... stack or... swith
nmap <leader>s <Plug>yankstack_substitute_older_paste
nmap <leader>S <Plug>yankstack_substitute_newer_paste
" despatch hax to not cover half screen
let g:dispatch_quickfix_height = 10
let g:dispatch_tmux_height = 1
" autoswap tmux support
let g:autoswap_detect_tmux = 1
" If you prefer the Omni-Completion tip window to close when a selection is
" made, these lines close it on movement in insert mode or when leaving
" insert mode
autocmd CompleteDone * pclose
" custom commands
" close all buffers but current
command! BCloseAll execute "%bd"
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
" disable double save (cousing file watchers issues)
set nowritebackup
set nobackup " well, thats the only way to prevent guard from rutting tests twice ;/
" copy to system clipboard
" alpha stage
function! g:ClipCopy()
  let selection = @"
  silent echo system('echo ' . shellescape(join(split(selection,'\n'),'\n')). '|xclip -i -selection c')
endfunction
" modify selected text using combining diacritics
command! -range -nargs=0 Overline        call s:CombineSelection(<line1>, <line2>, '0305')
command! -range -nargs=0 Underline       call s:CombineSelection(<line1>, <line2>, '0332')
command! -range -nargs=0 DoubleUnderline call s:CombineSelection(<line1>, <line2>, '0333')
command! -range -nargs=0 Strikethrough   call s:CombineSelection(<line1>, <line2>, '0336')

function! s:CombineSelection(line1, line2, cp)
  execute 'let char = "\u'.a:cp.'"'
  execute a:line1.','.a:line2.'s/\%V[^[:cntrl:]]/&'.char.'/ge'
endfunction
