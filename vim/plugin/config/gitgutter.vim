nmap <silent> <leader>gp <Plug>GitGutterPreviewHunk<bar>:exec('wincmd j')<bar>:exec('nnoremap q :wincmd q<lt>cr>')<cr>
nmap <silent> <leader>gu <Plug>GitGutterUndoHunk
nmap <silent> <leader>gs <Plug>GitGutterStageHunk
command! Grevert
      \  execute ":Gread"
      \| execute ":noautocmd w"
      \| execute ":GitGutter"
