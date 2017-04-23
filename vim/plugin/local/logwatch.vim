function! local#logwatch#init()
endfunction

augroup logwatch_group
  autocmd User ProjectionistActivate call s:activate()
augroup END

function! s:activate() abort
  for [root, value] in projectionist#query('logwatch')
    let b:_logwatch_console_command = value
    let b:_logwatch_project_root = root
  endfor
endfunction

function! s:log(bang) abort
  let value = get(b:, '_logwatch_console_command', "")
  let root = get(b:, '_logwatch_project_root', "")

  if l:value == "" || l:root == ""
    echo "You need to set up 'logwatch' property in projectionist config."
    return
  endif

  execute(':Dispatch! cd ' . root . ' && $TERMINAL -T ' . shellescape(value) . ' -e ' . value)
endfunction

command! -bang LogWatch :call s:log(<bang>0)
