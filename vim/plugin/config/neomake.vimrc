" Neomake
" Autocommands
augroup neomakegroup
  autocmd!
  autocmd BufWritePost * Neomake
  autocmd BufRead * Neomake
  autocmd FileType php call s:init_php()
  autocmd User ProjectionistActivate call s:activate()
augroup END

" projectionist maker config
" format "*": {"maker": {"name": "elixir", "props": {"exe": "elixirc"}}}
function! s:activate() abort
  for [root, attributes] in projectionist#query('maker')
    let maker = attributes.name
  endfor
  for [root, attributes] in projectionist#query('maker')
    let props = get(attributes, 'props', {})
    for property in keys(props)
      let value = get(props, property)
      let b:["neomake_" . &ft . "_" . l:maker ."_" . l:property] = l:value
    endfor
  endfor
endfunction

function! s:init_php()
  if !empty(get(b:, 'neomake_php_phpmd_args'))
    return
  endif

  " phpmd.xml for neomake @todo fallback to getcwd()
  let phpmd_xml_file = projectroot#guess() . '/phpmd.xml'
  if filereadable(phpmd_xml_file)
    let b:neomake_php_phpmd_args = ['%:p', 'text', phpmd_xml_file]
  else
    let b:neomake_php_phpmd_args = ['%:p', 'text', 'codesize,design,unusedcode,naming']
  endif
endfunction

" Messages
let g:neomake_error_sign = {'texthl': 'ErrorMsg'}
let g:neomake_warning_sign = {'texthl': 'WarningMsg'}
" highlight NeomakeErrorSign ctermfg=223 ctermbg=223 " cant make it work ;/
" let g:neomake_error_sign = {'text': '✖', 'texthl': 'NeomakeErrorSign'}
" let g:neomake_warning_sign = {'text': '⚠', 'texthl': 'NeomakeWarningSign'}
" let g:neomake_message_sign = {'text': '➤', 'texthl': 'NeomakeMessageSign'}
" let g:neomake_info_sign = {'text': 'ℹ', 'texthl': 'NeomakeInfoSign'}

function! NeomakeSetWarningType(entry)
  let a:entry.type = "W"
endfunction
function! NeomakeSetInfoType(entry)
  let a:entry.type = "I"
endfunction
function! NeomakeSetMessageType(entry)
  let a:entry.type = "M"
endfunction

" Makers
let g:neomake_php_enabled_makers = ['php', 'phpmd', 'phpcs']
let g:neomake_php_phpcs_maker = neomake#makers#ft#php#phpcs()
let g:neomake_php_phpcs_maker.postprocess = function('NeomakeSetMessageType')
let g:neomake_php_phpmd_maker = neomake#makers#ft#php#phpmd()
let g:neomake_php_phpmd_maker.postprocess = function('NeomakeSetWarningType')

let g:neomake_elixir_enabled_makers = ['credo']
let g:neomake_elixir_credo_maker = neomake#makers#ft#elixir#credo()
let g:neomake_elixir_credo_maker.args = ['credo', 'list', '%:p', '--format=oneline']

let g:neomake_xml_enabled_makers = ['xmllint']
let g:neomake_xml_xmllint_maker =
      \ {
      \   'errorformat': '%A%f:%l:\ %m'
      \ }
