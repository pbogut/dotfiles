call local#paranoicbackup#init()
call local#wipeout#init()
call local#combineselection#init()
call local#repl#init()
call local#setlocal#init()
call local#openscad#init()

nnoremap <silent> <space>l :call local#togglelist#locationlist()<cr>
nnoremap <silent> <space>q :call local#togglelist#quickfixlist()<cr>
