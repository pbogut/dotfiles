" toggle list plugin
"
" based on Donald Ephraim Curtis (2011) togglelist plugin
" https://github.com/milkypostman/vim-togglelist
"
function! s:getbufferlist()
  redir =>buflist
  silent! ls
  redir END
  return buflist
endfunction

function! local#togglelist#locationlist()
  let curbufnr = winbufnr(0)
  for bufnum in map(filter(split(s:getbufferlist(), '\n'), 'v:val =~ "Location List"'), 'str2nr(matchstr(v:val, "\\d\\+"))')
    if curbufnr == bufnum
      lclose
      return
    endif
  endfor

  let winnr = winnr()
  let prevwinnr = winnr("#")

  let nextbufnr = winbufnr(winnr + 1)
  try
    lopen
    wincmd j
    wincmd J
    resize 10
  catch /E776/
      echohl ErrorMsg
      echo "Location List is Empty."
      echohl None
      return
  endtry
  if winbufnr(0) == nextbufnr
    lclose
    if prevwinnr > winnr
      let prevwinnr-=1
    endif
  else
    if prevwinnr > winnr
      let prevwinnr+=1
    endif
  endif
  " restore previous window
  exec prevwinnr."wincmd w"
  exec winnr."wincmd w"
endfunction

function! local#togglelist#quickfixlist()
  for bufnum in map(filter(split(s:getbufferlist(), '\n'), 'v:val =~ "Quickfix List"'), 'str2nr(matchstr(v:val, "\\d\\+"))')
    if bufwinnr(bufnum) != -1
      cclose
      return
    endif
  endfor
  let winnr = winnr()
  if exists("g:toggle_list_copen_command")
    exec(g:toggle_list_copen_command)
  else
    copen
    wincmd j
    wincmd J
  endif
  if winnr() != winnr
    wincmd p
  endif
endfunction
