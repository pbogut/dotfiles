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
      \ 'elixir': ['filtered_credo']
      \}

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
      \ 'name': 'filtered_credo',
      \ 'executable': 'mix',
      \ 'command': 'mix credo suggest --format=flycheck --read-from-stdin %s',
      \ 'callback': function('s:ale_filtered_credo') })

highlight ALEErrorSign guibg=#073642 guifg=#dc322f
highlight ALEWarningSign guibg=#073642 guifg=#d33682
