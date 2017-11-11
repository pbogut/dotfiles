" Ale -- to be moved!!!!! START
if !has('nvim')
  finish
endif

augroup pb_alegroup
  autocmd!
  autocmd InsertEnter php call s:ale_init_php()
  autocmd FileType php call s:ale_init_php()
augroup END

let g:ale_lint_on_save = 1

let g:ale_sign_error = '✖'
let g:ale_sign_error = ''
let g:ale_sign_warning = '⚠'
let g:ale_sign_warning = ''

let g:ale_sign_column_always = 1

let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%severity%][%linter%] %s'

function! s:ale_init_php()
  if !empty(get(b:, 'ale_php_phpmd_ruleset'))
    let g:ale_php_phpmd_ruleset = b:ale_php_phpmd_ruleset
    return
  endif

  " phpmd.xml for neomake @todo fallback to getcwd()
  " it should update each time buffer is swiched... i guess
  let phpmd_xml_file = projectroot#guess() . '/phpmd.xml'
  if filereadable(phpmd_xml_file)
    let b:ale_php_phpmd_ruleset = phpmd_xml_file
  else
    let b:ale_php_phpmd_ruleset = 'codesize,design,unusedcode,naming'
  endif
  let g:ale_php_phpmd_ruleset = b:ale_php_phpmd_ruleset
endfunction

let g:ale_linters =
      \{
      \ 'elixir': ['dialyzer', 'mix']
      \}

function! s:ale_dialyzer(buffer, lines) abort
  " Matches patterns line the following:
  "
  " lib/calc.ex:2: Invalid type specification for function 'Elixir.Calc':sum/1. The success typing is (binary()) -> integer()
  " lib/filename.ex:19:7: Pipe chain should start with a raw value.
  let l:pattern = '\v(.*):(\d+): (.+)$'
  let l:output = []

  for l:line in a:lines
    let l:match = matchlist(l:line, l:pattern)

    if len(l:match) == 0
        continue
    endif

    " let l:type = "F"
    let l:type = "W"
    let l:text = l:match[3]

    if l:type ==# 'C'
      let l:type = 'E'
    elseif l:type ==# 'R'
      let l:type = 'W'
    endif

    if bufname(a:buffer) != l:match[1]
      continue
    endif

    " vcol is Needed to indicate that the column is a character.
    call add(l:output, {
    \   'bufnr': a:buffer,
    \   'lnum': l:match[2] + 0,
    \   'col': 0,
    \   'type': l:type,
    \   'text': l:text,
    \})
  endfor

  return l:output
endfunction

function! s:ale_mix_compile(buffer, lines) abort
  " Matches patterns line the following:
  "
  " ** (SyntaxError) lib/issues.ex:18: syntax error before: kota
  " (elixir) lib/kernel/parallel_compiler.ex:198: anonymous fn/4 in Kernel.ParallelCompiler.spawn_workers/6
  let l:pattern = '\v(\(.*\) )(.*):(\d+): (.+)$'
  let l:output = []

  for l:line in a:lines
    let l:match = matchlist(l:line, l:pattern)

    if len(l:match) == 0
        continue
    endif

    " let l:type = "F"
    let l:type = "W"
    let l:text = l:match[1] . l:match[4]

    if l:type ==# 'C'
      let l:type = 'E'
    elseif l:type ==# 'R'
      let l:type = 'W'
    endif

    if bufname(a:buffer) != l:match[2]
      " continue
    endif

    " vcol is Needed to indicate that the column is a character.
    call add(l:output, {
    \   'bufnr': a:buffer,
    \   'lnum': l:match[3] + 0,
    \   'col': 0,
    \   'type': l:type,
    \   'text': l:text,
    \})
  endfor

  return l:output
endfunction

function! s:ale_filtered_credo(buffer, lines) abort
  " Matches patterns line the following:
  "
  " lib/filename.ex:19:7: F: Pipe chain should start with a raw value.
  let l:pattern = '\v:(\d+):?(\d+)?: (.): (.+)$'
  let l:output = []

  for l:line in a:lines
    let l:match = matchlist(l:line, l:pattern)

    if len(l:match) == 0
        continue
    endif

    let l:type = l:match[3]
    let l:text = l:match[4]

    if l:text == "Functions should have a @spec type specification."
      continue
    endif

    if l:type ==# 'C'
      let l:type = 'E'
    elseif l:type ==# 'R'
      let l:type = 'W'
    endif

    " vcol is Needed to indicate that the column is a character.
    call add(l:output, {
    \   'bufnr': a:buffer,
    \   'lnum': l:match[1] + 0,
    \   'col': l:match[2] + 0,
    \   'type': l:type,
    \   'text': l:text,
    \})
  endfor

  return l:output
endfunction

call ale#linter#Define('elixir', {
      \ 'name': 'mix',
      \ 'executable': 'mix',
      \ 'command': 'mix compile --warnings-as-errors%s',
      \ 'callback': function('s:ale_mix_compile') })

call ale#linter#Define('elixir', {
      \ 'name': 'filtered_credo',
      \ 'executable': 'mix',
      \ 'command': 'mix credo suggest --format=flycheck --read-from-stdin %s',
      \ 'callback': function('s:ale_filtered_credo') })

call ale#linter#Define('elixir', {
      \ 'name': 'dialyzer',
      \ 'executable': 'mix',
      \ 'command': 'mix dialyzer %s',
      \ 'callback': function('s:ale_dialyzer') })

highlight ALEErrorSign guibg=#073642 guifg=#dc322f
highlight ALEWarningSign guibg=#073642 guifg=#d33682
