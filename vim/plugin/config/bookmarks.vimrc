" vim bookmarks
let g:bookmark_annotation_sign = ''
let g:bookmark_no_default_key_mappings = 1

" highlight BookmarkSign guibg=#073642 guifg=#93a1a1
" highlight BookmarkAnnotationSign guibg=#073642 guifg=#93a1a1

nmap gmm <Plug>BookmarkToggle
nmap gmi <Plug>BookmarkAnnotate
nmap gma <Plug>BookmarkShowAll
nmap gmj <Plug>BookmarkNext
nmap gmk <Plug>BookmarkPrev
nmap gmC <Plug>BookmarkClear
nmap gmX <Plug>BookmarkClearAll
nmap gmK <Plug>BookmarkMoveUp
nmap gmJ <Plug>BookmarkMoveDown
nmap gmg :BookmarkMove<cr>

function! s:bookmark_move()
  call inputsave()
  let line = input('Move bookmark: ')
  call inputrestore()
  redraw!

  if l:line <= 0
    call BookmarkModify(str2nr(l:line))
  elseif l:line[0] == '+'
    call BookmarkModify(str2nr(l:line[1:]))
  else
    call BookmarkMoveToLine(str2nr(l:line))
  endif
endfunction
command! BookmarkMove call s:bookmark_move()

" vim bookmarks
highlight BookmarkSign guibg=#073642 guifg=#93a1a1
highlight BookmarkAnnotationSign guibg=#073642 guifg=#93a1a1
