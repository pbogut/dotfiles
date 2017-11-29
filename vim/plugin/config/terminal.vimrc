" Setup solarized colors inside vim terminal
let g:terminal_color_0  = '#073642'
let g:terminal_color_1  = '#dc322f'
let g:terminal_color_2  = '#859900'
let g:terminal_color_3  = '#b58900'
let g:terminal_color_4  = '#268bd2'
let g:terminal_color_5  = '#d33682'
let g:terminal_color_6  = '#2aa198'
let g:terminal_color_7  = '#eee8d5'
let g:terminal_color_8  = '#002b36'
let g:terminal_color_9  = '#cb4b16'
let g:terminal_color_10 = '#586e75'
let g:terminal_color_11 = '#657b83'
let g:terminal_color_12 = '#839496'
let g:terminal_color_13 = '#6c71c4'
let g:terminal_color_14 = '#93a1a1'
let g:terminal_color_15 = '#fdf6e3'

" got gof goT goF
" nnoremap <silent> <leader>ot :belowright 20split \| terminal<cr>
if has("nvim")
  " nnoremap <silent> goF :te ranger<cr>
  " nnoremap <silent> got :te cd %:p:h && $SHELL<cr>
  " nnoremap <silent> goT :te<cr>

  fun! s:ranger_open_ohoosen_file(...)
    silent! exec("Bdelete!")
    silent! exec("q")
    silent! exec("e " . system("cat /tmp/ranger_nvim_choosefile 2> /dev/null"))
    silent! exec("!rm /tmp/ranger_nvim_choosefile")
  endfun
  fun! s:ranger(path, file)
    silent! tabnew
    silent! exec("!rm /tmp/ranger_nvim_choosefile")
    silent! call termopen("cd ". a:path . " && ranger --selectfile=" . a:file . " --choosefile=/tmp/ranger_nvim_choosefile", {
          \ 'on_exit' : function('s:ranger_open_ohoosen_file')
          \ })
    startinsert
  endfun
  fun! s:close_term_window(...)
    exec("Bdelete!")
  endfun
  fun! s:close_term_split(...)
    exec("Bdelete!")
    wincmd q
  endfun
  fun! s:open_terminal(path, ...)
    let split = get(a:, 1, 0)
    if (l:split)
      belowright 20split
      wincmd J
      resize 20
    endif
    enew
    if (l:split)
      call termopen("cd ". a:path . "; " . $SHELL, {
            \ 'on_exit' : function('s:close_term_split')
            \ })
    else
      call termopen("cd ". a:path . "; " . $SHELL, {
            \ 'on_exit' : function('s:close_term_window')
            \ })
    endif
    startinsert
  endfun

  nnoremap <silent> gof :call <sid>ranger(expand("%:p:h"), expand("%:t"))<cr>
  nnoremap <silent> goF :call <sid>ranger(getcwd(), expand("%:t"))<cr>
  nnoremap <silent> gOt :call <sid>open_terminal(expand("%:p:h"))<cr>
  nnoremap <silent> gOT :call <sid>open_terminal(getcwd())<cr>
  nnoremap <silent> got :call <sid>open_terminal(expand("%:p:h"), 1)<cr>
  nnoremap <silent> goT :call <sid>open_terminal(getcwd(), 1)<cr>
endif
