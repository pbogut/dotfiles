" nnoremap <silent> <leader>ot :belowright 20split \| terminal<cr>
if has("nvim")
  fun! s:close_term_window(...)
    exec("Bdelete!")
  endfun
  fun! s:close_term_split(...)
    exec("Bdelete!")
    wincmd q
  endfun

  function! QuickTerm(cmd, ...) abort
    let split = !get(a:, 1, 0)
    if (l:split)
      belowright 20split
      wincmd J
      resize 20
    endif
    enew
    let waitforkey = "; echo '\nPress any key to continue...'; read -n 1 -s -p ''"
    if (l:split)
      call termopen(a:cmd . l:waitforkey, {
            \ 'on_exit' : function('s:close_term_split')
            \ })
    else
      call termopen(a:cmd . l:waitforkey, {
            \ 'on_exit' : function('s:close_term_window')
            \ })
    endif
    startinsert
    tmap <buffer> <esc> <cr>
  endfunction

  command! -nargs=* -bang QuickTerm :call QuickTerm(<q-args>, <bang>0)
endif
