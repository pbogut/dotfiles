syntax on
set nocompatible              " be improved, required
filetype off                  " required

set noshowmode
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
set tabstop=2
" when indenting with '>', use 2 spaces width
set shiftwidth=2
" On pressing tab, insert 2 spaces
set expandtab
" scroll
set scrolloff=3
" tab size for php and html
" line numering
set number
set relativenumber
" set nolazyredraw
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
set listchars=tab:▸\ ,eol:¬,trail:⋅,extends:❯,precedes:❮,nbsp:%
set showbreak=↪
set fillchars=fold:\ ,vert:\│
set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo
set wildignore=*.swp,*.bak,*.pyc,*.class
set hidden " No bang needed to open new file
set clipboard=unnamedplus
" line 80 limit
set colorcolumn=81
set foldmethod=manual
set foldnestmax=10
set foldlevelstart=99
" set cscopetag "search both cscopes db and the tags file
" color scheme
set background=dark
if exists('&inccommand') | set inccommand=split | endif
if has("patch-7.4.314") | set shortmess+=c | endif
if executable('ag') | set grepprg=ag | endif
if executable('rg')
  set grepprg=rg\ --vimgrep\ --no-heading
  set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

let mapleader = "\<space>" " life changer

if has('nvim')
  " let $NVIM_TUI_ENABLE_CURSOR_SHAPE = 1
  set guicursor=n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor

  augroup configgroup_nvim
    autocmd!
    " fix terminal display
    autocmd TermOpen *
          \  :silent! normal! <c-\><c-n>a
          " \| setlocal nocursorline
          " \| setlocal nocursorcolumn
  augroup END
endif
augroup configgroup
  autocmd!
  autocmd FileType *
        \  call matchadd('Todo', '@todo\>')
        \| call matchadd('Todo', '@fixme\>')
  " autocmd FileType html
  "       \  setlocal tabstop=4 shiftwidth=4
  " autocmd FileType vue
  "       \  setlocal tabstop=2 shiftwidth=2
  " autocmd FileType javascript
  "       \  setlocal tabstop=2 shiftwidth=2
  " autocmd FileType elixir
  "       \  setlocal tabstop=2 shiftwidth=2
  autocmd FileType c
        \  setlocal tabstop=4 shiftwidth=4
  autocmd FileType php
        \  setlocal tabstop=4 shiftwidth=4
        \| let b:commentary_format='// %s'
        \| nmap <buffer> gD <plug>(composer-find)
        \| setlocal kp=:PhpDoc
        \| exec("map get mz0wwwyw/getters<cr>jo/**<cr>Gets <esc>pb~yiwo<cr>@return mixed<cr><cr>/<cr>public function get<esc>pa()<cr>{<cr>return $this-><esc>pb~A;<esc>jo<esc>`zj")
        \| exec("map set mz0wwwyw/setters<cr>jo/**<cr>Sets <esc>pb~yiwo<cr>@return $this<cr><cr>/<cr>public function set<esc>pa(<esc>pbi$<esc>~~ea)<cr>{<cr>$this-><esc>pb~A = $<esc>pb~A;<cr>return $this;<esc>jo<esc>`zj")
  autocmd FileType go
        \  setlocal noexpandtab
        " \| setlocal tabstop=2 shiftwidth=2
  " autocmd FileType ruby
  "       \  setlocal tabstop=2 shiftwidth=2
  " autocmd FileType vim
  "       \  setlocal tabstop=2 shiftwidth=2
  "       \| setlocal kp=:help
  " autocmd FileType xml
  "       \  setlocal tabstop=4 shiftwidth=4
  " autocmd FileType sh
  "       \  setlocal tabstop=4 shiftwidth=4
  " autocmd FileType css
  "       \  setlocal tabstop=4 shiftwidth=4
  " autocmd FileType scss
  "       \  setlocal tabstop=4 shiftwidth=4
  autocmd FileType blade
        \  let b:commentary_format='{{-- %s --}}'
  autocmd FileType crontab\|nginx\|resolv
        \  let b:commentary_format='# %s'
  autocmd FileType markdown
        \  setlocal spell spelllang=en_gb
  autocmd FileType qf
        \  nnoremap <buffer> o <cr>
        \| nnoremap <buffer> q :q
  autocmd FileType gitcommit
        \  execute("wincmd J")
        \| if(winnr() != 1) | execute("resize 20") | endif
  " start mutt file edit on first empty line
  autocmd FileType mail
        \ execute("normal /^$/\n")
        \| setlocal spell spelllang=en_gb
        \| setlocal textwidth=72
  autocmd BufEnter lpass.*
        \  if search('^Password: $')
        \|   execute('r !apg -m16 -n1 -MSNCL')
        \|   execute('normal kJkk')
        \| endif
  " autocmd BufEnter * normal! zR
  " check shada to share vim info between instances
  " autocmd CursorHold * rshada | wshada
  " autocmd FocusLost * wshada
  " autocmd FocusGained * sleep 100m | rshada
  autocmd FileType tagbar
        \  nmap <buffer> <leader>n q
  autocmd InsertLeave *
              \ if &buftype == 'acwrite' | execute('WidenRegion') | endif
  " always show gutter column to avoid blinking and jumping
  " autocmd BufEnter *
  "       \  execute('sign define dummy')
  "       \| execute('sign place 98913 line=1 name=dummy buffer=' . bufnr(''))
augroup END

silent! call plug#begin()
if exists(':Plug')
  Plug 'vim-ruby/vim-ruby', { 'for': 'ruby' }
  Plug 'xolox/vim-misc'
  Plug 'xolox/vim-notes'
  Plug 'jiangmiao/auto-pairs'
  Plug 'tpope/vim-scriptease'
  " Plug 'tpope/vim-fugitive'
  Plug 'pbogut/vim-fugitive'
  Plug 'tpope/vim-eunuch'
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
  Plug 'airblade/vim-gitgutter'
  Plug 'MarcWeber/vim-addon-mw-utils'
  Plug 'ludovicchabant/vim-gutentags'
  Plug 'gioele/vim-autoswap'
  Plug 'ntpeters/vim-better-whitespace'
  Plug 'honza/vim-snippets'
  Plug 'mattn/emmet-vim'
  Plug 'majutsushi/tagbar'
  Plug 'sirver/ultisnips'
  Plug 'joonty/vdebug', { 'on': 'PlugLoadVdebug' }
  " Plug 'benekastah/neomake'
  " Plug 'Chiel92/vim-autoformat'
  Plug 'alvan/vim-closetag'
  Plug 'k-takata/matchit.vim'
  Plug 'captbaritone/better-indent-support-for-php-with-html', { 'for': 'php' }
  Plug 'noahfrederick/vim-composer', { 'for': 'php' }
  Plug 'janko-m/vim-test'
  Plug 'elmcast/elm-vim', { 'for': 'elm' }
  Plug 'elixir-lang/vim-elixir', { 'for': ['elixir', 'eelixir'] }
  Plug 'kana/vim-operator-user'
  Plug 'moll/vim-bbye', { 'on': 'Bdelete' }
  Plug 'will133/vim-dirdiff'
  Plug 'dbakker/vim-projectroot'
  Plug 'AndrewRadev/switch.vim'
  Plug 'AndrewRadev/splitjoin.vim'
  Plug 'AndrewRadev/sideways.vim'
  Plug 'godlygeek/tabular'
  Plug 'vim-scripts/cmdalias.vim'
  " Plug 'Shougo/unite.vim'
  Plug 'Shougo/echodoc.vim'
  Plug 'andyl/vim-textobj-elixir'
  Plug 'kana/vim-textobj-user'
  Plug 'justinmk/vim-dirvish'
  Plug 'pbogut/dbext.vim'
  Plug 'w0rp/ale'
  Plug 'wakatime/vim-wakatime'

  " testing
  Plug 'sbdchd/neoformat'
  Plug 'vimwiki/vimwiki'
  Plug 'MattesGroeger/vim-bookmarks'
  Plug 'vim-scripts/ReplaceWithRegister'
  Plug 'kassio/neoterm'
  Plug 'beloglazov/vim-textobj-quotes'

  Plug 'lvht/phpcd.vim', { 'for': 'php', 'do': 'composer install' }
  Plug 'joereynolds/gtags-scope'

  if has('nvim')
    Plug 'autozimu/LanguageClient-neovim', { 'do': ':UpdateRemotePlugins' }
    Plug 'Shougo/denite.nvim', { 'do': ':UpdateRemotePlugins' }
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
    Plug 'Shougo/neco-vim', { 'for': 'vim' }
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'
    Plug 'pbogut/fzf-mru.vim'
    Plug 'slashmili/alchemist.vim', { 'for': ['elixir', 'eelixir'] }
    Plug 'powerman/vim-plugin-AnsiEsc', { 'for': ['elixir', 'eelixir'] }
    Plug 'zchee/deoplete-go', { 'do': 'go get github.com/nsf/gocode && make', 'for': 'go'}
    Plug 'zchee/deoplete-zsh', { 'for': 'zsh' }
    Plug 'zchee/deoplete-jedi', { 'for': 'python' }
    Plug 'padawan-php/deoplete-padawan', { 'for': 'php' }
    Plug 'pbogut/deoplete-elm', { 'for': 'elm' }
    Plug 'carlitux/deoplete-ternjs', { 'for': ['javascript', 'javascript.jsx'], 'do': 'yarn global add tern' }
    " Plug 'roxma/nvim-completion-manager'
    " Plug 'autozimu/LanguageClient-neovim', { 'do': ':UpdateRemotePlugins' }
    " Plug 'roxma/LanguageServer-php-neovim',  {'do': 'composer install && composer run-script parse-stubs'}
  endif " if Plug installed
  if (!has('nvim') || $STY != '')
    Plug 'altercation/vim-colors-solarized'
  else
    set termguicolors
    Plug 'frankier/neovim-colors-solarized-truecolor-only'
  endif
  Plug 'sheerun/vim-polyglot'
endif "
silent! call plug#end()      " requiredc
filetype plugin indent on    " required
silent! colorscheme solarized
"
source ~/.vim/plugin/config/airline.vimrc
source ~/.vim/plugin/config/ale.vimrc
source ~/.vim/plugin/config/autoformat.vimrc
source ~/.vim/plugin/config/autopairs.vimrc
source ~/.vim/plugin/config/bookmarks.vimrc
source ~/.vim/plugin/config/composer.vimrc
source ~/.vim/plugin/config/denite.vimrc
source ~/.vim/plugin/config/deoplete.vimrc
source ~/.vim/plugin/config/dirvish.vimrc
source ~/.vim/plugin/config/fzf.vimrc
source ~/.vim/plugin/config/gutentags.vimrc
" source ~/.vim/plugin/config/neomake.vimrc
source ~/.vim/plugin/config/projectionist.vimrc
source ~/.vim/plugin/config/switch.vimrc
source ~/.vim/plugin/config/terminal.vimrc

augroup after_load
  autocmd!
  autocmd VimEnter *
        \  source ~/.vim/plugin/config/abolish.vimrc
        \| source ~/.vim/plugin/config/cmdalias.vimrc
augroup END

" nicer vertical split
hi VertSplit guibg=#073642 guifg=fg

" vdebug
let g:vdebug_keymap = {
      \    "run" : "<leader>vr",
      \    "run_to_cursor" : "<leader>vc",
      \    "step_over" : "<leader>vn",
      \    "step_into" : "<leader>vi",
      \    "step_out" : "<leader>vo",
      \    "close" : "<leader>vq",
      \    "detach" : "<leader>vd",
      \    "set_breakpoint" : "<leader>vb",
      \    "get_context" : "<leader>vx",
      \    "eval_under_cursor" : "<leader>ve",
      \    "eval_visual" : "<leader>vv",
      \}

" ansi esc
let g:no_plugin_maps = 1
" vim polyglot
let g:polyglot_disabled = ['eelixir', 'elixir']
" closetag
let g:closetag_filenames = "*.html,*.xhtml,*.phtml,*.xml,*.blade.php,*.html.eex"
" notes
let g:notes_directories = [ $HOME . "/Notes/" ]
" projectroot
let g:rootmarkers = ['.projectroot', '.git', '.hg', '.svn', '.bzr',
      \ '_darcs', 'build.xml', 'composer.json', 'mix.exs']
" macros
nnoremap <leader>em :tabnew ~/.vim/macros.vim<cr>
nnoremap <leader>sm :source ~/.vim/macros.vim<cr>
" edit vimrc/zshrc and load vimrc bindings
nnoremap <leader>ev :tabnew $MYVIMRC<CR>
nnoremap <leader>ez :tabnew ~/.zshrc<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>
" open list / quickfix
nnoremap <silent> <leader>l :call local#togglelist#locationlist()<cr>
nnoremap <silent> <leader>q :call local#togglelist#quickfixlist()<cr>

nnoremap <silent> <bs> :Dirvish %:p:h<cr>
nnoremap <silent> _ :Dirvish %:p:h<cr>
nnoremap <silent> <leader>n :TagbarOpenAutoClose<cr>
" fzf
nnoremap <silent> <leader>w :W!<cr>
nnoremap <silent> <leader>a :Neoformat<cr>
nnoremap <silent> <leader>z za
nnoremap <silent> <esc> :set nohls<cr>
nnoremap R ddO
nnoremap n :set hls<cr>n
nnoremap N :set hls<cr>N
" selection mode (for easy snippets parts move)
" removes selection as block
smap <c-d> <esc>`<V`>x
smap <c-c> <esc>`<V`>c
" removes selection as it is
smap <c-x> <esc>gvd
smap <c-s> <esc>gvc
" append to selection
smap <c-a> <esc>a
" nnoremap <silent> <leader>z :call PHP__Fold()<cr>
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
" remap delete to c-d because on hardware level Im sending del when c-d (ergodox)
nmap <silent> <del> <c-d>
map <silent> <C-w>d :silent! Bdelete<cr>
map <silent> <C-w>D :silent! Bdelete!<cr>
" more natural split (always right/below)
nmap <silent> <c-w>v :rightbelow vsplit<cr>
nmap <silent> <c-w>s :rightbelow split<cr>
" just in case I want old behaviour from time to time
nmap <silent> <c-w>V :vsplit<cr>
nmap <silent> <c-w>S :split<cr>
map Y y$
nnoremap <leader> "*
vnoremap <leader> "*
nmap yaf :let @+=expand('%:p')<bar>echo 'Yanked: '.expand('%:p')<cr>
nmap yif :let @+=expand('%:t')<bar>echo 'Yanked: '.expand('%:t')<cr>

" nicer wrapline navigation
for [key1, key2] in [['j', 'gj'], ['k', 'gk']]
  for maptype in ['noremap', 'vnoremap', 'onoremap']
    execute(maptype . ' <silent> ' . key1 . ' ' . key2)
    execute(maptype . ' <silent> ' . key2 . ' ' . key1)
  endfor
endfor

" nice to have
inoremap <c-d> <del>
cnoremap <c-d> <del>
" vim-test
nmap <silent> <leader>tn :call FixTestFileMod() <bar> TestNearest<CR>
nmap <silent> <leader>tf :call FixTestFileMod() <bar> TestFile<CR>
nmap <silent> <leader>ts :call FixTestFileMod() <bar> TestSuite<CR>
nmap <silent> <leader>tl :call FixTestFileMod() <bar> TestLast<CR>
nmap <silent> <leader>tt :call FixTestFileMod() <bar> TestLast<CR>
nmap <silent> <leader>tv :call FixTestFileMod() <bar> TestVisit<CR>
function! FixTestFileMod() abort
  if &ft == 'elixir'
    let g:test#filename_modifier = ':p'
  elseif (!empty(get(g:, 'test#filename_modifier')))
    unlet g:test#filename_modifier
  endif
endfunction
" regex helpers
cnoremap \\* \(.*\)
cnoremap \\- \(.\{-}\)
" prevent pasting in visual from yank seletion
snoremap p "_dP
vnoremap p "_dP
" case insensitive search by default
nnoremap / :let @/=""<cr>:set hls<cr>/\c
nnoremap ? :let @/=""<cr>:set hls<cr>?\c
nnoremap * :set hls<cr>*
nnoremap # :set hls<cr>#
nnoremap <leader><leader> :let @/='\<<c-r><c-w>\>'<cr>:set hls<cr>
nnoremap <silent> <leader>= migg=G`i
nmap <silent> <leader>gp <Plug>GitGutterPreviewHunk<bar>:exec('wincmd j')<bar>:exec('nnoremap q :wincmd q<lt>cr>')<cr>
nmap <silent> <leader>gu <Plug>GitGutterUndoHunk
nmap <silent> <leader>gs <Plug>GitGutterStageHunk
" keep ga functionality as gas
nnoremap gas ga
" Sideways
nmap <silent> ga< :SidewaysLeft<cr>
nmap <silent> ga> :SidewaysRight<cr>
nmap <silent> gap :SidewaysJumpLeft<cr>
nmap <silent> gan :SidewaysJumpRight<cr>
omap <silent> aa <plug>SidewaysArgumentTextobjA
xmap <silent> aa <plug>SidewaysArgumentTextobjA
omap <silent> ia <plug>SidewaysArgumentTextobjI
xmap <silent> ia <plug>SidewaysArgumentTextobjI
inoremap <C-Space> <c-x><c-o>
imap <C-@> <C-Space>
" emmet
imap <c-e> <c-y>,

if has('nvim')
  nnoremap <silent> <leader>fm :execute(':FZFFreshMru '. g:fzf_preview)<cr>
  nnoremap <silent> <leader>fa :call local#fzf#files()<cr>
  nnoremap <silent> <leader>fp :FZFProject<cr>
  nnoremap <silent> <leader>fc :call local#fzf#clip()<cr>
  nnoremap <silent> <leader>fd :call local#fzf#buffer_dir_files()<cr>
  nnoremap <silent> <leader>ff :call local#fzf#all_files()<cr>
  nnoremap <silent> <leader>fg :call local#fzf#git_ls()<cr>
  nnoremap <silent> <leader>ft :FZFTags <cword><cr>
  nnoremap <silent> <leader>] :FZFTags<cr>
  nnoremap <silent> <leader>fb :FZFBuffers<cr>
  nnoremap <silent> <leader>gf :call local#fzf#files(expand('<cfile>'))<cr>
  nnoremap <silent> <leader>gF :call local#fzf#all_files(expand('<cfile>'))<cr>
  nnoremap <silent> <leader>gt :call fzf#vim#tags(expand('<cword>'))<cr>
  nnoremap <silent> <leader>gw :Rg <cword><cr>
  nnoremap <silent> <leader>ga :Ag<cr>
  nnoremap <silent> <leader>gr :Rg<cr>
  vnoremap <silent> <leader>ga "ay :Ag <c-r>a<cr>
  vnoremap <silent> <leader>gr "ay :Rg <c-r>a<cr>

  nnoremap <silent> <leader>of :let g:pwd = expand('%:h') \| belowright 20split \| enew \| call termopen('cd ' . g:pwd . ' && zsh') \| startinsert<cr>
  nnoremap <silent> <leader>op :let g:pwd = projectroot#guess() \| belowright 20split \| enew \| call termopen('cd ' . g:pwd . ' && zsh') \| startinsert<cr>
  nnoremap <silent> <leader>ov :belowright 20split \| terminal vagrant ssh<cr>

  noremap <leader>sc :execute(':rightbelow 10split \| te scspell %')<cr>

  " nvim now can map alt without terminal issues, new cool shortcuts commin
  tnoremap <silent> <c-q> <C-\><C-n>

  noremap <silent> <M-l> :vertical resize +1<cr>
  noremap <silent> <M-h> :vertical resize -1<cr>
  noremap <silent> <M-j> :resize +1<cr>
  noremap <silent> <M-k> :resize -1<cr>

  cnoremap <A-k> <Up>
  cnoremap <A-j> <Down>
endif

for keys in ['w', 'iw', 'aw', 'e', 'W', 'iW', 'aW']
  if keys == 'w' | let motion = 'e' | else | let motion = keys | endif
  " quick change and search for naxt, change can be repeaded by . N and n will
  " search for the same selection, gn gN will select same selection
  exe('nnoremap cg' . keys . ' y' . motion . ':exe("let @/=@+")<bar><esc>cgn')
  exe('nnoremap <leader>s' . keys . ' y' . motion . ':s/<c-r>+//g<left><left>')
endfor

nmap <silent> grr :Rg<cr>
nmap <silent> grq :Rgg<cr>
nmap <silent> gr :set opfunc=<sid>ripgrep_from_motion<CR>g@
function! s:ripgrep_from_motion(type, ...)
  let l:tmp = @a
  if a:0  " Invoked from Visual mode, use '< and '> marks.
    silent exe("normal! `<" . a:type . "`>\"ay")
  elseif a:type == 'line'
    silent exe "normal! '[V']\"ay"
  elseif a:type == 'block'
    silent exe "normal! `[\<C-V>`]\"ay"
  else
    silent exe "normal! `[v`]\"ay"
  endif
  exe("Rg " . @a)
  let @a = l:tmp
endfunction

nmap <leader><cr> za
vmap <leader><cr> zf

" quick set
nnoremap <leader>s  :set
nnoremap <leader>sf :set filetype=
nnoremap <leader>ss :set spell!<cr>
nnoremap <leader>sp :set paste!<cr>

nnoremap <leader>S :call SpellCheckToggle()<cr>
function! SpellCheckToggle()
  let b:spell_check = get(b:, 'spell_check', 0)
  if b:spell_check == 1
    let b:spell_check = 0
    execute(':set syntax=' . b:syntax)
    hi SpellBad guifg=NONE
    set nospell
  else
    let b:syntax = &syntax
    let b:spell_check = 1
    set syntax=
    hi SpellBad guifg=lightred
    set spell
  endif
endfunction

" global variables used by modules {{{
" better key bindings for UltiSnipsExpandTrigger
let g:UltiSnipsExpandTrigger = "<tab>"
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"

let g:UltiSnipsSnippetDirectories=["UltiSnips", "mysnippets", "mytemplates"]
" eclim
let g:EclimFileTypeValidate = 0
let g:EclimCompletionMethod = 'omnifunc'
let g:strip_whitespace_on_save = 1

let g:formatdef_blade = '"html-beautify -s ".&shiftwidth'
let g:formatters_blade = ['blade']
let g:formatdef_elixir = '"mix format -"'
let g:formatters_elixir = ['elixir']

" despatch hax to not cover half screen
let g:dispatch_quickfix_height = 10
let g:dispatch_tmux_height = 1
" }}}
" custom commands
" close all buffers but current
command! BCloseAll execute "%bd"
command! BCloseOther execute "%bd | e#"
command! BCloseOtherForce execute "%bd! | e#"

"Git
command! Gan execute "!git an %"
function! s:gap()
  let file = expand('%')
  belowright 30split
  enew
  exec "te git ap " . file
endfunction
command! Gap call s:gap()

" tabularize shortcut alias
command! -nargs=* -range T Tabularize <args>

command! Grevert
            \  execute ":Gread"
            \| execute ":noautocmd w"
            \| execute ":GitGutter"

command! -nargs=1 PhpDoc split
    \| silent! execute("e phpdoc://<args>")
    \| silent! setlocal noswapfile
    \| silent! setlocal ft=php
    \| silent! setlocal syntax=man
    \| silent! execute("read !psysh <<< 'doc <args>' | head -n -2 | tail -n +2")
    \| silent! execute("normal! ggdd")
    \| silent! setlocal buftype=nofile
    \| silent! setlocal nomodifiable
    \| silent! map <buffer> q :q<cr>

let g:test#strategy = 'neovim'

let g:paranoic_backup_dir="~/.vim/backupfiles/"

command! -bang W :call CreateFoldersAndWrite(<bang>0)
function! CreateFoldersAndWrite(bang)
  silent execute('!mkdir -p %:h')
  try
    if (a:bang)
      execute(':w!')
    else
      execute(':w')
    endif
  catch "E166: Can't open linked file for writing"
    redraw!
    let sudo_write = confirm(
          \ "Can't open linked file for writing, should I try SudoWrite?",
          \ "&Yes\n&No", 2)
    " call inputrestore()
    if sudo_write == 1
      SudoWrite
    endif
  endtry
endfunction
" disable double save (cousing file watchers issues)

" fold adjust
" remove underline
hi Folded term=NONE cterm=NONE gui=NONE
" new fold                   style
function! NeatFoldText()
  let line = ' ' . substitute(getline(v:foldstart), '^\s*"\?\s*\|\s*"\?\s*{{' . '{\d*\s*', '', 'g') . ' '
  let line = ' ' . substitute(getline(v:foldstart), '^\s*"\?\s*\|\s*"\?\s*{{' . '{\d*\s*', '', 'g') . ' '
  let line = ' ' . substitute(getline(v:foldstart), '^\s\s\s\s', '', 'g') . ' '
  let g:line = line
  let lines_count = v:foldend - v:foldstart + 1
  let lines_count_text = '| ' . printf("%10s", lines_count . ' lines') . ' |'
  " let foldchar = matchstr(&fillchars, 'fold:\zs.')
  let foldchar = ' ' " use the space
  let winwidth = winwidth(0)
  if l:winwidth > 88
    let winwidth = 88
  endif
  let foldtextstart = strpart('+++' . repeat(foldchar, v:foldlevel*3) . line, 0, (l:winwidth*2)/3)
  let foldtextstart = strpart('+++' . line, 0, (l:winwidth*2)/3)
  let foldtextend = lines_count_text . repeat(foldchar, 8)
  let foldtextlength = strlen(substitute(foldtextstart . foldtextend, '.', 'x', 'g')) + &foldcolumn
  return foldtextstart . repeat(foldchar, l:winwidth-foldtextlength) . foldtextend
endfunction
set foldtext=NeatFoldText()

augroup set_title_group
    autocmd!
    autocmd BufEnter * call s:set_title_string()
augroup END
function! s:set_title_string()
  let file = expand('%:~')
  if file == ""
    let file = substitute(getcwd(),$HOME,'~', 'g')
  endif
  if empty($SSH_CLIENT) && empty($SSH_TTY)
    let &titlestring = $USER . '@' . hostname() . ":nvim:" . substitute($NVIM_LISTEN_ADDRESS, '/tmp/nvim\(.*\)\/0$', '\1', 'g') . ":" . l:file
  else
    let &titlestring = $USER . '@' . hostname() . ":nvim:" . l:file
  endif
endfunction
let &titlestring = $USER . '@' . hostname() . ":nvim:" . substitute($NVIM_LISTEN_ADDRESS, '/tmp/nvim\(.*\)\/0$', '\1', 'g') . ":" . substitute(getcwd(),$HOME,'~', 'g')
set title

let g:snips_author = "Pawel Bogut"
let g:snips_author_url = "http://pbogut.me"
let g:snips_github = "https://github.com/pbogut"

silent! exec(":source ~/.vim/" . hostname() . ".vim")

" nnoremap <silent> K :call LanguageClient_textDocument_hover()<CR>
" nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
" nnoremap <silent> <F2> :call LanguageClient_textDocument_rename()<CR>

" vimwiki
let g:vimwiki_map_prefix = '-w'
let g:vimwiki_list = [{'path': '~/pawel.bogut@gmail.com/vimwiki/',
                     \ 'syntax': 'markdown', 'ext': '.md'}]

" replace with register
nmap cp <Plug>ReplaceWithRegisterOperator
nmap cP cp$
nmap cp= cpp==
nmap cpp <Plug>ReplaceWithRegisterLine
xmap cp <Plug>ReplaceWithRegisterVisual

let g:prosession_per_branch = 1
