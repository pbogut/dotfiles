" basic settings
lua require('settings')
lua require('indents')

source ~/.config/nvim/config/perproject.vimrc

" autogroups
lua require('autogroups')

augroup configgroup_nvim
  autocmd!
augroup END
augroup configgroup
  autocmd!
  autocmd BufEnter .i3blocks.conf
        \ let b:whitespace_trim_disabled = 1
  autocmd BufWritePost *
        \  silent! Whitespace
augroup END

" Plug 'tpope/vim-dadbod'
autocmd User after_vim_load source ~/.config/nvim/config/dadbod.vimrc

" Plug 'janko-m/vim-test'
source ~/.config/nvim/config/test.vim
" Plug 'elmcast/elm-vim', { 'for': 'elm' }
" Plug 'pbogut/vim-elmper', { 'for': 'elm' }
let g:elm_format_autosave = 0
" Plug 'dbakker/vim-projectroot'
let g:rootmarkers = ['.projectroot', '.git', '.hg', '.svn', '.bzr',
      \ '_darcs', 'build.xml', 'composer.json', 'mix.exs']
" Plug 'godlygeek/tabular'
command! -nargs=* -range T Tabularize <args>
" Plug 'kristijanhusak/vim-dirvish-git'
source ~/.config/nvim/config/dirvish.vimrc
" Plug 'w0rp/ale'
autocmd User after_plug_end source ~/.config/nvim/config/ale.vimrc
" Plug 'samoshkin/vim-mergetool'
source ~/.config/nvim/config/vim-mergetool.vim
" Plug 'vim-scripts/ReplaceWithRegister'
source ~/.config/nvim/config/replacewithregister.vim
" Plug 'MattesGroeger/vim-bookmarks'
let g:bookmark_save_per_working_dir = 1

lua require('plugins')

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
source ~/.config/nvim/config/autopairs.vimrc
source ~/.config/nvim/config/terminal.vimrc

" nicer vertical split
hi VertSplit guibg=#073642 guifg=fg

" dont mess with me!
let g:no_plugin_maps = 1

lua require('keymappings')

" open list / quickfix
nnoremap <silent> <space>l :call local#togglelist#locationlist()<cr>
nnoremap <silent> <space>q :call local#togglelist#quickfixlist()<cr>

nnoremap <silent> \won <Plug>(dirvish_up)
nnoremap <silent> <bs> :Dirvish %:p:h<cr>
nnoremap <silent> _ :Dirvish %:p:h<cr>
nnoremap <silent> <space>w :W!<cr>
nnoremap <silent> <space>a :Format<cr>
nnoremap <silent> <space>z za
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
nmap yrf :let @+=expand('%:.')<bar>echo 'Yanked: '.expand('%:.')<cr>

" {{{ fzf
lua require'plugins.fzf'
" }}}

ProjectType laravel nnoremap <silent> <space>gf :call local#laravel#file_under_coursor()<cr>

nnoremap <silent> <space>of :let g:pwd = expand('%:h') \| belowright 20split \| enew \| call termopen('cd ' . g:pwd . ' && zsh') \| startinsert<cr>
nnoremap <silent> <space>op :let g:pwd = projectroot#guess() \| belowright 20split \| enew \| call termopen('cd ' . g:pwd . ' && zsh') \| startinsert<cr>

noremap <space>sc :execute(':rightbelow 10split \| te scspell %')<cr>

" emmet quick shortcut
imap <M-Tab> <c-y>,
imap <M-n> <c-y>n
imap <M-N> <c-y>N
" ripgrep
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
" toggle spell dictionaires
nnoremap <space>ss :call SpellToggle()<cr>
function! SpellToggle()
  let l:get_next = v:false
  for [l:spell, l:lang] in [[1, 'en_gb'], [1, 'pl'], [0, 'en_gb']]
    if l:get_next
      if l:spell == 0
        set nospell
        echom "Disable spell checking"
      else
        set spell
        echom "Set spell to " . l:lang
      endif
      exec('set spelllang=' . l:lang)
      return
    endif
    if &spell == l:spell && &spelllang == l:lang
      let l:get_next = v:true
      continue
    endif
  endfor
  " default if something is set up different
  echom "Set spell to en_gb"
  set spelllang=en_gb
  set spell
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

let g:paranoic_backup_dir="~/.vim/backupfiles/"

command! -bang W :call CreateFoldersAndWrite(<bang>0)
function! CreateFoldersAndWrite(bang)
  let l:one = expand('%:p')
  let l:two = substitute(l:one, '^[A-Za-z]*', '', '')
  if l:one != l:two
    echo "Sorry but buffer is not a real file"
    return
  endif
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
  if filereadable('.editorconfig')
    return
  endif
  let l:rootmakers = g:rootmarkers
  call add(g:rootmarkers, '.editorconfig')
  let l:root = projectroot#guess()
  let g:rootmarkers = l:rootmakers
  if filereadable(l:root . '/.editorconfig')
    return
  endif
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

function! s:whitespace()
  if !empty(get(b:, 'whitespace_trim_disabled'))
    return
  endif

  silent! StripWhitespace
endfunction
command! Whitespace call s:whitespace()
