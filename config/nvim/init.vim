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

" Plug 'dbakker/vim-projectroot'
let g:rootmarkers = ['.projectroot', '.git', '.hg', '.svn', '.bzr',
      \ '_darcs', 'build.xml', 'composer.json', 'mix.exs']
" Plug 'godlygeek/tabular'
command! -nargs=* -range T Tabularize <args>
" Plug 'w0rp/ale'
autocmd User after_plug_end source ~/.config/nvim/config/ale.vimrc
" Plug 'samoshkin/vim-mergetool'
source ~/.config/nvim/config/vim-mergetool.vim
" Plug 'vim-scripts/ReplaceWithRegister'
source ~/.config/nvim/config/replacewithregister.vim
" Plug 'MattesGroeger/vim-bookmarks'
let g:bookmark_save_per_working_dir = 1

lua require('plugins')
" local plugins by me
lua require('projector')


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
