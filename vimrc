syntax on

set nocompatible              " be iMproved, required
filetype off                  " required

set timeoutlen=1000 ttimeoutlen=0   " eliminate esc timeout
set report=0
set nohlsearch
set mouse= "disable mouse support
set cursorline
set cursorcolumn
" space instead of tab
set laststatus=2
set completeopt-=preview
set cmdheight=2
" show existing tab with 4 spaces width
set tabstop=2
" when indenting with '>', use 4 spaces width
set shiftwidth=2
" On pressing tab, insert 4 spaces
set expandtab
" scroll
set scrolloff=3
" tab size for php and html
" line numering
set number
set relativenumber
set lazyredraw
set wildmenu
set incsearch
set showcmd
" toggle invisible characters
set invlist
set listchars=tab:▸\ ,eol:¬,trail:⋅,extends:❯,precedes:❮
set showbreak=↪
set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo
set wildignore=*.swp,*.bak,*.pyc,*.class
augroup configgroup
  autocmd!
  autocmd FileType html :setlocal tabstop=4 shiftwidth=4
  autocmd FileType php :setlocal tabstop=4 shiftwidth=4
  " autocmd FileType javascript :setlocal tabstop=4 shiftwidth=4
  autocmd FileType xml :setlocal tabstop=4 shiftwidth=4
  autocmd FileType sh :setlocal tabstop=4 shiftwidth=4
  autocmd FileType qf :nnoremap <buffer> o <enter>
augroup END
" line 80 limit
set colorcolumn=81

let g:python_host_prog='/usr/bin/python'

if has("patch-7.4.314")
  set shortmess+=c
endif

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'

Plugin 'vim-ruby/vim-ruby'

" Plugin 'Raimondi/delimitMate' "needs to be loaded before endwise
Plugin 'jiangmiao/auto-pairs'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-git'
Plugin 'tpope/vim-commentary'
Plugin 'tpope/vim-rvm'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-obsession'
Plugin 'tpope/vim-endwise'
Plugin 'tpope/vim-unimpaired'
" Plugin 'tpope/vim-dispatch'
Plugin 'pbogut/vim-dispatch' " panel size
Plugin 'terryma/vim-expand-region'
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
Bundle 'ervandew/supertab'
" Plugin 'Valloric/YouCompleteMe'
Plugin 'Shougo/deoplete.nvim'
" Plugin 'mkusher/padawan.vim'
Plugin 'dhruvasagar/vim-prosession'
Plugin 'airblade/vim-gitgutter'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
" Plugin 'tomtom/tcomment_vim'
" Plugin 'garbas/vim-snipmate'
" Plugin 'szw/vim-tags'
" Plugin 'craigemery/vim-autotag'
Plugin 'ludovicchabant/vim-gutentags'
Plugin 'mileszs/ack.vim'
Plugin 'rking/ag.vim'
Plugin 'gioele/vim-autoswap'
Plugin 'ntpeters/vim-better-whitespace'
Plugin 'honza/vim-snippets'
" Plugin 'majutsushi/tagbar'
" Plugin 'Shougo/echodoc.vim'
Plugin 'Shougo/vimproc.vim'
Plugin 'mattn/emmet-vim'
Plugin 'christoomey/vim-tmux-navigator'
Plugin 'moll/vim-bbye'
Plugin 'sirver/ultisnips'
" Plugin 'Shougo/neosnippet'
" Plugin 'Shougo/neosnippet-snippets'
Plugin 'sheerun/vim-polyglot'
Bundle 'joonty/vdebug.git'
Plugin 'jaxbot/browserlink.vim'
" Plugin 'scrooloose/syntastic'
Plugin 'benekastah/neomake' "efed615 - working commit, 3bfb4ef - seams to work as well
Plugin 'Chiel92/vim-autoformat'
Plugin 'alvan/vim-closetag'
Plugin 'edsono/vim-matchit'

Plugin 'captbaritone/better-indent-support-for-php-with-html'
Plugin 'docteurklein/php-getter-setter.vim'

Plugin 'elixir-lang/vim-elixir'
Plugin 'thinca/vim-ref'
Plugin 'awetzel/elixir.nvim', { 'do': 'yes \| ./install.sh' }
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" closetag
let g:closetag_filenames = "*.html,*.xhtml,*.phtml,*.xml"
" Neomake
augroup neomakegroup
  autocmd!
  autocmd BufWritePost * Neomake
augroup END

let g:neomake_airline = 1
let g:neomake_error_sign = {'texthl': 'ErrorMsg'}

let g:neomake_php_enabled_makers = ['php', 'phpmd']

" nerdtree
let NERDTreeQuitOnOpen=1
" one actino to reaveal file and close sidebar
function! ToggleNERDTree()
  if &buftype == 'nofile'
    :NERDTreeClose
  else
    :NERDTreeFind
  endif
endfunction
let mapleader = "\<space>" " test if that will work better
" macros
nnoremap <leader>em :vsp ~/.vim/macros.vim<cr>
nnoremap <leader>sm :source ~/.vim/macros.vim<cr>
" edit vimrc/zshrc and load vimrc bindings
nnoremap <leader>ev :vsp $MYVIMRC<CR>
nnoremap <leader>ez :vsp ~/.zshrc<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>
" open list / quickfix
nnoremap <leader>ol :lopen<cr>
nnoremap <leader>oq :copen<cr>
" nnoremap <leader>s :NERDTreeToggle<cr>
nnoremap <leader>t :TagbarToggle<cr>
nnoremap <leader>r :call ToggleNERDTree()<cr>
nnoremap <leader>l :bn!<cr>
nnoremap <leader>h :bp!<cr>
nnoremap <leader>b :CtrlPBuffer<cr>
nnoremap <leader>m :CtrlPMRUFiles<cr>
" nnoremap <leader>gf :CtrlP<cr><C-\>f
" nnoremap <leader>gw :CtrlP<cr><C-\>w
" nnoremap <leader>gt :CtrlPTag<cr><C-\>w
nnoremap <leader>w :w<cr>
nnoremap <leader>a :Autoformat<cr>
map <C-w>d :Bdelete<cr>
map <C-w>D :Bdelete!<cr>
map <C-w>p :bp!<cr>
map <C-w>n :bn!<cr>
map <C-w>x :Bdelete <bar>q<cr>
map <C-w>X :Bdelete! <bar> q<cr>
nnoremap <leader>d "_d
vnoremap <leader>d "_d
snoremap <leader>d "_d
nnoremap <leader>D "_D
vnoremap <leader>D "_D
snoremap <leader>D "_D
nnoremap <leader>c "_c
vnoremap <leader>c "_c
snoremap <leader>c "_c
nnoremap <leader>C "_C
vnoremap <leader>C "_C
snoremap <leader>C "_C
nnoremap <leader>x "_x
vnoremap <leader>x "_x
snoremap <leader>x "_x
nnoremap <leader>y "+y
vnoremap <leader>y "+y
snoremap <leader>y "+y
nnoremap <leader>Y "+Y
vnoremap <leader>Y "+Y
snoremap <leader>Y "+Y
nnoremap <leader>p "+p
vnoremap <leader>p "+p
snoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>P "+P
snoremap <leader>P "+P
noremap <leader>sh :set syntax=html<cr>
noremap <leader>sp :set syntax=php<cr>
noremap <leader>sr :set syntax=ruby<cr>
noremap <leader>sc :set syntax=css<cr>
noremap <leader>sj :set syntax=js<cr>
noremap <leader>sx :set syntax=xml<cr>
noremap <leader>sa :exec "Autoformat ".&syntax<cr>
" prevent pasting in visual from yank seletion
snoremap p "_dP
vnoremap p "_dP
" case insensitive search by default
nnoremap / /\c
nnoremap ? ?\c
nnoremap <leader>= migg=G'i
nnoremap <leader>gp <Plug>GitGutterPreviewHunk
nnoremap <leader>gr <Plug>GitGutterRevertHunk
nnoremap <leader>gstage <Plug>GitGutterStageHunk
" Reload Browser
iabbrev <// </<C-X><C-O>
map <F8> :BLReloadPage<cr>
map <F7> :BLReloadCSS<cr>
let g:bl_no_autoupdate = 1
" CtrlPset splitbelow
function! CtrlPFindTag()
  let g:ctrlp_default_input = expand('<cword>')
  CtrlPTag
  let g:ctrlp_default_input = ''
endfunction
function! CtrlPFindFile()
  let g:ctrlp_default_input = expand('<cfile>')
  CtrlP
  let g:ctrlp_default_input = ''
endfunction
nnoremap <leader>gf :call CtrlPFindFile()<cr>
nnoremap <leader>gt :call CtrlPFindTag()<cr>
let g:ctrlp_cmd = 'CtrlPMixed'
let g:ctrlp_map = '<leader>f'
" air-line
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
" color scheme
colorscheme jellybeans
highlight ColorColumn ctermbg=234
highlight CursorLine ctermbg=233
highlight CursorColumn ctermbg=232
highlight SpecialKey ctermbg=none
" Padawan
let g:ycm_semantic_triggers = {}
let g:ycm_semantic_triggers.php = ['->', '::', '(', 'use ', 'namespace ', '\']
" Deoplete
let g:deoplete#enable_at_startup = 1
inoremap <C-Space> <c-x><c-o>
imap <C-@> <C-Space>
" make YCM compatible with UltiSnips (using supertab)
let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']
let g:SuperTabDefaultCompletionType = '<C-n>'
" better key bindings for UltiSnipsExpandTrigger
let g:UltiSnipsExpandTrigger = "<tab>"
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"
" eclim
let g:EclimFileTypeValidate = 0
let g:EclimCompletionMethod = 'omnifunc'
" expand region
vmap v <Plug>(expand_region_expand)
vmap V <Plug>(expand_region_shrink)
let g:strip_whitespace_on_save = 1
" delimitMate
let g:delimitMate_smart_matchpairs = 1
let g:delimitMate_expand_cr = 2
let g:delimitMate_expand_space = 1
let g:delimitMate_matchpairs = "(:),[:],{:}"
let g:delimitMate_jump_expansion = 0
" AutoPair
let g:AutoPairsMultilineClose = 0
" php linter
let g:syntastic_mode_map = {
      \ "mode": "active",
      \ "active_filetypes": ["ruby", "php"],
      \ "passive_filetypes": ["puppet"] }
"let g:syntastic_quiet_messages = { "type": "style" }
" let g:syntastic_php_checkers = ['php', 'phpmd', 'phpcs']
let g:syntastic_php_checkers = ['php', 'phpmd']
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
" use ag if available
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif
let g:ag_working_path_mode="r"

cnoreabbrev fixphpf %s/\(function.*\){$/\1\r{/g

" Autoformat
" PHP - pipline of few
let g:formatdef_phppipeline = '"fmt.phar --passes=ConvertOpenTagWithEcho --indent_with_space=".&shiftwidth." - | html-beautify -s ".&shiftwidth." | phpcbf"'
let g:formatters_php = ['phppipeline']
let g:formatdef_blade = '"html-beautify -s ".&shiftwidth'
let g:formatters_blade = ['blade']
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
" modify selected text using combining diacritics
command! -range -nargs=0 Overline        call s:CombineSelection(<line1>, <line2>, '0305')
command! -range -nargs=0 Underline       call s:CombineSelection(<line1>, <line2>, '0332')
command! -range -nargs=0 DoubleUnderline call s:CombineSelection(<line1>, <line2>, '0333')
command! -range -nargs=0 Strikethrough   call s:CombineSelection(<line1>, <line2>, '0336')
function! s:CombineSelection(line1, line2, cp)
  execute 'let char = "\u'.a:cp.'"'
  execute a:line1.','.a:line2.'s/\%V[^[:cntrl:]]/&'.char.'/ge'
endfunction
