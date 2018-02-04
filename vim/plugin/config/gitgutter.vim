nmap <silent> <space>gp <Plug>GitGutterPreviewHunk<bar>:exec('wincmd j')<bar>:exec('nnoremap q :wincmd q<lt>cr>')<cr>
nmap <silent> <space>gu <Plug>GitGutterUndoHunk
nmap <silent> <space>gs <Plug>GitGutterStageHunk
command! Grevert
      \  execute ":Gread"
      \| execute ":noautocmd w"
      \| execute ":GitGutter"
