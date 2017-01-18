" Neomake
" Autocommands
augroup neomakegroup
  autocmd!
  autocmd BufWritePost * NeomakeWithSpellCheck
  autocmd BufRead * NeomakeWithSpellCheck
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
let g:neomake_info_sign = {'text': '➤'}
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

" let g:neomake_elixir_enabled_makers = []
let g:neomake_elixir_enabled_makers = ['credo']
" let g:neomake_elixir_credo_maker = neomake#makers#ft#elixir#credo()
" let g:neomake_elixir_credo_maker.args = ['credo', 'list', '%:p', '--format=oneline']

let g:neomake_xml_enabled_makers = ['xmllint']
let g:neomake_xml_xmllint_maker =
      \ {
      \   'errorformat': '%A%f:%l:\ %m'
      \ }

" Source Code Spell Checker
function! NeomakeWithSpellCheck(entry)
  let a:entry.type = "I"
  let line = getline(a:entry.lnum)
  let word = substitute(a:entry.text, "[^']'\\(.\\{-}\\)'.*", "\\1", "")
  let token = substitute(a:entry.text, ".*(from token '\\(.\\{-}\\)'.*", "\\1", "")
  let offset = stridx(tolower(token), word)
  let a:entry.col = stridx(line, token) + offset + 1
endfunction

let s:spellcheck_types = [
      \ 'elixir', 'php', 'bash', 'mail',
      \ 'ruby', 'go', 'markdown',
      \ 'javascript', 'git', 'vim']

function! s:neomake_with_spellcheck() abort
  if index(s:spellcheck_types, &ft) == -1
    return
  endif
  if empty(get(g:, 'neomake_' . &ft . '_scspell_maker', ''))
    let g:['neomake_' . &ft . '_scspell_maker'] = {
          \   'exe': 'scspell',
          \   'args': ['--report-only'],
          \   'postprocess': function('NeomakeWithSpellCheck'),
          \ }
    " let g:['neomake_' . &ft . '_scspell_maker'] = {
    "       \   'exe': 'scaspell.rb',
    "       \   'args': [],
    "       \   'postprocess': function('NeomakeWithSpellCheck'),
    "       \ }
  endif
  let list = get(g:, 'neomake_' . &ft . '_enabled_makers', [])
  execute ':Neomake ' . join(list) . ' scspell'
endfunction

command! NeomakeWithSpellCheck call s:neomake_with_spellcheck()
