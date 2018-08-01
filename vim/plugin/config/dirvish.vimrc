augroup pb_dirvish
  autocmd!
  autocmd FileType dirvish
        \  nmap <buffer> <bs> <Plug>(dirvish_up)
        \| nmap <buffer> H <Plug>(dirvish_up)
        \| nmap <buffer> cc :DirvishCopy<cr>
        \| nmap <buffer> rr :DirvishRename<cr>
        \| nmap <buffer> mm :DirvishMove<cr>
        \| nmap <buffer> dd :DirvishDelete<cr>
        \| nmap <buffer> K :DirvishCreate<cr>
        \| nmap <buffer> A :DirvishCreate<cr>
        \| nnoremap <buffer> / /\ze[^\/]*[\/]\=$<Home>\c
        \| nnoremap <buffer> ? ?\ze[^\/]*[\/]\=$<Home>\c
augroup END

" dirvish
let g:dirvish_mode = ':sort r /[^\/]$/'
let g:echodoc_enable_at_startup = 1
if has('nvim')
  hi SpecialKey guibg=none
endif

function! s:copy()
  let from = getline('.')
  let extension = substitute(l:from, '.*/[^\.]*\(.\{-}\)$', '\1', '')
  let move_cursor = substitute(l:extension, '.', "\<left>", 'g')
  call inputsave()
  let to = input('!cp -r ' . l:from . ' -> ', l:from . l:move_cursor, 'file')
  call inputrestore()
  redraw!
  if !empty(l:to)
    silent exec ('!cp -r ' . l:from . ' ' . l:to)
    call append(line('.') - 1, l:to)
    normal k
    " Dirvish %
  endif
endfunction

function! s:move()
  let from = getline('.')
  let extension = substitute(l:from, '.*/\(.\{-}\)$', '\1', '')
  let move_cursor = substitute(l:extension, '.', "\<left>", 'g')
  call inputsave()
  let to = input('!mv ' . l:from . ' -> ', l:from . l:move_cursor, 'file')
  call inputrestore()
  redraw!
  if !empty(l:to)
    silent exec ('!mv ' . l:from . ' ' . l:to)
    call setline('.', l:to)
  endif
endfunction

function! s:rename()
  if getline('.')[-1:-1] == '/'
    let l:suffix = '/'
    let from = getline('.')[:-2]
  else
    let l:suffix = ''
    let from = getline('.')
  endif
  let dir_name = substitute(l:from, '\(.*/\).\{-}$', '\1', '')
  let file_name = substitute(l:from, '.*/\(.\{-}\)$', '\1', '')
  let extension = substitute(l:from, '.*/[^\.]*\(.\{-}\)$', '\1', '')
  let move_cursor = substitute(l:extension, '.', "\<left>", 'g')
  call inputsave()
  let to = input('!mv ' . l:from . ' -> '. l:dir_name, l:file_name . l:move_cursor, 'file')
  call inputrestore()
  redraw!
  if !empty(l:to)
    silent exec ('!mv ' . l:from . ' ' . l:dir_name . l:to)
    call setline('.', l:dir_name . l:to . l:suffix)
  endif
endfunction

function! s:delete()
  let file = getline('.')
  call inputsave()
  let confirm = input('!rm -fr ' . l:file . ' // Are you sure? [yes|no]: ')
  call inputrestore()
  redraw!
  if l:confirm == 'yes'
    silent exec ('!rm -fr ' . l:file)
    silent! exec ('bd! ' . l:file)
    Dirvish %
  endif
endfunction

function! s:file()
  let from = expand('%:p')
  call inputsave()
  let to = input('e ', l:from, 'file')
  call inputrestore()
  redraw!
  if !empty(l:to)
    silent exec ('e ' . l:to)
  endif
endfunction

function! s:mkdir()
  let from = expand('%:p')
  call inputsave()
  let to = input('!mkdir -p ', l:from, 'file')
  call inputrestore()
  redraw!
  if !empty(l:to)
    silent exec ('!mkdir -p ' . l:to)
    Dirvish %
  endif
endfunction

function! s:file_or_mkdir()
  let from = expand('%:p')
  call inputsave()
  let to = input('create: ', l:from, 'file')
  call inputrestore()
  redraw!
  if empty(l:to)
    return
  endif
  if l:to =~ '/$'
    let dir = l:to
  else
    let dir = substitute(l:to, '\(.*\)/[^/]\+', '\1', '')
  endif
  silent exec ('!mkdir -p ' . l:dir)
  silent exec ('e ' . l:to)
endfunction

command! DirvishCreate call s:file_or_mkdir()
command! DirvishMkdir call s:mkdir()
command! DirvishCopy call s:copy()
command! DirvishRename call s:rename()
command! DirvishMove call s:move()
command! DirvishDelete call s:delete()
command! DirvishFile call s:file()
