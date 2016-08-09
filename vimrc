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
set completeopt=menuone,noselect
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
set hidden " No bang needed to open new file
let mapleader = "\<space>" " life changer
augroup configgroup
  autocmd!
  autocmd FileType html :setlocal tabstop=4 shiftwidth=4
  autocmd FileType php :setlocal tabstop=4 shiftwidth=4
        \| noremap <leader>ta :AltTestPhp<cr>
        \| noremap <leader>tA :AltTestPhp!<cr> " create separate function to handle file type
        \| :let b:commentary_format='// %s'
  " autocmd FileType javascript :setlocal tabstop=4 shiftwidth=4
  autocmd FileType xml :setlocal tabstop=4 shiftwidth=4
  autocmd FileType sh :setlocal tabstop=4 shiftwidth=4
  autocmd FileType qf :nnoremap <buffer> o <enter>
  autocmd FileType qf :nnoremap <buffer> q :q
  autocmd FileType blade :let b:commentary_format='{{-- %s --}}'
  " start mutt file edit  on first empty line
  autocmd BufRead mutt* execute 'normal gg/\n\nj'
        \| :setlocal spell spelllang=en_gb
  autocmd BufEnter * normal zR
augroup END
" line 80 limit
set colorcolumn=81

let g:python_host_prog='/usr/bin/python'

if has("patch-7.4.314")
  set shortmess+=c
endif

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
  Plug 'pbogut/vim-dispatch' " panel size patch
  Plug 'dhruvasagar/vim-prosession'
  Plug 'terryma/vim-expand-region'
  Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeClose', 'NERDTreeFind'] }
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  Plug 'edkolev/tmuxline.vim'
  Plug 'airblade/vim-gitgutter'
  Plug 'terryma/vim-multiple-cursors'
  Plug 'MarcWeber/vim-addon-mw-utils'
  " Plug 'tomtom/tlib_vim'
  Plug 'ludovicchabant/vim-gutentags'
  Plug 'gioele/vim-autoswap'
  Plug 'ntpeters/vim-better-whitespace'
  Plug 'honza/vim-snippets'
  " Plug 'Shougo/vimproc.vim'
  Plug 'mattn/emmet-vim'
  Plug 'christoomey/vim-tmux-navigator'
  Plug 'sirver/ultisnips'
  Plug 'sheerun/vim-polyglot'
  Plug 'joonty/vdebug', { 'for': 'php' }
  Plug 'benekastah/neomake', { 'on': 'Neomake' }
  Plug 'Chiel92/vim-autoformat'
  Plug 'alvan/vim-closetag'
  Plug 'edsono/vim-matchit'
  Plug 'captbaritone/better-indent-support-for-php-with-html', { 'for': 'php' }
  Plug 'docteurklein/php-getter-setter.vim', { 'for': 'php' }
  Plug 'pbogut/phpfolding.vim', { 'for': 'php' }
  Plug 'janko-m/vim-test'
  Plug 'benmills/vimux'
  Plug 'elixir-lang/vim-elixir', { 'for': 'elixir' }
  Plug 'slashmili/alchemist.vim', { 'for': 'elixir' }
  Plug 'kana/vim-operator-user'
  Plug 'tyru/operator-camelize.vim'
  Plug 'chrisbra/csv.vim', { 'for': ['csv', 'tsv'] }
  Plug 'rhysd/vim-grammarous'
  Plug 'moll/vim-bbye', { 'on': 'Bdelete' }
  Plug 'cosminadrianpopescu/vim-sql-workbench'
  Plug 'ctrlpvim/ctrlp.vim'
  if has('nvim')
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'
    Plug 'pbogut/fzf-mru.vim'
    Plug 'Shougo/deoplete.nvim'
  else
  endif " if Plug installed
  if (!has('nvim') || $STY != '')
    Plug 'altercation/vim-colors-solarized'
  else
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
    Plug 'frankier/neovim-colors-solarized-truecolor-only'
  endif
  " All of your Plugins must be added before the following line
endif "
silent! call plug#end()            " requiredc
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

" phpgetset config
let g:phpgetset_insertPosition = 2 " below current block
let b:phpgetset_insertPosition = 2 " below current block
let g:phpgetset_getterTemplate =
\ "    \n" .
\ "    /**\n" .
\ "     * Get %varname%\n" .
\ "     *\n" .
\ "     * @return %varname%\n" .
\ "     */\n" .
\ "    public function %funcname%()\n" .
\ "    {\n" .
\ "        return $this->%varname%;\n" .
\ "    }"

let g:phpgetset_setterTemplate =
\ "    \n" .
\ "    /**\n" .
\ "     * Set %varname%.\n" .
\ "     *\n" .
\ "     * @param %varname% - value to set.\n" .
\ "     * @return $this\n" .
\ "     */\n" .
\ "    public function %funcname%($%varname%)\n" .
\ "    {\n" .
\ "        $this->%varname% = $%varname%;\n" .
\ "        return $this;\n" .
\ "    }"

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
nnoremap <leader>ol :lopen<cr>
nnoremap <leader>oq :copen<cr>
nnoremap <leader>r :call ToggleNERDTree()<cr>
nnoremap <leader>b :Buffers<cr>
nnoremap <leader>m :FZFMru<cr>
nnoremap <leader>f :call FzfFilesAg()<cr>
nnoremap <leader>F :Files<cr>
nnoremap <leader>w :call WriteOrCr()<cr>
nnoremap <leader>a :Autoformat<cr>
nnoremap <leader>z :call PHP__Fold()<cr>
map <leader>_ <Plug>(operator-camelize-toggle)
" vim is getting ^_ when pressing ^/, so I've mapped both
nmap <C-_> gcc<down>^
nmap <C-/> gcc<down>^
vmap <C-_> gc
vmap <C-/> gc
nmap <bs> :TmuxNavigateLeft<cr>
map <C-w>d :Bdelete<cr>
map <C-w>D :Bdelete!<cr>
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
noremap <leader>sa :exec "Autoformta ".&syntax<cr>
" nvim now can map alt without terminal issues, new cool shortcuts commin
if has('nvim')
  inoremap <A-a> <Esc>A
  inoremap <A-i> <Esc>I
  noremap <A-a> <Esc>A
  noremap <A-i> <Esc>I
  noremap <A-l> <C-w>>
  noremap <A-h> <C-w><
  noremap <A-j> <C-w>-
  noremap <A-k> <C-w>+
  " search command history based on typed stryng
  cnoremap <A-k> <Up>
  cnoremap <A-j> <Down>
endif
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
iabbrev </ </<C-X><C-O><C-n>
map <F8> :BLReloadPage<cr>
map <F7> :BLReloadCSS<cr>
" fzf
nnoremap <leader>gf :call fzf#vim#files('', extend({'options': '-q '.shellescape(expand('<cfile>'))}, g:fzf_layout))<cr>
nnoremap <leader>gt :call fzf#vim#tags(expand('<cword>'))<cr>
" air-line
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
" color scheme
" colorscheme jellybeans
" highlight ColorColumn ctermbg=234
" highlight CursorLine ctermbg=233
" highlight CursorColumn ctermbg=232
" highlight SpecialKey ctermbg=none
function! SolarizedLight()
  set background=light
  silent !dbus-send --session /net/sf/roxterm/Options net.sf.roxterm.Options.SetColourScheme string:$ROXTERM_ID string:Solarized\ Light
endfunction
function! SolarizedDark()
  set background=dark
  silent !dbus-send --session /net/sf/roxterm/Options net.sf.roxterm.Options.SetColourScheme string:$ROXTERM_ID string:Solarized\ Dark
endfunction
nnoremap <leader>cd :call SolarizedDark()<cr>
nnoremap <leader>cl :call SolarizedLight()<cr>
set background=dark
silent! colorscheme solarized
" Padawan
let g:ycm_semantic_triggers = {}
let g:ycm_semantic_triggers.php = ['->', '::', '(', 'use ', 'namespace ', '\']
" Deoplete
let g:deoplete#enable_at_startup = 1
let g:deoplete#auto_completion_start_length = 1
let g:deoplete#enable_debug=1
" let g:deoplete#sources = {}
" let g:deoplete#sources._ = ['buffer']
" let g:deoplete#sources.php = ['buffer', 'tag', 'member', 'file']
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

let g:UltiSnipsSnippetDirectories=["UltiSnips", "mysnippets"]
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
let g:AutoPairsShortcutToggle = ''
let g:AutoPairsShortcutFastWrap = ''
let g:AutoPairsShortcutJump = ''
let g:AutoPairsShortcutBackInsert = ''
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
" gutentags
let g:gutentags_generate_on_new = 0
let g:gutentags_generate_on_missing = 0
let g:gutentags_exclude = ['*node_modules*', '*bower_components*', 'tmp*', 'temp*']
" vim tags
let g:vim_tags_use_language_field = 1
let g:vim_tags_use_vim_dispatch = 1
" fzf
function! FzfFilesAg()
  let $FZF_DEFAULT_COMMAND = 'ag -l -g ""'
  execute('Files')
  let $FZF_DEFAULT_COMMAND = ''
endfunction
let g:fzf_layout = { 'down': '~20%' }
" ctrlp
let g:ctrlp_extensions = ['tag', 'mixed']
" Use silver searcher to list files
let g:ctrlp_user_command =
      \ 'ag %s --files-with-matches -g "" --ignore "\.git$\|\.hg$\|\.svn$"; '
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
set nowritebackup
set nobackup " well, thats the only way to prevent guard from running tests twice ;/
" vim-test
nmap <silent> <leader>tn :TestNearest<CR>
nmap <silent> <leader>tf :TestFile<CR>
nmap <silent> <leader>ts :TestSuite<CR>
nmap <silent> <leader>tl :TestLast<CR>
nmap <silent> <leader>tv :TestVisit<CR>
" to close and go back to Vim perss <c-k> or <c-j>
nmap <silent> <leader>ti :call InspectTest()<CR>
nmap <silent> <leader>tx :VimuxCloseRunner<CR>
nmap <silent> <leader>tq :VimuxCloseRunner<CR>
let g:VimuxHeight = "7"
function! InspectTestStrategy(cmd)
  let echo  = 'echo -e ' . shellescape(a:cmd)
  let cmd = join(['clear', l:echo, a:cmd], '; ')
  call VimuxCloseRunner()
  call VimuxRunCommand(cmd)
  call VimuxZoomRunner()
  call VimuxRunCommand('tmux copy-mode')
  call VimuxSendText('exit')
endfunction
let g:test#custom_strategies = {'inspect': function('InspectTestStrategy')}
let g:test#strategy = 'vimux'
function! InspectTest()
  call VimuxZoomRunner()
  call VimuxInspectRunner()
endfunction
" new backup file every minute, coz I can
" its recreating file path and then save copy there with current time
" dont know how fast it will grow...
augroup backup
  autocmd!
  autocmd BufWritePre * call ParanoicBackup()
augroup END
let g:paranoic_backup_dir="~/.vim/backupfiles/"
function! ParanoicBackup()
  let filedir = g:paranoic_backup_dir . expand('%:p:h')
  let filename = expand('%:t')
  let timestamp = strftime("___%y%m%d_%H%M")
  silent execute "!mkdir -p " . fnameescape(filedir)
  silent execute "w! " . fnameescape(filedir . '/' . filename . timestamp)
endfunction
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
" modify selected text using combining diacritics
command! -range -nargs=0 Overline        call s:CombineSelection(<line1>, <line2>, '0305')
command! -range -nargs=0 Underline       call s:CombineSelection(<line1>, <line2>, '0332')
command! -range -nargs=0 DoubleUnderline call s:CombineSelection(<line1>, <line2>, '0333')
command! -range -nargs=0 Strikethrough   call s:CombineSelection(<line1>, <line2>, '0336')
function! s:CombineSelection(line1, line2, cp)
  execute 'let char = "\u'.a:cp.'"'
  execute a:line1.','.a:line2.'s/\%V[^[:cntrl:]]/&'.char.'/ge'
endfunction

" Wipes out all invisible buffers
command! -bang Wipeout :call Wipeout(<bang>0)
function! Wipeout(bang)
  " figure out which buffers are visible in any tab
  let visible = {}
  for t in range(1, tabpagenr('$'))
    for b in tabpagebuflist(t)
      let visible[b] = 1
    endfor
  endfor
  " close any buffer that are loaded and not visible
  let l:tally = 0
  let l:cmd = 'bw'
  if a:bang
    let l:cmd .= '!'
  endif
  for b in range(1, bufnr('$'))
    if buflisted(b) && !has_key(visible, b)
      let l:tally += 1
      silent exe l:cmd . ' ' . b
    endif
  endfor
  echon "Deleted " . l:tally . " buffers"
endfun
" switch between class and test file
function! AltTestPhp(bang)
  let s:fullpath = expand('%:p')
  if !(s:fullpath =~ ".*\.php$")
    echo("Its not a php file")
    return
  endif
  if s:fullpath =~ ".*Test\.php$"
    let l:alternate = substitute(s:fullpath, '\(.*\)Test\.php$', '\1\.php', '')
    let l:alternate = substitute(l:alternate, '/tests/', '/app/', '')
  else
    let l:alternate = substitute(s:fullpath, '\(.*\)\.php$', '\1Test\.php', '')
    let l:alternate = substitute(l:alternate, '/app/', '/tests/', '')
  endif

  if (!filereadable(l:alternate) && !a:bang)
    echo("Alternate file not found. Use bang to force.")
  else
    echo (l:alternate)
    silent execute('edit '.l:alternate)
  endif
endfunction
command! -bang AltTestPhp :call AltTestPhp(<bang>0)

" This allows for change paste motion cp{motion}
nmap <silent> cp :set opfunc=ChangePaste<CR>g@
nmap <silent> cpp :normal! V"_dP<cr>
function! ChangePaste(type, ...)
  if a:0  " Invoked from Visual mode, use '< and '> marks.
      silent exe "normal! `<" . a:type . "`>\"_c" . @"
  elseif a:type == 'line'
      silent exe "normal! '[V']\"_c" . @"
  elseif a:type == 'block'
      silent exe "normal! `[\<C-V>`]\"_c" . @"
  else
      silent exe "normal! `[v`]\"_c" . @"
  endif
endfunction
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
func! I3Focus(comando,vim_comando)
  let oldw = winnr()
  silent exe 'wincmd ' . a:vim_comando
  let neww = winnr()
  if oldw == neww
    silent exe '!i3-msg -q focus ' . a:comando
    if !has("gui_running")
        redraw!
    endif
  endif
endfunction
function! PHP__Fold()
  if (get(b:, 'PHP__Flod__INITIATED', 0))
    silent! normal za
  else
    silent! execute 'EnableFastPHPFolds'
    silent! normal zRza
    let b:PHP__Flod__INITIATED = 1
  endif
endfunction
set foldtext=NeatFoldText()
let g:DisableAutoPHPFolding = 1

let g:snips_author = "Pawel Bogut"
let g:snips_github = "https://github.com/pbogut"
