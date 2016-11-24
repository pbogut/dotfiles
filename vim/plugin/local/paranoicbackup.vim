" new backup file every minute, coz I can
" its recreating file path and then save copy there with current time
" dont know how fast it will grow...

function! local#paranoicbackup#init()
  augroup paranoicbackup
    autocmd!
    autocmd BufWritePre * call local#paranoicbackup#write()
  augroup END
endfunction

function! local#paranoicbackup#write()
  let dir = get(g:, 'paranoic_backup_dir' , '~/.vim/paranoic_backup/')
  let filedir = dir . expand('%:p:h')
  let filename = expand('%:t')
  let timestamp = strftime("___%y%m%d_%H%M")
  silent execute "!mkdir -p " . fnameescape(filedir)
  silent execute "keepalt w! " . fnameescape(filedir . '/' . filename . timestamp)
endfunction

