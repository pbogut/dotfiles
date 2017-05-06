" refresh title when gui is attached, hacky way
set notitle
function! s:init_title(...)
  set title
endfunction
call jobstart("bash -c 'sleep 0.1s'", {'on_exit': function('s:init_title')})

