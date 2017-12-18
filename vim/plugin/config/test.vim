let g:test#strategy = 'neovim'
function! FixTestFileMod() abort
  if &ft == 'elixir'
    let g:test#filename_modifier = ':p'
  elseif (!empty(get(g:, 'test#filename_modifier')))
    unlet g:test#filename_modifier
  endif
endfunction
nmap <silent> <leader>tn :call FixTestFileMod() <bar> TestNearest<CR>
nmap <silent> <leader>tf :call FixTestFileMod() <bar> TestFile<CR>
nmap <silent> <leader>ts :call FixTestFileMod() <bar> TestSuite<CR>
nmap <silent> <leader>tl :call FixTestFileMod() <bar> TestLast<CR>
nmap <silent> <leader>tt :call FixTestFileMod() <bar> TestLast<CR>
nmap <silent> <leader>tv :call FixTestFileMod() <bar> TestVisit<CR>
