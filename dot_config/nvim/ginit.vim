" refresh title when gui is attached, hacky way
Guifont! SauceCodePro Nerd Font:h10
set notitle
function! s:init_title(...)
  set title
endfunction
call jobstart("bash -c 'sleep 0.5s'", {'on_exit': function('s:init_title')})

" copy urxvt behaviour
nnoremap <m-p> "+p
cnoremap <m-p> <c-r>+
inoremap <m-p> <c-r>+
tnoremap <m-p> <c-\><c-n>pA
