" i3focus
function! local#i3focus#switch(comando, vim_comando)
  " clear mapping echo
  let oldw = winnr()
  silent exe 'wincmd ' . a:vim_comando
  let neww = winnr()
  if oldw == neww
    silent! exe '!~/.scripts/i3-focus.py ' . a:comando . ' --skip-vim > /dev/null'
  endif
endfunction
