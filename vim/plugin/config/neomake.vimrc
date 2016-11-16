" Neomake
if exists(':Neomake')
  " Autocommands
  augroup neomakegroup
    autocmd!
    autocmd BufWritePost * Neomake
    autocmd BufWritePre php call NeomakePreWritePhp()
    autocmd FileType php call NeomakeInitPhp()
  augroup END

  function! NeomakePreWritePhp()
    if exists('b:neomake_php_phpmd_maker_args')
      let g:neomake_php_phpmd_maker.args = b:neomake_php_phpmd_maker_args
    endif
  endfunction

  function! NeomakeInitPhp()
    if get(b:, 'neomake_php_initialized')
      return
    endif
    let b:neomake_php_initialized = 1

    " phpmd.xml for neomake @todo fallback to getcwd()
    let phpmd_xml_file = silent! projectroot#guess() . '/phpmd.xml'
    if filereadable(phpmd_xml_file)
      let b:neomake_php_phpmd_maker_args = ['%:p', 'text', phpmd_xml_file]
    else
      let b:neomake_php_phpmd_maker_args = ['%:p', 'text', 'codesize,design,unusedcode,naming']
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

  let g:neomake_elixir_enabled_makers = ['elixir']
  let g:neomake_elixir_mix_maker =
        \ {
        \   'exe' : 'mix',
        \   'args': ['compile', '--warnings-as-errors'],
        \   'cwd': getcwd(),
        \   'errorformat': '** %s %f:%l: %m,%f:%l: warning: %m'
        \ }
  let g:neomake_elixir_elixir_maker =
        \ {
        \   'exe': 'elixirc',
        \   'args': [
        \     '--ignore-module-conflict', '--warnings-as-errors',
        \     '--app', 'mix', '--app', 'ex_unit',
        \     '-o', $TMPDIR, '%:p'
        \   ],
        \   'errorformat': '%E** %s %f:%l: %m,%W%f:%l'
        \ }

  let g:neomake_xml_enabled_makers = ['xmllint']
  let g:neomake_xml_xmllint_maker =
        \ {
        \   'errorformat': '%A%f:%l:\ %m'
        \ }
end
