function! local#setlocal#init()
endfunction
augroup setlocal_group
  autocmd User ProjectionistActivate call s:activate()
augroup END

let s:options = {
      \    "tabstop": "int",
      \    "shiftwidth": "int",
      \    "expandtab": "bool",
      \    "noexpandtab": "bool"
      \  }

function! s:activate() abort
  for [l:root, l:map] in projectionist#query('let')
    for [l:variable, l:value] in items(l:map)
      let l:test_var = substitute(l:variable, '.*\([wbgl]:[A-Za-z_\-]*\).*', '\1', 'g')
      if l:test_var != l:variable
        echom "l:variable `" . l:variable . "` != `" . l:test_var . "` is not valid variable name"
      endif
      exec('let ' . l:variable . ' = "' . escape(l:value, '"') . '"')
    endfor
  endfor

  for [l:root, l:map] in projectionist#query('setlocal')
    let b:_proj_setlocal = get(b:, '_proj_setlocal', {})
    for [l:option, l:value] in items(l:map)
      " apply only first occurence of the option
      if empty(get(b:_proj_setlocal, l:option, 0))
        let b:_proj_setlocal[l:option] = 1
        let l:type = get(s:options, l:option, 0)
        if l:type == "bool"
          if (l:value)
            exec('setlocal ' . l:option)
          else
            exec('setlocal no' . l:option)
          endif
        elseif l:type == "int"
          exec('setlocal ' . l:option . '=' . l:value)
        else
          echom "Unknown local option: " . l:option
        endif
      endif
    endfor
  endfor
endfunction
