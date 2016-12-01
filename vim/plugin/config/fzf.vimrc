" fzf
let g:fzf_layout = { 'down': '~20%' }
let g:fzf_command_prefix = "FZF"
let g:fzf_mru_relative = 1
let g:fzf_mru_max = 50
let g:fzf_preview =
      \   "--preview '"
      \ . 'sh -c "[ -f {-1} ] '
      \ . '&& '
      \ . '('
      \ .   '('
      \ .     '('
      \ .        'git diff {-1} > /dev/null 2>&1 && git diff --color=always -- {-1} || cat {-1}'
      \ .     ') | sed 1,4d; cat {-1}'
      \ .   ') | head -n 50'
      \ . ') '
      \ . '|| '
      \ . 'echo Preview is not available."'
      \ . "'"
