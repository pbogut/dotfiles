" fzf
if !has('nvim')
  finish
endif

let g:fzf_layout = { 'down': '~35%' }
let g:fzf_command_prefix = "FZF"
" let g:fzf_mru_relative = 1
let g:fzf_mru_max = 50
let g:fzf_mru_per_session = 1

let g:fzf_action = {
      \ 'ctrl-t': 'tab split',
      \ 'ctrl-x': 'rightbelow split',
      \ 'ctrl-v': 'rightbelow vsplit' }

" default options
let $FZF_DEFAULT_OPTS=
      \   "--filepath-word --reverse "
      \ . "--cycle "
      \ . "--bind="
      \ . "ctrl-e:preview-down,ctrl-y:preview-up,ctrl-s:toggle-preview,"
      \ . "ctrl-w:backward-kill-word "

" preview
function! s:cat_cmd() abort
  if executable('bat')
    return ' bat -p --color=always '
  else
    return ' cat '
  endif
endfunction

let g:fzf_preview =
      \   "--preview '"
      \ . 'sh -c "[ -f {-1} ] '
      \ . '&& '
      \ . '('
      \ .   '('
      \ .     '('
      \ .        'git diff {-1} > /dev/null 2>&1 && git diff --color=always -- {-1} || echo ""'
      \ .     ') | sed 1,4d; ' . s:cat_cmd() . ' {-1}'
      \ .   ') | head -n 250'
      \ . ') '
      \ . '|| '
      \ . 'echo Preview is not available."'
      \ . "'"
