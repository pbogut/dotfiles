function! local#changepaste#init()
  " This allows for change paste motion cp{motion}
  " nmap <silent> cp :let b:changepaste_register = v:register<cr>:set opfunc=local#changepaste#cp<CR>g@
  " nmap <silent> cpp :exec "normal! V\"_d\"" . v:register . "P"<cr>
  " nmap <silent> cp= :exec "normal! V\"_d\"" . v:register . "P=="<cr>
  " nmap <silent> cP cp$
endfunction

function! local#changepaste#cp(type, ...)
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

