let g:signify_vcs_list = [ 'git' ]
let g:signify_sign_add = '+'
let g:signify_sign_delete = '_'
let g:signify_sign_delete_first_line = '‾'
let g:signify_sign_change = '~'
let g:signify_sign_changedelete = '~'
let g:signify_sign_show_count = 0

omap ic <plug>(signify-motion-inner-pending)
xmap ic <plug>(signify-motion-inner-visual)
omap ac <plug>(signify-motion-outer-pending)
xmap ac <plug>(signify-motion-outer-visual)

nmap <space>gd :SignifyDiff<cr>

command! Grevert
      \  execute ":Gread"
      \| execute ":noautocmd w"
      \| execute ":SignifyRefresh"
