augroup pb_templates
  autocmd!
  autocmd BufNewFile * silent! call templates#InsertSkeleton()
augroup END

command! -nargs=? Skel call templates#InsertSkeleton(<f-args>)
