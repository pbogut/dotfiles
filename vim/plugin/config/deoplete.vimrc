" Deoplete
if !has('nvim')
  finish
endif

let g:deoplete#enable_at_startup = 1
let g:deoplete#auto_complete_start_length = 1
let g:deoplete#enable_debug=1
let g:deoplete#sources#padawan#add_parentheses = 1
let g:deoplete#sources#padawan#auto_update = 0
let g:deoplete#skip_chars = ['$']
" let g:deoplete#skip_chars = ['$']
" let g:deoplete#sources = {}
" let g:deoplete#sources._ = ['buffer']
" let g:deoplete#sources.php = ['buffer', 'tag', 'member', 'file']
" let g:deoplete#ignore_sources = {}
" let g:deoplete#ignore_sources.php = ['omni']
command! PadawanStart call deoplete#sources#padawan#StartServer()
command! PadawanStop call deoplete#sources#padawan#StopServer()
command! PadawanRestart call deoplete#sources#padawan#RestartServer()
command! PadawanInstall call deoplete#sources#padawan#InstallServer()
command! PadawanUpdate call deoplete#sources#padawan#UpdateServer()
command! -bang PadawanGenerate call deoplete#sources#padawan#Generate(<bang>0)

" dont use enter to select item
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function() abort
  return deoplete#close_popup() . "\<CR>"
endfunction
