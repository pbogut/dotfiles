let g:switch_custom_definitions =
            \ [
            \   {
            \     '\(===\)': '==',
            \     '\(==\)':  '===',
            \   },
            \   {
            \     '\(!==\)': '!=',
            \     '\(!=\)':  '!==',
            \   },
            \ ]
let s:switch_c_like_if =
            \ {
            \   'if (true || (\(.*\)))':          'if (false && (\1))',
            \   'if (false && (\(.*\)))':         'if (\1)',
            \   'if (\%(true\|false\)\@!\(.*\))': 'if (true || (\1))',
            \ }
let s:switch_c_like_while =
            \ {
            \   'while (true || (\(.*\)))':          'while (false && (\1))',
            \   'while (false && (\(.*\)))':         'while (\1)',
            \   'while (\%(true\|false\)\@!\(.*\))': 'while (true || (\1))',
            \ }
let s:switch_php_scope =
            \ {
            \   '\<private\>':   'protected',
            \   '\<protected\>': 'public',
            \   '\<public\>':    'private',
            \ }
let s:switch_php_array =
            \ {
            \   '\<array(\(.*\))':      '[\1]',
            \   '\(\s*\|^\)\[\(.*\)\]': '\1array(\2)',
            \ }
let s:switch_php_comment =
            \ {
            \   '^\(\s*\)/\* \(.*\) \*/$':      '\1// \2',
            \   '^\(\s*\)// \(.*\)': '\1/* \2 */',
            \ }
let s:switch_elixir_assert =
            \ {
            \   '\(assert\)': 'refute',
            \   '\(refute\)': 'assert',
            \ }
let s:switch_elixir_map =
            \ {
            \   '\<\([a-zA-Z0-9_]*\): \([^,]*\),':   '"\1" => \2,',
            \   '"\([a-zA-Z0-9_]*\)" => \([^,]*\),': '\1: \2,',
            \ }
let s:switch_blade_echo =
            \ {
            \   '{{\(.\{-}\)}}':   '{!!\1!!}',
            \   '{!!\(.\{-}\)!!}':   '{{\1}}',
            \ }
augroup swich_vim
  autocmd!
  autocmd FileType blade let b:switch_custom_definitions =
            \ [
            \   s:switch_blade_echo,
            \ ]
  autocmd FileType php let b:switch_custom_definitions =
            \ [
            \   s:switch_c_like_if,
            \   s:switch_c_like_while,
            \   s:switch_php_array,
            \   s:switch_php_comment,
            \   s:switch_php_scope,
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
            \   s:switch_elixir_map,
            \ ]
augroup END
