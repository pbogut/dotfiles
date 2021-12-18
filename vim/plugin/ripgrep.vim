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
  exe("Rg " . trim(@a))
  let @a = l:tmp
endfunction
