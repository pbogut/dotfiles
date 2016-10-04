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
  autocmd FileType elixir
        \  noremap <buffer> <leader>ta :AltTestElixir<cr>
        \| noremap <buffer> <leader>tA :AltTestElixir!<cr>
  autocmd FileType php
        \  setlocal tabstop=4 shiftwidth=4
        \| noremap <buffer> <leader>ta :AltTestPhp<cr>
        \| noremap <buffer> <leader>tA :AltTestPhp!<cr> " create separate function to handle file type
        \| :let b:commentary_format='// %s'
  autocmd FileType go :setlocal expandtab!
  " autocmd FileType javascript :setlocal tabstop=4 shiftwidth=4
  autocmd FileType xml :setlocal tabstop=4 shiftwidth=4
  autocmd FileType sh :setlocal tabstop=4 shiftwidth=4
  autocmd FileType css :setlocal tabstop=4 shiftwidth=4
  autocmd FileType scss :setlocal tabstop=4 shiftwidth=4
  autocmd FileType qf :nnoremap <buffer> o <enter>
  autocmd FileType qf :nnoremap <buffer> q :q
  autocmd FileType blade :let b:commentary_format='{{-- %s --}}'
  autocmd FileType markdown :setlocal spell spelllang=en_gb
  " start mutt file edit  on first empty line
  autocmd BufRead mutt* execute 'normal gg/\n\nj'
        \| :setlocal spell spelllang=en_gb
  autocmd BufEnter * normal zR
augroup END
" line 80 limit
set colorcolumn=81

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
  Plug 'tpope/vim-dispatch'
  Plug 'tpope/vim-abolish'
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
  " Plug 'slashmili/alchemist.vim', { 'for': 'elixir' }
  Plug 'kana/vim-operator-user'
  Plug 'chrisbra/csv.vim', { 'for': ['csv', 'tsv'] }
  Plug 'rhysd/vim-grammarous'
  Plug 'moll/vim-bbye', { 'on': 'Bdelete' }
  Plug 'cosminadrianpopescu/vim-sql-workbench'
  Plug 'ctrlpvim/ctrlp.vim'
  Plug 'will133/vim-dirdiff'
  Plug 'dbakker/vim-projectroot'
  Plug 'AndrewRadev/switch.vim'
  Plug 'osyo-manga/vim-over'
  if has('nvim')
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'
    Plug 'pbogut/fzf-mru.vim'
    Plug 'Shougo/deoplete.nvim'
    Plug 'archSeer/elixir.nvim', { 'for': 'elixir' }
    Plug 'zchee/deoplete-go', { 'do': 'make', 'for': 'go'}
    Plug 'zchee/deoplete-zsh', { 'for': 'zsh' }
    Plug 'zchee/deoplete-jedi', { 'for': 'python' }
    Plug 'pbogut/deoplete-padawan'
    " Plug 'eugen0329/vim-esearch'
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
" vim over
let g:over_enable_cmd_window = 0
" Neomake
augroup neomakegroup
  autocmd!
  autocmd BufWritePost * Neomake
  autocmd BufWritePre * call NeomakePreWrite()
	autocmd FileType php call NeomakeInitPhp()
augroup END

function! NeomakePreWrite()
  if exists('b:neomake_php_phpmd_maker_args')
    let g:neomake_php_phpmd_maker.args = b:neomake_php_phpmd_maker_args
  endif
endfunction

function! NeomakeInitPhp()
  if get(b:, 'neomake_php_init')
    return
  endif
  let b:neomake_php_init = 1

  let phpmd_xml_file = projectroot#guess() . '/phpmd.xml'
  if filereadable(phpmd_xml_file)
    let b:neomake_php_phpmd_maker_args = ['%:p', 'text', phpmd_xml_file]
  else
    let b:neomake_php_phpmd_maker_args = ['%:p', 'text', 'codesize,design,unusedcode,naming']
  endif
endfunction

let g:neomake_error_sign = {'texthl': 'ErrorMsg'}
let g:neomake_warning_sign = {'texthl': 'WarningMsg'}
" highlight NeomakeErrorSign ctermfg=223 ctermbg=223 " cant make it work ;/
" let g:neomake_error_sign = {'text': '✖', 'texthl': 'NeomakeErrorSign'}
" let g:neomake_warning_sign = {'text': '⚠', 'texthl': 'NeomakeWarningSign'}
" let g:neomake_message_sign = {'text': '➤', 'texthl': 'NeomakeMessageSign'}
" let g:neomake_info_sign = {'text': 'ℹ', 'texthl': 'NeomakeInfoSign'}

function! NeomakeSetWarningType(entry)
  let a:entry.type = "W"
endfunction
function! NeomakeSetInfoType(entry)
  let a:entry.type = "I"
endfunction
function! NeomakeSetMessageType(entry)
  let a:entry.type = "M"
endfunction

let g:neomake_php_enabled_makers = ['php', 'phpmd']
let g:neomake_php_phpcs_maker = neomake#makers#ft#php#phpcs()
let g:neomake_php_phpcs_maker.postprocess = function('NeomakeSetMessageType')
let g:neomake_php_phpmd_maker = neomake#makers#ft#php#phpmd()
let g:neomake_php_phpmd_maker.postprocess = function('NeomakeSetWarningType')

let g:neomake_xml_enabled_makers = ['xmllint']
let g:neomake_xml_xmllint_maker = {
      \ 'errorformat': '%A%f:%l:\ %m'
      \}
" sqlworkbench
let g:sw_config_dir = $HOME . "/.sqlworkbench/"
let g:sw_exe = "/opt/SQLWorkbench/sqlwbconsole.sh"
" esearch
let g:esearch = {
      \ 'adapter':    'ag',
      \ 'out':        'win',
      \ 'batch_size': 1000,
      \ 'use':        ['visual', 'hlsearch', 'last'],
      \}
let g:esearch#out#win#open = 'enew'
" notes
let g:notes_directories = [ $HOME . "/Notes/" ]
" projectroot
let g:rootmarkers = ['.projectroot', '.git', '.hg', '.svn', '.bzr',
      \ '_darcs', 'build.xml', 'composer.json']
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
let NERDTreeAutoDeleteBuffer=1
" one actino to reaveal file and close sidebar
function! ToggleNERDTree()
  if &buftype == 'nofile'
    :NERDTreeClose
  else
    silent! :NERDTreeFind
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
nnoremap <silent> <leader>b :Buffers<cr>
nnoremap <silent> <leader>m :FZFMru<cr>
nnoremap <silent> <leader>f :call FzfFilesAg()<cr>
nnoremap <silent> <leader>F :Files<cr>
nnoremap <silent> <leader>w :call WriteOrCr()<cr>
nnoremap <leader>a :Autoformat<cr>
nnoremap <leader>z :call PHP__Fold()<cr>
" vim is getting ^_ when pressing ^/, so I've mapped both
nmap <C-_> gcc<down>^
nmap <C-/> gcc<down>^
vmap <C-_> gc
vmap <C-/> gc
" surround
vmap s S
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
" nicer wrapline navigation
noremap <silent> j gj
noremap <silent> k gk
noremap  <silent> 0 g0
noremap  <silent> $ g$
noremap  <silent> ^ g^
vnoremap <silent> j gj
vnoremap <silent> k gk
onoremap <silent> j gj
onoremap <silent> k gk
" nice to have
inoremap <c-d> <del>
cnoremap <c-d> <del>
" nvim now can map alt without terminal issues, new cool shortcuts commin
if has('nvim')
  noremap <silent> <M-r> :call I3Focus('down', 'j')<cr>
  noremap <silent> <M-w> :call I3Focus('up', 'k')<cr>
  noremap <silent> <M-t> :call I3Focus('right', 'l')<cr>
  noremap <silent> <M-a> :call I3Focus('left', 'h')<cr>

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
let g:deoplete#sources#padawan#add_parentheses = 1
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
let g:gutentags_project_root = ['composer.json', 'tags']
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
let g:formatdef_phppipeline = '"fmt.phar --passes=ConvertOpenTagWithEcho --indent_with_space=".&shiftwidth." - | phpcbf | sed ' . "'s/[ ]*$//g'" . '"'
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
nmap <silent> <leader>tt :TestLast<CR>
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
  " how about add new shortcut for q which will do the action below? should be
  " awesome
  call VimuxSendText('tmux resize-pane -Z; tmux select-pane -U')
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

" switch between lib and test file
function! AltTestElixir(bang)
  let s:fullpath = expand('%:p')
  if !(s:fullpath =~ ".*\.ex$") && !(s:fullpath =~ ".*\.exs$")
    echo("Its not a elixir file")
    return
  endif
  if s:fullpath =~ ".*_test\.exs$"
    let l:alternate = substitute(s:fullpath, '\(.*\)_test\.exs$', '\1\.ex', '')
    let l:alternate = substitute(l:alternate, '/test/', '/lib/', '')
  else
    let l:alternate = substitute(s:fullpath, '\(.*\)\.ex$', '\1_test.exs', '')
    let l:alternate = substitute(l:alternate, '/lib/', '/test/', '')
  endif
  if (!filereadable(l:alternate) && !a:bang)
    echo("Alternate file not found. Use bang to force.")
  else
    echo (l:alternate)
    silent execute('edit '.l:alternate)
  endif
endfunction
command! -bang AltTestElixir :call AltTestElixir(<bang>0)

" This allows for change paste motion cp{motion}
nmap <silent> cp :let b:changepaste_register = v:register<cr>:set opfunc=ChangePaste<CR>g@
nmap <silent> cpp :exec "normal! V\"_d\"" . v:register . "P"<cr>
function! ChangePaste(type, ...)
  if a:0  " Invoked from Visual mode, use '< and '> marks.
    silent exe "normal! `<" . a:type . "`>\"_c" . getreg(b:changepaste_register)
  elseif a:type == 'line'
    silent exe "normal! '[V']\"_c" . getreg(b:changepaste_register)
  elseif a:type == 'block'
    silent exe "normal! `[\<C-V>`]\"_c" . getreg(b:changepaste_register)
  else
    silent exe "normal! `[v`]\"_c" . getreg(b:changepaste_register)
  endif
endfunction
nmap <leader>cp "+cp
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
func! I3Focus(comando, vim_comando)
  " clear mapping echo
  let oldw = winnr()
  silent exe 'wincmd ' . a:vim_comando
  let neww = winnr()
  if oldw == neww
    silent! exe '!~/.scripts/i3-focus.py ' . a:comando . ' --skip-vim > /dev/null'
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
silent! exec(":source ~/.vim/" . hostname() . ".vim")
