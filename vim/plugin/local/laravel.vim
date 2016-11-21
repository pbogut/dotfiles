" Simple Laravel integration

function! local#laravel#complete(A,L,P)
  return system("php artisan --no-ansi | sed \"1,/Available commands/d\" | awk '/^ +[a-z]+/ { print $1 }'")
endfun

function! local#laravel#run(bang, command)
  let root = projectroot#guess()
  if filereadable(root . '/artisan')
    rightbelow 11split | execute(":te php " . root . "/artisan " . a:command)
  else
    echo "It looks like it's not a Laravel project (artisan missing in " . root . ")."
  endif
endfun

command! -nargs=* -bang -complete=custom,local#laravel#complete Artisan call local#laravel#run(<bang>0,<q-args>)
