let g:switch_custom_definitions =
            \ [
            \   {
            \     '\(===\)':  '==',
            \     '\(==\)':   '===',
            \   },
            \   {
            \     '\(!==\)':  '!=',
            \     '\(!=\)':   '!==',
            \   },
            \ ]
let s:switch_c_like_if =
            \ {
            \   'if (true || (\(.*\)))':           'if (false && (\1))',
            \   'if (false && (\(.*\)))':          'if (\1)',
            \   'if (\%(true\|false\)\@!\(.*\))':  'if (true || (\1))',
            \ }
let s:switch_php_array =
            \ {
            \   '\<array(\(.*\))':  '[\1]',
            \   '\(\s*\|^\)\[\(.*\)\]':      '\1array(\2)',
            \ }
let s:switch_elixir_assert =
            \ {
            \   '\(assert\)':  'refute',
            \   '\(refute\)':   'assert',
            \ }
augroup swich_vim
  autocmd!
  autocmd FileType php let b:switch_custom_definitions =
            \ [
            \   s:switch_c_like_if,
            \   s:switch_php_array,
            \ ]
  autocmd FileType javascript let b:switch_custom_definitions =
            \ [
            \   s:switch_c_like_if,
            \ ]
  autocmd FileType javascript.jsx let b:switch_custom_definitions =
            \ [
            \   s:switch_c_like_if,
            \ ]
  autocmd FileType elixir let b:switch_custom_definitions =
            \ [
            \   s:switch_elixir_assert,
            \ ]
augroup END
