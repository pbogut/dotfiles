let g:mergetool_layout = 'mr'
let g:mergetool_prefer_revision = 'local'

nmap <expr> <M-BS> &diff? '<Plug>(MergetoolDiffExchangeLeft)' : '<M-BS>'
nmap <expr> <M-C-H> &diff? '<Plug>(MergetoolDiffExchangeLeft)' : '<M-C-H>'
nmap <expr> <M-C-L> &diff? '<Plug>(MergetoolDiffExchangeRight)' : '<M-C-L>'
nmap <expr> <M-C-J> &diff? '<Plug>(MergetoolDiffExchangeDown)' : '<M-C-J>'
nmap <expr> <M-C-K> &diff? '<Plug>(MergetoolDiffExchangeUp)' : '<M-C-K>'

nmap <space>mt <plug>(MergetoolToggle)
nmap <space>ml :call MergetoolSwitchLayout()<cr>

function! MergetoolSwitchLayout()
    let t:merge_tool_layout = get(t:, 'merge_tool_layout', 'mr')
    if t:merge_tool_layout  == 'mr'
        exec(':MergetoolToggleLayout mr,b')
    else
        exec(':MergetoolToggleLayout mr')
    endif
endfunction
