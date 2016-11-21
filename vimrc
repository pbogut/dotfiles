syntax on
set nocompatible              " be iMproved, required
filetype off                  " required

set runtimepath+=~/.vim
set timeoutlen=1000 ttimeoutlen=0   " eliminate esc timeout
set report=0
set nohlsearch
set mouse= "disable mouse support
set cursorline
set cursorcolumn
" space instead of tab
set laststatus=2
set completeopt=menuone
silent! set completeopt=menuone,noselect
set cmdheight=2
" show existing tab with 2 spaces width
set tabstop=4
" when indenting with '>', use 2 spaces width
set shiftwidth=4
" On pressing tab, insert 2 spaces
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
" set a directory to store the undo history
set undodir=~/.vim/undofiles//
set undofile
" set a directory for swp files
set dir=~/.vim/swapfiles//
" set backup disr
set backupdir=~/.vim/backupfiles//
set nowritebackup
set nobackup " well, thats the only way to prevent guard from running tests twice ;/
" toggle invisible characters
set invlist
set listchars=tab:▸\ ,eol:¬,trail:⋅,extends:❯,precedes:❮
set showbreak=↪
set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo
set wildignore=*.swp,*.bak,*.pyc,*.class
set hidden " No bang needed to open new file
" line 80 limit
set colorcolumn=81
" color scheme
set background=dark
if exists('&inccommand') | set inccommand=split | endif
if has("patch-7.4.314") | set shortmess+=c | endif

let mapleader = "\<space>" " life changer

if has('nvim')
  augroup configgroup_nvim
    autocmd!
    " fix terminal display
    autocmd TermOpen *
          \  setlocal listchars=
          \| set nocursorline
          \| set nocursorcolumn
  augroup END
endif
augroup configgroup
  autocmd!
  autocmd FileType html
        \  setlocal tabstop=4 shiftwidth=4
  autocmd FileType elixir
        \  setlocal tabstop=2 shiftwidth=2
  autocmd FileType c
        \  setlocal tabstop=4 shiftwidth=4
  autocmd FileType php
        \  setlocal tabstop=4 shiftwidth=4
        \| let b:commentary_format='// %s'
  autocmd FileType go :setlocal expandtab!
  " autocmd FileType javascript :setlocal tabstop=4 shiftwidth=4
  autocmd FileType ruby
        \  setlocal tabstop=2 shiftwidth=2
  autocmd FileType vim
        \  setlocal tabstop=2 shiftwidth=2
  autocmd FileType xml
        \  setlocal tabstop=4 shiftwidth=4
  autocmd FileType sh
        \  setlocal tabstop=4 shiftwidth=4
  autocmd FileType css
        \  setlocal tabstop=4 shiftwidth=4
  autocmd FileType scss
        \  setlocal tabstop=4 shiftwidth=4
  autocmd FileType qf :nnoremap <buffer> o <enter>
  autocmd FileType qf :nnoremap <buffer> q :q
  autocmd FileType blade :let b:commentary_format='{{-- %s --}}'
  autocmd FileType markdown :setlocal spell spelllang=en_gb
  " start mutt file edit on first empty line
  autocmd BufRead /tmp/mutt* execute "normal /^$/\ni\n\n\<esc>k"
        \| setlocal spell spelllang=en_gb
        \| let g:pencil#textwidth = 72
        \| call pencil#init()
  autocmd BufEnter * normal zR
  " check shada to share vim info between instances
  " autocmd CursorHold * rshada | wshada
  " autocmd FocusLost * wshada
  " autocmd FocusGained * sleep 100m | rshada
  autocmd FileType vimfiler
        \  nunmap <buffer> <leader>
        \| nunmap <buffer> N
        \| nmap <buffer> A <Plug>(vimfiler_new_file)
        \| nmap <buffer> <leader>r q
        \| nmap <buffer> v <Plug>(vimfiler_toggle_mark_current_line)
        \| nmap <buffer> <leader>fm q <bar> :FZFFreshMru<cr>
        \| nmap <buffer> <leader>fa q <bar> :call local#fzf#files()<cr>
        \| nmap <buffer> <leader>ff q <bar> :call local#fzf#all_files()<cr>
        \| nmap <buffer> <leader>fg q <bar> :call local#fzf#git_ls()<cr>
        \| nmap <buffer> <leader>fb q <bar> :FZFBuffers<cr>
augroup END


" set the runtime path to include Vundle and initialize
" set rtp+=~/.vim/bundle/Vundle.vim
silent! call plug#begin()
if exists(':Plug')
  Plug 'vim-ruby/vim-ruby', { 'for': 'ruby' }
  Plug 'xolox/vim-misc'
  Plug 'xolox/vim-notes'
  Plug 'jiangmiao/auto-pairs'
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-git'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-rails', { 'for': 'ruby' }
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-unimpaired'
  Plug 'tpope/vim-obsession'
  Plug 'tpope/vim-dispatch'
  Plug 'tpope/vim-abolish'
  Plug 'tpope/vim-projectionist'
  Plug 'dhruvasagar/vim-prosession'
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  Plug 'edkolev/tmuxline.vim'
  Plug 'airblade/vim-gitgutter'
  Plug 'terryma/vim-expand-region'
  Plug 'terryma/vim-multiple-cursors'
  Plug 'MarcWeber/vim-addon-mw-utils'
  Plug 'ludovicchabant/vim-gutentags'
  Plug 'gioele/vim-autoswap'
  Plug 'ntpeters/vim-better-whitespace'
  Plug 'honza/vim-snippets'
  Plug 'mattn/emmet-vim'
  Plug 'christoomey/vim-tmux-navigator'
  Plug 'sirver/ultisnips'
  Plug 'sheerun/vim-polyglot'
  Plug 'joonty/vdebug', { 'on': 'PlugLoadVdebug' }
  Plug 'benekastah/neomake'
  Plug 'Chiel92/vim-autoformat'
  Plug 'alvan/vim-closetag'
  Plug 'edsono/vim-matchit'
  Plug 'captbaritone/better-indent-support-for-php-with-html', { 'for': 'php' }
  Plug 'docteurklein/php-getter-setter.vim', { 'for': 'php' }
  Plug 'pbogut/phpfolding.vim', { 'for': 'php' }
  Plug 'janko-m/vim-test'
  Plug 'benmills/vimux'
  Plug 'elixir-lang/vim-elixir', { 'for': 'elixir' }
  Plug 'kana/vim-operator-user'
  Plug 'chrisbra/csv.vim', { 'for': ['csv', 'tsv'] }
  Plug 'rhysd/vim-grammarous'
  Plug 'moll/vim-bbye', { 'on': 'Bdelete' }
  Plug 'will133/vim-dirdiff'
  Plug 'dbakker/vim-projectroot'
  Plug 'AndrewRadev/switch.vim'
  Plug 'AndrewRadev/splitjoin.vim'
  Plug 'AndrewRadev/sideways.vim'
  Plug 'godlygeek/tabular'
  Plug 'reedes/vim-pencil'
  Plug 'vim-scripts/cmdalias.vim'
  Plug 't9md/vim-choosewin'
  Plug 'Shougo/unite.vim'
  Plug 'Shougo/vimfiler.vim'
  if has('nvim')
    Plug 'Shougo/deoplete.nvim'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'
    Plug 'pbogut/fzf-mru.vim'
    Plug 'slashmili/alchemist.vim', { 'for': 'elixir' }
    Plug 'zchee/deoplete-go', { 'do': 'go get github.com/nsf/gocode && make', 'for': 'go'}
    Plug 'zchee/deoplete-zsh', { 'for': 'zsh' }
    Plug 'zchee/deoplete-jedi', { 'for': 'python' }
    Plug 'pbogut/deoplete-padawan'
  endif " if Plug installed
  if has('nvim') || has('vim8')
    Plug 'metakirby5/codi.vim'
  endif
  if (!has('nvim') || $STY != '')
    Plug 'altercation/vim-colors-solarized'
  else
    set termguicolors
    Plug 'frankier/neovim-colors-solarized-truecolor-only'
  endif
endif "
silent! call plug#end()      " requiredc
filetype plugin indent on    " required
"
source ~/.vim/plugin/config/airline.vimrc
source ~/.vim/plugin/config/autopairs.vimrc
source ~/.vim/plugin/config/deoplete.vimrc
source ~/.vim/plugin/config/fzf.vimrc
source ~/.vim/plugin/config/gutentags.vimrc
source ~/.vim/plugin/config/neomake.vimrc
source ~/.vim/plugin/config/phpgetset.vimrc
source ~/.vim/plugin/config/projectionist.vimrc
source ~/.vim/plugin/config/switch.vimrc
source ~/.vim/plugin/config/terminal.vimrc

augroup after_load
  autocmd!
  autocmd VimEnter *
        \  source ~/.vim/plugin/config/abolish.vimrc
        \| source ~/.vim/plugin/config/cmdalias.vimrc
augroup END

silent! colorscheme solarized

" vim filer
let g:vimfiler_safe_mode_by_default = 0
" closetag
let g:closetag_filenames = "*.html,*.xhtml,*.phtml,*.xml,*.blade.php"
" notes
let g:notes_directories = [ $HOME . "/Notes/" ]
" projectroot
let g:rootmarkers = ['.projectroot', '.git', '.hg', '.svn', '.bzr',
      \ '_darcs', 'build.xml', 'composer.json', 'mix.exs']
" write or select when in command mode
function! WriteOrCr()
  if &buftype == 'nofile'
    call feedkeys("\<cr>")
  elseif @% != ''
    exec "w"
  else
    echo 'Nothing to save...'
  endif
endfunction
" macros
nnoremap <leader>em :tabnew ~/.vim/macros.vim<cr>
nnoremap <leader>sm :source ~/.vim/macros.vim<cr>
" edit vimrc/zshrc and load vimrc bindings
nnoremap <leader>ev :tabnew $MYVIMRC<CR>
nnoremap <leader>ez :tabnew ~/.zshrc<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>
" open list / quickfix
nnoremap <silent> <leader>ol :lopen<cr>
nnoremap <silent> <leader>oq :copen<cr>
nnoremap <silent> <leader>oc :copen<cr>
nnoremap <silent> <leader>ot :belowright 11split \| terminal<cr>
nnoremap <silent> <leader>oT :belowright split \| terminal<cr>
nnoremap <silent> <leader>ovt :belowright vertical split \| terminal<cr>
nnoremap <silent> <leader>r :VimFilerExplorer -find -force-quit<cr>
nnoremap <silent> <leader>b :Buffers<cr>
" fzf
nnoremap <silent> <leader>fm :FZFFreshMru<cr>
nnoremap <silent> <leader>fa :call local#fzf#files()<cr>
nnoremap <silent> <leader>ff :call local#fzf#all_files()<cr>
nnoremap <silent> <leader>fg :call local#fzf#git_ls()<cr>
nnoremap <silent> <leader>fb :FZFBuffers<cr>
nnoremap <silent> <leader>gf :call local#fzf#files(expand('<cfile>'))<cr>
nnoremap <silent> <leader>gt :call fzf#vim#tags(expand('<cword>'))<cr>
nnoremap <silent> <leader>w :call WriteOrCr()<cr>
nnoremap <silent> <leader>a :Autoformat<cr>
nnoremap <silent> <leader>z :call PHP__Fold()<cr>
" vim is getting ^_ when pressing ^/, so I've mapped both
nmap <C-_> gcc<down>^
nmap <C-/> gcc<down>^
vmap <C-_> gc
vmap <C-/> gc
" projectionist - alternate
noremap <leader>ta :A<cr>
" surround
vmap s S
" expand region
vmap v <Plug>(expand_region_expand)
vmap V <Plug>(expand_region_shrink)
nmap <silent> <bs> :TmuxNavigateLeft<cr>
" remap delete to c-d because on hardware level Im sending del when c-d (ergodox)
nmap <silent> <del> <c-d>
map <C-w>d :Bdelete<cr>
map <C-w>D :Bdelete!<cr>
" more natural split (always right/below)
nmap <silent> <c-w>v :rightbelow vsplit<cr>
nmap <silent> <c-w>s :rightbelow split<cr>
" just in case I want old behaviour from time to time
nmap <silent> <c-w>V :vsplit<cr>
nmap <silent> <c-w>S :split<cr>
map Y y$
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
nnoremap <leader>Y "+y$
vnoremap <leader>Y "+y$
snoremap <leader>Y "+y$
nnoremap <leader>p "+p
vnoremap <leader>p "+p
snoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>P "+P
snoremap <leader>P "+P
nnoremap <leader><leader>p "*p
vnoremap <leader><leader>p "*p
snoremap <leader><leader>p "*p
nnoremap <leader><leader>P "*P
vnoremap <leader><leader>P "*P
snoremap <leader><leader>P "*P
nmap <leader>cp "+cp
noremap <leader>sh :set syntax=html<cr>
noremap <leader>sp :set syntax=php<cr>
noremap <leader>sr :set syntax=ruby<cr>
noremap <leader>sc :set syntax=css<cr>
noremap <leader>sj :set syntax=js<cr>
noremap <leader>sx :set syntax=xml<cr>
noremap <leader>sa :exec "Autoformta ".&syntax<cr>
" nicer wrapline navigation
noremap <silent> j gj
noremap <silent> k gk
" noremap  <silent> 0 g0
" noremap  <silent> $ g$
" noremap  <silent> ^ g^
vnoremap <silent> j gj
vnoremap <silent> k gk
onoremap <silent> j gj
onoremap <silent> k gk
" nice to have
inoremap <c-d> <del>
cnoremap <c-d> <del>
" vim-test
nmap <silent> <leader>tn :TestNearest<CR>
nmap <silent> <leader>tf :TestFile<CR>
nmap <silent> <leader>ts :TestSuite<CR>
nmap <silent> <leader>tl :TestLast<CR>
nmap <silent> <leader>tt :TestLast<CR>
nmap <silent> <leader>tv :TestVisit<CR>
cnoremap \\* \(.*\)
cnoremap \\- \(.\{-}\)
" prevent pasting in visual from yank seletion
snoremap p "_dP
vnoremap p "_dP
" case insensitive search by default
nnoremap / /\c
nnoremap c/ c/\c
nnoremap d/ d/\c
nnoremap y/ y/\c
nnoremap ? ?\c
nnoremap c? c?\c
nnoremap d? d?\c
nnoremap y? y?\c
nnoremap <silent> <leader>= migg=G'i
nmap <silent> <leader>gp <Plug>GitGutterPreviewHunk
nmap <silent> <leader>grevert <Plug>GitGutterRevertHunk
nmap <silent> <leader>gstage <Plug>GitGutterStageHunk
" keep ga functionality as gas
nnoremap gas ga
" Sideways
nmap <silent> ga< :SidewaysLeft<cr>
nmap <silent> ga> :SidewaysRight<cr>
nmap <silent> gab :SidewaysJumpLeft<cr>
nmap <silent> gaw :SidewaysJumpRight<cr>
omap <silent> aa <plug>SidewaysArgumentTextobjA
xmap <silent> aa <plug>SidewaysArgumentTextobjA
omap <silent> ia <plug>SidewaysArgumentTextobjI
xmap <silent> ia <plug>SidewaysArgumentTextobjI
inoremap <C-Space> <c-x><c-o>
imap <C-@> <C-Space>
inoremap <silent> </ </<C-X><C-O><C-n><esc>mB==`Ba
" nvim now can map alt without terminal issues, new cool shortcuts commin
if has('nvim')
  noremap <silent> <M-r> :call local#i3focus#switch('down', 'j')<cr>
  noremap <silent> <M-w> :call local#i3focus#switch('up', 'k')<cr>
  noremap <silent> <M-t> :call local#i3focus#switch('right', 'l')<cr>
  noremap <silent> <M-a> :call local#i3focus#switch('left', 'h')<cr>
  inoremap <silent> <M-r> <end>:call local#i3focus#switch('down', 'j')<cr>
  inoremap <silent> <M-w> <esc>:call local#i3focus#switch('up', 'k')<cr>
  inoremap <silent> <M-t> <esc>:call local#i3focus#switch('right', 'l')<cr>
  inoremap <silent> <M-a> <esc>:call local#i3focus#switch('left', 'h')<cr>
  cnoremap <silent> <M-r> <end><c-u>:call local#i3focus#switch('down', 'j')<cr>
  cnoremap <silent> <M-w> <end><c-u>:call local#i3focus#switch('up', 'k')<cr>
  cnoremap <silent> <M-t> <end><c-u>:call local#i3focus#switch('right', 'l')<cr>
  cnoremap <silent> <M-a> <end><c-u>:call local#i3focus#switch('left', 'h')<cr>
  " escape terminal and move switch focus
  tnoremap <silent> <M-r> <C-\><C-n> :call local#i3focus#switch('down', 'j')<cr>
  tnoremap <silent> <M-w> <C-\><C-n>:call local#i3focus#switch('up', 'k')<cr>
  tnoremap <silent> <M-t> <C-\><C-n> :call local#i3focus#switch('right', 'l')<cr>
  tnoremap <silent> <M-a> <C-\><C-n> :call local#i3focus#switch('left', 'h')<cr>

  tnoremap <silent> <c-q> <C-\><C-n>

  noremap <silent> <M-l> :vertical resize +1<cr>
  noremap <silent> <M-h> :vertical resize -1<cr>
  noremap <silent> <M-j> :resize +1<cr>
  noremap <silent> <M-k> :resize -1<cr>

  cnoremap <A-k> <Up>
  cnoremap <A-j> <Down>
endif

" better key bindings for UltiSnipsExpandTrigger
let g:UltiSnipsExpandTrigger = "<tab>"
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"

let g:UltiSnipsSnippetDirectories=["UltiSnips", "mysnippets"]
" eclim
let g:EclimFileTypeValidate = 0
let g:EclimCompletionMethod = 'omnifunc'
let g:strip_whitespace_on_save = 1
" Autoformat
let g:formatdef_phpcbf = '"phpcbf -d tabWidth=".&shiftwidth'
let g:formatters_php = ['phpcbf']

let g:formatdef_blade = '"html-beautify -s ".&shiftwidth'
let g:formatters_blade = ['blade']
" despatch hax to not cover half screen
let g:dispatch_quickfix_height = 10
let g:dispatch_tmux_height = 1
" autoswap tmux support
let g:autoswap_detect_tmux = 1
" custom commands
" close all buffers but current
command! BCloseAll execute "%bd"
command! BCloseOther execute "%bd | e#"
command! BCloseOtherForce execute "%bd! | e#"
let g:test#strategy = 'neovim'

let g:paranoic_backup_dir="~/.vim/backupfiles/"

command! -bang W :call CreateFoldersAndWrite(<bang>0)
function! CreateFoldersAndWrite(bang)
  if (a:bang)
    silent execute('!mkdir -p %:h')
    execute(':w')
  else
    echo('You need to use W!')
  endif
endfunction
" disable double save (cousing file watchers issues)

" fold adjust
set fillchars="vert:|,fold: "
" remove underline
hi Folded term=NONE cterm=NONE gui=NONE
" new fold style
function! NeatFoldText()
  let line = ' ' . substitute(getline(v:foldstart), '^\s*"\?\s*\|\s*"\?\s*{{' . '{\d*\s*', '', 'g') . ' '
  let lines_count = v:foldend - v:foldstart + 1
  let lines_count_text = '| ' . printf("%10s", lines_count . ' lines') . ' |'
  " let foldchar = matchstr(&fillchars, 'fold:\zs.')
  let foldchar = ' ' " use the space
  let foldtextstart = strpart('+' . repeat(foldchar, v:foldlevel*2) . line, 0, (winwidth(0)*2)/3)
  let foldtextend = lines_count_text . repeat(foldchar, 8)
  let foldtextlength = strlen(substitute(foldtextstart . foldtextend, '.', 'x', 'g')) + &foldcolumn
  return foldtextstart . repeat(foldchar, winwidth(0)-foldtextlength) . foldtextend
endfunction
function! PHP__Fold()
  if (get(b:, '_php__flod__initiated', 0))
    silent! normal za
  else
    silent! execute 'EnableFastPHPFolds'
    silent! normal zRza
    let b:_php__flod__initiated = 1
  endif
endfunction
set foldtext=NeatFoldText()
let g:DisableAutoPHPFolding = 1

let &titlestring = $USER . '@' . hostname() . ":nvim:" . substitute($NVIM_LISTEN_ADDRESS, '/tmp/nvim\(.*\)\/0$', '\1', 'g') . ":" . substitute(getcwd(),$HOME,'~', 'g')
set title

let g:snips_author = "Pawel Bogut"
let g:snips_github = "https://github.com/pbogut"

silent! exec(":source ~/.vim/" . hostname() . ".vim")
