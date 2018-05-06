function! templates#elixir#appmod() abort
  let mix_file = templates#elixir#approot() . '/mix.exs'

  if filereadable(l:mix_file)
    let line = get(readfile(l:mix_file), 0)
    return substitute(line, 'defmodule \(.*\)\.Mixfile.*', '\1', '')
  endif

  return "App"
endfunction

function! templates#elixir#appname() abort
  let mix_file = templates#elixir#approot() . '/mix.exs'
  let pattern =  '.*app: :\([a-zA-Z0-9_]*\).*'


  if filereadable(l:mix_file)
    for l:line in readfile(l:mix_file)
      if match(l:line, l:pattern) != -1
        echom l:line
        return substitute(l:line, l:pattern, '\1', '')
      endif
    endfor
    return ''
  endif

  return "App"
endfunction

function! templates#elixir#approot() abort
  let path = expand('%:h')
  let parts = split(expand('%:h'), '/')

  for i in range(1, len(l:parts) + 1)
    let path_candidate = (l:path[0] == '/' ? '/' : '') . join(parts[:-l:i], '/')
    let mix_file = l:path_candidate . '/mix.exs'

    if filereadable(l:mix_file)
      let line = get(readfile(l:mix_file), 0)
      return l:path_candidate
    endif
  endfor

  return getcwd()
endfunction
