" vim-dadbod over SSH {{{

function! s:db_export(file, ...) abort
  let dir = trim(system('mktemp -d'))
  exec ('!~/.scripts/db-output-conv/conv.php ' . shellescape(expand('%')) . ' ' . shellescape(l:dir . '/db.csv') . ' | unoconv -d spreadsheet -o ' . shellescape(a:file) . ' ' . shellescape(l:dir . '/db.csv'))
endfunction

function! s:db_report(cmd, bang, line1, line2) abort
  let content = nvim_buf_get_lines(0, a:line1 - 1, a:line2, v:true)

  let sqlfile = trim(system('mktemp'))
  let result = system('~/.scripts/db-output-conv/report-form.php ' . shellescape(sqlfile), l:content)
  if v:shell_error == 15
    echom "Report canceled by user"
  endif
  if v:shell_error == 0
    if (!empty(a:bang))
      exec('DB! ' . a:cmd . ' < ' . sqlfile)
    else
      exec('DB ' . a:cmd . ' < ' . sqlfile)
    endif
  endif
endfunction

"Export result window
command! -bang -nargs=? -range=-1 -complete=file DBExport
      \ exe s:db_export(<q-args>, <bang>0)

"Ask for placeholder data with yad
command! -bang -nargs=? -range=% -complete=custom,db#command_complete DBReport
      \ exe s:db_report(<q-args>, <bang>0, <line1>, <count>)
