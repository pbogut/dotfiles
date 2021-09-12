vim.cmd([[
  imap <expr> <tab> snippy#can_expand() ? '<Plug>(snippy-expand)' : '<tab>'
  imap <expr> <C-j> snippy#can_jump(1) ? '<Plug>(snippy-next)' : '<c-j>'
  imap <expr> <C-k> snippy#can_jump(-1) ? '<Plug>(snippy-previous)' : '<c-k>'
  smap <expr> <C-j> snippy#can_jump(1) ? '<Plug>(snippy-next)' : '<c-j>'
  smap <expr> <C-k> snippy#can_jump(-1) ? '<Plug>(snippy-previous)' : '<c-k>'
]])
