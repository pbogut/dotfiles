function! templates#elixir#appmod() abort
  if filereadable('mix.exs')
    let line = get(readfile('mix.exs'), 0)
    return substitute(line, 'defmodule \(.*\)\.Mixfile.*', '\1', '')
  endif
  return "App"
endfunction

