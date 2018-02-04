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
set termguicolors
set background=dark
set guicursor=n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor

if exists('&inccommand') | set inccommand=split | endif
if has("patch-7.4.314") | set shortmess+=c | endif
if executable('ag') | set grepprg=ag | endif
if executable('rg')
  set grepprg=rg\ --vimgrep\ --no-heading
  set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

" Keep mapleader as backspack "\" for plugins not mess with my space leader
" let mapleader = "\<space>" " life changer

augroup configgroup_nvim
  autocmd!
  " fix terminal display
  autocmd TermOpen *
        \  :silent! normal! <c-\><c-n>a
  " \| setlocal nocursorline
  " \| setlocal nocursorcolumn
augroup END
augroup configgroup
  autocmd!
  autocmd BufRead,BufNewFile *.phtml
        \  setfiletype php.phtml
  autocmd FileType *
        \  call matchadd('Todo', '@todo\>')
        \| call matchadd('Todo', '@fixme\>')
  autocmd FileType html
        \  call s:set_indent(4, v:false, v:true)
  autocmd FileType vue
        \  call s:set_indent(2, v:false, v:true)
  autocmd FileType javascript
        \  call s:set_indent(2, v:false, v:true)
  autocmd FileType elixir
        \  call s:set_indent(2, v:false, v:true)
  autocmd FileType elm
        \  call s:set_indent(4, v:false, v:true)
        \| setlocal makeprg=elm-make
        \| let b:my_make_cmd = "elm-make --warn --output /dev/null {file_name}"
  autocmd FileType c
        \  setlocal tabstop=4 shiftwidth=4
  autocmd FileType php
        \| call s:set_indent(4, v:false, v:true)
        \| let b:commentary_format='// %s'
        \| nmap <buffer> gD <plug>(composer-find)
        \| setlocal kp=:PhpDoc
        \| exec("map cgget mz0wwwyw/getters<cr>jo/**<cr>Gets <esc>pb~yiwo<cr>@return mixed<cr><cr>/<cr>public function get<esc>pa()<cr>{<cr>return $this-><esc>pb~A;<esc>jo<esc>`zj")
        \| exec("map cgset mz0wwwyw/setters<cr>jo/**<cr>Sets <esc>pb~yiwo<cr>@return $this<cr><cr>/<cr>public function set<esc>pa(<esc>pbi$<esc>~~ea)<cr>{<cr>$this-><esc>pb~A = $<esc>pb~A;<cr>return $this;<esc>jo<esc>`zj")
  autocmd FileType php.phtml
        \  call s:set_indent(4, v:false, v:true)
        \| let b:commentary_format='<?php /* %s */ ?>'
  autocmd FileType go
        \  call s:set_indent(2, v:true, v:true)
  " \| setlocal tabstop=2 shiftwidth=2
  " autocmd FileType ruby
  "       \  setlocal tabstop=2 shiftwidth=2
  autocmd FileType vim
        \  call s:set_indent(2, v:false, v:true)
        \| let b:neoformat_basic_format_align = 1
  "       \| setlocal kp=:help
  " autocmd FileType xml
  "       \  setlocal tabstop=4 shiftwidth=4
  autocmd FileType sh
        \  call s:set_indent(2, v:false, v:true)
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
        \|   execute('normal kJk')
        \|   execute('r !gpg-config get gmail-user')
        \|   execute('normal kJk$p')
        \|   execute('normal kJ')
        \| endif
  autocmd FileType tagbar
        \  nmap <buffer> <space>n q
  autocmd  FileType fzf
        \  set laststatus=0 noshowmode noruler
        \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler
  autocmd InsertLeave *
        \ if &buftype == 'acwrite' | execute('WidenRegion') | endif
  " always show gutter column to avoid blinking and jumping
  " autocmd BufEnter *
  "       \  execute('sign define dummy')
  "       \| execute('sign place 98913 line=1 name=dummy buffer=' . bufnr(''))
  autocmd BufWritePre *
        \  silent! Format auto
  autocmd BufWritePost *
        \  silent! Whitespace
augroup END

silent! call plug#begin()
if exists(':Plug')
  Plug 'pbogut/dbext.vim'
  let g:dbext_map_prefix = '\s'
  Plug 'vim-ruby/vim-ruby', { 'for': 'ruby' }
  Plug 'xolox/vim-misc'
  Plug 'xolox/vim-notes'
  let g:notes_directories = [ $HOME . "/Notes/" ]
  Plug 'tpope/vim-scriptease'
  " Plug 'tpope/vim-fugitive'
  Plug 'pbogut/vim-fugitive'
  Plug 'tpope/vim-eunuch'
  Plug 'tpope/vim-git'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-surround'
  vmap s S
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-rails', { 'for': 'ruby' }
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-unimpaired'
  Plug 'tpope/vim-obsession'
  Plug 'tpope/vim-abolish'
  autocmd User after_vim_load source ~/.vim/plugin/config/abolish.vimrc
  Plug 'tpope/vim-projectionist'
  source ~/.vim/plugin/config/projectionist.vimrc
  Plug 'dhruvasagar/vim-prosession'
  let g:prosession_per_branch = 1
  Plug 'vim-airline/vim-airline'
  source ~/.vim/plugin/config/airline.vimrc
  Plug 'vim-airline/vim-airline-themes'
  Plug 'airblade/vim-gitgutter'
  source ~/.vim/plugin/config/gitgutter.vim
  Plug 'MarcWeber/vim-addon-mw-utils'
  Plug 'ludovicchabant/vim-gutentags'
  source ~/.vim/plugin/config/gutentags.vimrc
  Plug 'gioele/vim-autoswap'
  Plug 'ntpeters/vim-better-whitespace'
  let g:strip_whitespace_on_save = 0 " Use Whitespace wrapper instead
  Plug 'honza/vim-snippets'
  Plug 'mattn/emmet-vim'
  imap <c-e> <c-y>,
  Plug 'majutsushi/tagbar'
  nnoremap <silent> <space>n :TagbarOpenAutoClose<cr>
  Plug 'sirver/ultisnips'
  source ~/.vim/plugin/config/ultisnips.vim
  Plug 'joonty/vdebug', { 'on': 'PlugLoadVdebug' }
  source ~/.vim/plugin/config/vdebug.vim
  Plug 'sbdchd/neoformat'
  let g:neoformat_only_msg_on_error = 1
  Plug 'k-takata/matchit.vim'
  Plug 'captbaritone/better-indent-support-for-php-with-html', { 'for': 'php' }
  Plug 'noahfrederick/vim-composer', { 'for': 'php' }
  Plug 'janko-m/vim-test'
  source ~/.vim/plugin/config/test.vim
  Plug 'elmcast/elm-vim', { 'for': 'elm' }
  Plug 'pbogut/vim-elmper', { 'for': 'elm' }
  let g:elm_format_autosave = 0
  Plug 'elixir-lang/vim-elixir', { 'for': ['elixir', 'eelixir'] }
  Plug 'kana/vim-operator-user'
  Plug 'moll/vim-bbye', { 'on': 'Bdelete' }
  Plug 'will133/vim-dirdiff'
  Plug 'dbakker/vim-projectroot'
  let g:rootmarkers = ['.projectroot', '.git', '.hg', '.svn', '.bzr',
        \ '_darcs', 'build.xml', 'composer.json', 'mix.exs']
  Plug 'AndrewRadev/switch.vim'
  autocmd User after_plug_end source ~/.vim/plugin/config/switch.vimrc
  Plug 'AndrewRadev/splitjoin.vim'
  Plug 'AndrewRadev/sideways.vim'
  source ~/.vim/plugin/config/sideways.vim
  Plug 'godlygeek/tabular'
  command! -nargs=* -range T Tabularize <args>
  Plug 'vim-scripts/cmdalias.vim'
  autocmd User after_vim_load source ~/.vim/plugin/config/cmdalias.vimrc
  " Plug 'Shougo/unite.vim'
  Plug 'Shougo/echodoc.vim'
  Plug 'andyl/vim-textobj-elixir'
  Plug 'kana/vim-textobj-user'
  Plug 'justinmk/vim-dirvish'
  source ~/.vim/plugin/config/dirvish.vimrc
  Plug 'w0rp/ale'
  autocmd User after_plug_end source ~/.vim/plugin/config/ale.vimrc
  autocmd User after_vim_load
        \  highlight ALEErrorSign guibg=#073642 guifg=#dc322f
        \| highlight ALEWarningSign guibg=#073642 guifg=#d33682
  Plug 'wakatime/vim-wakatime'
  Plug 'vimwiki/vimwiki', { 'branch': 'dev' }
  let g:vimwiki_map_prefix = '-w'
  let g:vimwiki_list = [{'path': '~/pawel.bogut@gmail.com/vimwiki/',
        \ 'syntax': 'markdown', 'ext': '.md'}]
  Plug 'vim-scripts/ReplaceWithRegister'
  source ~/.vim/plugin/config/replacewithregister.vim
  Plug 'beloglazov/vim-textobj-quotes'
  Plug 'lvht/phpcd.vim', { 'for': 'php', 'do': 'composer install' }
  Plug 'joereynolds/gtags-scope'
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
  source ~/.vim/plugin/config/deoplete.vimrc
  Plug 'Shougo/neco-vim', { 'for': 'vim' }
  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim'
  Plug 'pbogut/fzf-mru.vim'
  source ~/.vim/plugin/config/fzf.vimrc
  Plug 'slashmili/alchemist.vim', { 'for': ['elixir', 'eelixir'] }
  Plug 'powerman/vim-plugin-AnsiEsc', { 'for': ['elixir', 'eelixir'] }
  Plug 'zchee/deoplete-go', { 'do': 'go get github.com/nsf/gocode && make', 'for': 'go'}
  Plug 'zchee/deoplete-zsh', { 'for': 'zsh' }
  Plug 'zchee/deoplete-jedi', { 'for': 'python' }
  Plug 'padawan-php/deoplete-padawan', { 'for': 'php' }
  Plug 'pbogut/deoplete-elm', { 'for': 'elm' }
  Plug 'carlitux/deoplete-ternjs', { 'for': ['javascript', 'javascript.jsx'], 'do': 'yarn global add tern' }
  Plug 'frankier/neovim-colors-solarized-truecolor-only'
  Plug 'sheerun/vim-polyglot'
  let g:polyglot_disabled = ['eelixir', 'elixir']
endif "
silent! call plug#end()      " requiredc
filetype plugin indent on    " required

doautocmd User after_plug_end
autocmd! User after_plug_end " clear after_plug_end command list

augroup after_load
  autocmd!
  autocmd VimEnter *
        \  doautocmd User after_vim_load
        \| autocmd! User after_vim_load " clear after_plug_end command list
augroup END

silent! colorscheme solarized
"
source ~/.vim/plugin/config/autopairs.vimrc
source ~/.vim/plugin/config/composer.vimrc
source ~/.vim/plugin/config/terminal.vimrc

" nicer vertical split
hi VertSplit guibg=#073642 guifg=fg

" dont mess with me!
let g:no_plugin_maps = 1

" macros
nnoremap <space>em :tabnew ~/.vim/macros.vim<cr>
nnoremap <space>sm :source ~/.vim/macros.vim<cr>
" edit vimrc/zshrc and load vimrc bindings
nnoremap <space>ev :tabnew $MYVIMRC<CR>
nnoremap <space>ez :tabnew ~/.zshrc<CR>
nnoremap <space>sv :source $MYVIMRC<CR>
" open list / quickfix
nnoremap <silent> <space>l :call local#togglelist#locationlist()<cr>
nnoremap <silent> <space>q :call local#togglelist#quickfixlist()<cr>

nnoremap <silent> <bs> :Dirvish %:p:h<cr>
nnoremap <silent> _ :Dirvish %:p:h<cr>
nnoremap <silent> <space>w :W!<cr>
nnoremap <silent> <space>a :Format<cr>
nnoremap <silent> <space>z za
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
" nnoremap <silent> <space>z :call PHP__Fold()<cr>
" vim is getting ^_ when pressing ^/, so I've mapped both
nmap <C-_> gcc<down>^
nmap <C-/> gcc<down>^
vmap <C-_> gc
vmap <C-/> gc
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
nnoremap <space> "*
vnoremap <space> "*
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
" vim make
nmap <space>mf <space>w:call QuickTerm(substitute(b:my_make_cmd, '{file_name}', expand('%'), ''))<cr>
nmap <space>ms <space>w:make<cr>
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
nnoremap <space><space> *``:set hls<cr>
nnoremap <silent> <space>= migg=G`i
inoremap <C-Space> <c-x><c-o>
imap <C-@> <C-Space>

nnoremap <silent> <space>fm :execute(':FZFFreshMru '. g:fzf_preview)<cr>
nnoremap <silent> <space>fa :call local#fzf#files()<cr>
nnoremap <silent> <space>fp :FZFProject<cr>
nnoremap <silent> <space>fc :call local#fzf#clip()<cr>
nnoremap <silent> <space>fd :call local#fzf#buffer_dir_files()<cr>
nnoremap <silent> <space>ff :call local#fzf#all_files()<cr>
nnoremap <silent> <space>fg :call local#fzf#git_ls()<cr>
nnoremap <silent> <space>ft :FZFTags <cword><cr>
nnoremap <silent> <space>] :FZFTags<cr>
nnoremap <silent> <space>fb :FZFBuffers<cr>
nnoremap <silent> <space>gf :call local#fzf#files(expand('<cfile>'))<cr>
nnoremap <silent> <space>gF :call local#fzf#all_files(expand('<cfile>'))<cr>
nnoremap <silent> <space>gt :call fzf#vim#tags(expand('<cword>'))<cr>
nnoremap <silent> <space>gw :Rg <cword><cr>
nnoremap <silent> <space>ga :Ag<cr>
nnoremap <silent> <space>gr :Rg<cr>
vnoremap <silent> <space>ga "ay :Ag <c-r>a<cr>
vnoremap <silent> <space>gr "ay :Rg <c-r>a<cr>

nnoremap <silent> <space>of :let g:pwd = expand('%:h') \| belowright 20split \| enew \| call termopen('cd ' . g:pwd . ' && zsh') \| startinsert<cr>
nnoremap <silent> <space>op :let g:pwd = projectroot#guess() \| belowright 20split \| enew \| call termopen('cd ' . g:pwd . ' && zsh') \| startinsert<cr>
nnoremap <silent> <space>ov :belowright 20split \| terminal vagrant ssh<cr>

noremap <space>sc :execute(':rightbelow 10split \| te scspell %')<cr>

" nvim now can map alt without terminal issues, new cool shortcuts commin
tnoremap <silent> <c-q> <C-\><C-n>

noremap <silent> <M-l> :vertical resize +1<cr>
noremap <silent> <M-h> :vertical resize -1<cr>
noremap <silent> <M-j> :resize +1<cr>
noremap <silent> <M-k> :resize -1<cr>

cnoremap <A-k> <Up>
cnoremap <A-j> <Down>

for keys in ['w', 'iw', 'aw', 'e', 'W', 'iW', 'aW']
  if keys == 'w' | let motion = 'e' | else | let motion = keys | endif
  " quick change and search for naxt, change can be repeaded by . N and n will
  " search for the same selection, gn gN will select same selection
  exe('nnoremap cg' . keys . ' y' . motion . ':exe("let @/=@+")<bar><esc>cgn')
  exe('nnoremap <space>s' . keys . ' y' . motion . ':s/<c-r>+//g<left><left>')
  exe('nnoremap <space>%' . keys . ' y' . motion . ':%s/<c-r>+//g<left><left>')
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

nmap <space><cr> za
vmap <space><cr> zf

" quick set
nnoremap <space>s  :set
nnoremap <space>sf :FZFFileType<cr>
nnoremap <space>ss :set spell!<cr>
nnoremap <space>sp :set paste!<cr>

nnoremap <space>S :call SpellCheckToggle()<cr>
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

" custom commands
" close all buffers but current
command! BCloseAll execute "%bd"
command! BCloseOther execute "%bd | e#"
command! BCloseOtherForce execute "%bd! | e#"

"Git
command! Gan execute "!git an %"
function! s:gap()
  let file = expand('%:p')
  belowright 30split
  enew
  exec "te git ap " . file
  startinsert
endfunction
command! Gap call s:gap()

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
    let &titlestring = $USER . '@' . hostname() . ":nvim:" . substitute($NVIM_LISTEN_ADDRESS, $TMPDIR . '/nvim\(.*\)\/0$', '\1', 'g') . ":" . l:file
  else
    let &titlestring = $USER . '@' . hostname() . ":nvim:" . l:file
  endif
endfunction
let &titlestring = $USER . '@' . hostname() . ":nvim:" . substitute($NVIM_LISTEN_ADDRESS, $TMPDIR . '/nvim\(.*\)\/0$', '\1', 'g') . ":" . substitute(getcwd(),$HOME,'~', 'g')
set title

function! s:set_indent(width, ...) " width:int, hardtab:bool, init:bool
  let l:hardtab = get(a:000, 0, v:false)
  let l:init = get(a:000, 1, v:false)

  if l:init && get(b:, 'Set_indent_inited', v:false) " init only once
    return
  elseif l:init
    let b:Set_indent_inited = v:true
  endif

  " show existing tab with spaces
  let &tabstop = a:width
  " when indenting with '>', use 2 spaces width
  let &shiftwidth = a:width
  " On pressing tab, insert 2 spaces
  if empty(l:hardtab)
    set expandtab
  else
    set noexpandtab
  end
endfunction
command! -bang -nargs=1 SetIndentWidth call s:set_indent(<args>, <bang>0)


let g:neoformat_vimwiki_prettier = {
      \ 'exe': 'prettier',
      \ 'args': ['--stdin', '--stdin-filepath', '%:p'],
      \ 'stdin': 1,
      \ }

let g:neoformat_enabled_vimwiki = ['prettier']
function! s:format(...)
  let g:neoformat_run_all_formatters = get(b:, 'neoformat_run_all_formatters')
  let g:neoformat_basic_format_align = get(b:, 'neoformat_basic_format_align')
  let g:neoformat_basic_format_trim = get(b:, 'neoformat_basic_format_trim')
  let l:disabled = !empty(get(b:, 'neoformat_disable_on_save'))
        \ || !empty(get(g:, 'neoformat_disable_on_save'))

  if a:0 && a:1 == "auto" && l:disabled
    return
  endif

  if !empty(get(b:, 'neoformat_disabled'))
    return
  endif

  silent! Neoformat
endfunction
command! -nargs=? Format call s:format(<q-args>)
command! -bang FormatOnSaveDisable :exec 'let ' . (empty("<bang>") ? 'b' : 'g' ) . ':neoformat_disable_on_save = 1'
command! -bang FormatOnSaveEnable :exec 'unlet ' . (empty("<bang>") ? 'b' : 'g' ) . ':neoformat_disable_on_save'

function! s:whitespace()
  if !empty(get(b:, 'whitespace_trim_disabled'))
    return
  endif

  silent! StripWhitespace
endfunction
command! Whitespace call s:whitespace()

nmap <C-_> :call Comment()<cr><down>
nmap <C-/> :call Comment()<cr><down>
vmap <C-_> :call Comment()<cr><down>
vmap <C-/> :call Comment()<cr><down>

function! Comment()
  if &ft == 'php.phtml'
    if Phtml_scope() == 'php'
      let b:commentary_format = '/* %s */'
    else
      let b:commentary_format = '<?php /* %s */ ?>'
    endif
  endif
  normal gcc
endfunction

function! Phtml_scope()
  let [l1, c1] = searchpos('?>', 'bnW')
  let [l2, c2] = searchpos('<?php', 'bnW')

  if l1 < l2 || l1 == l2 && c1 < c2
    return 'php'
  else
    return 'html'
  endif
endfunction

silent! exec(":source ~/.vim/" . hostname() . ".vim")
