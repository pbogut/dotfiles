if !has('nvim')
  finish
endif

let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_enter = 0
let g:ale_php_phpcs_executable = $HOME . '/.bin/phpcs'
let g:ale_php_phpcs_use_global = 1

augroup pb_alegroup
  autocmd!
  autocmd InsertEnter php call s:ale_init_php()
  autocmd FileType php call s:ale_init_php()
  autocmd TextChanged * call s:ale_lint('normal')
  autocmd TextChangedI * call s:ale_lint('insert')
augroup END

let g:ale_lint_on_save = 1
" to disable autocommand set up by ale
let g:ale_lint_on_text_changed = 'never'
let g:ale_command_wrapper = 'nice -n15'

let g:ale_lint_on_text_changed_default = 'never'
" file needs to be saved anyway, so dont do anything on change
let g:ale_lint_on_text_changed_eelixir = 'never'
let g:ale_lint_on_text_changed_elixir = 'never'
" linting elm takes too long to do this when file chaneg
let g:ale_lint_on_text_changed_elm = 'never'

let g:ale_sign_error = '✖'
let g:ale_sign_error = ''
let g:ale_sign_warning = '⚠'
let g:ale_sign_warning = ''

let g:ale_sign_column_always = 1

let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%severity%][%linter%] %s'

" wrapper around ale linting to allow lint setup by file tyep
function! s:ale_lint(type)
  let action = get(g:, 'ale_lint_on_text_changed_' . &ft)
  if empty(l:action)
    let action = g:ale_lint_on_text_changed_default
  endif

  if l:action == 'always' || l:action == a:type
    call ale#Queue(g:ale_lint_delay)
  endif
endfunction

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
      \ 'elixir': ['mix'],
      \}
" \ 'elixir': ['mix', 'dialyzer']

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

let g:ale_elixir_mix_compile_current_app = ''
function! s:ale_mix_compile(buffer, lines) abort


  let l:app_pattern = '\v^\=\=\> (.+)$'

  " Matches patterns line the following:
  "
  " ** (SyntaxError) lib/issues.ex:18: syntax error before: kota
  " (elixir) lib/kernel/parallel_compiler.ex:198: anonymous fn/4 in Kernel.ParallelCompiler.spawn_workers/6
  let l:pattern = '\v(\(.*\) )(.*):(\d+): (.+)$'
  let l:output = []

  let l:app_path = ''

  for l:line in a:lines
    let l:app_pattern = '\v^\=\=\> (.+)$'
    let l:app_match = matchlist(l:line, l:app_pattern)
    if len(l:app_match) != 0
      let l:app_path = 'apps/' . l:app_match[1] . '/'
      continue
    endif

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

    if bufname(a:buffer) != l:app_path . l:match[2]
      continue
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

call ale#linter#Define('elixir', {
      \ 'name': 'mix',
      \ 'executable': 'mix',
      \ 'command': 'mix compile --warnings-as-errors%s',
      \ 'callback': function('s:ale_mix_compile') })

call ale#linter#Define('elixir', {
      \ 'name': 'dialyzer',
      \ 'executable': 'mix',
      \ 'command': 'mix dialyzer %s',
      \ 'callback': function('s:ale_dialyzer') })

highlight ALEErrorSign guibg=#073642 guifg=#dc322f
highlight ALEWarningSign guibg=#073642 guifg=#d33682

autocmd User after_vim_load
      \  highlight ALEErrorSign guibg=#073642 guifg=#dc322f
      \| highlight ALEWarningSign guibg=#073642 guifg=#d33682
