function! local#repl#init()
endfunction

augroup repl_group
  autocmd User ProjectionistActivate call s:activate()
augroup END

function! s:activate() abort
  for [root, value] in projectionist#query('console')
    let b:_repl_console_command = value
    let b:_repl_project_root = root
    break
  endfor
endfunction

function! s:repl(bang) abort
  let value = get(b:, '_repl_console_command', "")
  let root = get(b:, '_repl_project_root', "")

  if l:value == "" || l:root == ""
    echo "You need to set up 'console' property in projectionist config."
    return
  endif

  if a:bang == 0
    execute(':belowright 11split')
  endif

  execute(':te cd ' . l:root . ' && ' . l:value)
endfunction

command! -bang Repl :call s:repl(<bang>0)
