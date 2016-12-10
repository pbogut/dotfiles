" vim-composer
augroup pb_vimcomposergroup
  autocmd!
  autocmd User ProjectionistActivate call s:activate()
  autocmd FileType php silent! nmap gd :ComposerGoToDefinition<cr>
augroup END

command! ComposerGoToDefinition :call s:go_to_definition()
function! s:go_to_definition() abort
  let file = ''
  silent! let file = composer#autoload#find()
  if l:file == ''
    normal! gd
  else
    execute "normal \<plug>(composer-find)"
  endif
endfunction

function! s:activate() abort
  " set project root, so it is possible to travel to definitions
  " inside vendor directories
  for [root, attributes] in projectionist#query('project_root')
    let b:composer_root = root
  endfor
endfunction
