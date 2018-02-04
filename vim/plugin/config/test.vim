let g:test#strategy = 'neovim'
function! FixTestFileMod() abort
  if &ft == 'elixir'
    let g:test#filename_modifier = ':p'
  elseif (!empty(get(g:, 'test#filename_modifier')))
    unlet g:test#filename_modifier
  endif
endfunction
nmap <silent> <space>tn :call FixTestFileMod() <bar> TestNearest<CR>
nmap <silent> <space>tf :call FixTestFileMod() <bar> TestFile<CR>
nmap <silent> <space>ts :call FixTestFileMod() <bar> TestSuite<CR>
nmap <silent> <space>tl :call FixTestFileMod() <bar> TestLast<CR>
nmap <silent> <space>tt :call FixTestFileMod() <bar> TestLast<CR>
nmap <silent> <space>tv :call FixTestFileMod() <bar> TestVisit<CR>
