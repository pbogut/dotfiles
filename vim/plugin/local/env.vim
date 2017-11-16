function! local#env#init()
endfunction

augroup pbogut_env_group
  autocmd User ProjectionistActivate call s:activate()
augroup END

function! s:activate() abort
  for [l:root, l:envs] in projectionist#query('env')
    for l:key in keys(l:envs)
      exec('let $') . l:key . '=' . shellescape(l:envs[l:key])
    endfor
  endfor
endfunction
