" new backup file every minute, coz I can
" its recreating file path and then save copy there with current time
" dont know how fast it will grow...

function! local#paranoicbackup#init()
  augroup pb_paranoicbackup
    autocmd!
    autocmd BufWritePre * call local#paranoicbackup#write()
  augroup END
endfunction

function! local#paranoicbackup#write()
  let dir = get(g:, 'paranoic_backup_dir' , $HOME . '/.vim/paranoic_backup')
  if isdirectory(l:dir) != 1
    silent execute "!mkdir -p " . fnameescape(l:dir)
  endif
  if isdirectory(l:dir . '/.git') != 1
     silent execute '!sh -c "cd ' . fnameescape(l:dir) . ' && git init "'
  endif
  let filedir = l:dir . '/' . expand('%:p:h')
  let filename = expand('%:t')
  let timestamp = strftime("%Y-%m-%d %H:%M:%S")
  let fullpath = l:filedir . '/' . l:filename
  let escdir = fnameescape(l:filedir)
  let escfile = fnameescape(l:fullpath)
  let message = l:timestamp . " "
        \ . substitute(l:fullpath, '^.\{4,}\(.\{27}\)$', '...\1','')
  silent execute "!mkdir -p " . l:escdir
  silent execute "keepalt w! " . l:escfile
  silent execute "!sh -c \"cd " . l:escdir .
        \ " && git add " . l:escfile .
        \ " && git commit ". l:escfile . " -m'" . l:message . "'\" > /dev/null &"
endfunction
