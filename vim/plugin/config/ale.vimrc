" Ale -- to be moved!!!!! START

augroup pb_alegroup
  autocmd!
  autocmd InsertEnter php call s:ale_init_php()
  autocmd FileType php call s:ale_init_php()
augroup END

let g:ale_lint_on_save = 1

let g:ale_sign_error = '✖'
let g:ale_sign_warning = '⚠'
let g:ale_sign_column_always = 1

let g:ale_javascript_eslint_options = "--rule 'semi: [1, always]'"
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
