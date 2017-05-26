" refresh title when gui is attached, hacky way
let g:Guifont="SauceCodePro Nerd Font:h10"
set guifontset=SauceCodePro\ Nerd\ Font:h10
Guifont! SauceCodePro Nerd Font:h10

set notitle
function! s:init_title(...)
  set title
endfunction
call jobstart("bash -c 'sleep 0.5s'", {'on_exit': function('s:init_title')})
