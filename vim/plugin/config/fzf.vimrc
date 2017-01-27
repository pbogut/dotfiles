" fzf
let g:fzf_layout = { 'down': '~20%' }
let g:fzf_command_prefix = "FZF"
let g:fzf_mru_relative = 1
let g:fzf_mru_max = 50
" preview
function! s:cat_cmd() abort
  if executable('ccat')
    return ' ccat --color=always '
  else
    return ' cat '
  endif
endfunction
let g:fzf_preview =
      \   "--bind=ctrl-e:preview-down,ctrl-y:preview-up,ctrl-s:toggle-preview "
      \ . "--preview '"
      \ . 'sh -c "[ -f {-1} ] '
      \ . '&& '
      \ . '('
      \ .   '('
      \ .     '('
      \ .        'git diff {-1} > /dev/null 2>&1 && git diff --color=always -- {-1} || cat {-1}'
      \ .     ') | sed 1,4d; ' . s:cat_cmd() . ' {-1}'
      \ .   ') | head -n 250'
      \ . ') '
      \ . '|| '
      \ . 'echo Preview is not available."'
      \ . "'"

let g:fzf_action = {
      \ 'ctrl-t': 'tab split',
      \ 'ctrl-x': 'rightbelow split',
      \ 'ctrl-v': 'rightbelow vsplit' }
