" Simple Laravel integration

function! local#laravel#complete(A,L,P)
  return system("php artisan --no-ansi | sed \"1,/Available commands/d\" | awk '/^ +[a-z]+/ { print $1 }'")
endfun

function! s:sink(cmd, winnr, c, lines, stream)
  if (a:cmd == 'make:migration')
    let filename = substitute(a:lines[0], '.* \(\d\{4}_\d\{2}_\d\{2}_[a-zA-Z0-9_]*\).*', '\1', '')
    let fullname = 'database/migrations/' . l:filename . '.php'
  endif

  if !empty(l:fullname) && filereadable(l:fullname)
    if (confirm('Do you want to open ' . l:fullname . ' file?', "&Yes\n&No", 1) == 1)
      exec('silent! Bdelete!')
      exec('wincmd q')
      exec(a:winnr . 'wincmd w')
      exec('e ' . l:fullname)
    endif
  endif
endfunction

function! local#laravel#run(bang, command)
  let root = projectroot#guess()
  let artisan = get(b:, 'laravel_artisan_command', 'php {}/artisan')

  for [p_root, p_artisan] in projectionist#query('artisan_command')
    let root = p_root
    let artisan = p_artisan
  endfor

  let artisan = substitute(artisan, '{}', root, '')
  if filereadable(root . '/artisan')
    let l:winnr = winnr()
    " rightbelow 11split | execute(":te " . artisan . " " . a:command)
    rightbelow 11split
          \| enew
          \| call termopen(artisan . " " . a:command, {
          \    'on_stdout': function('s:sink', [substitute(a:command, '\(^[^ ]*\).*', '\1', ''), l:winnr]),
          \    'stdout_buffered': v:true
          \  })
          \| startinsert
  else
    echo "It looks like it's not a Laravel project (artisan missing in " . root . ")."
  endif
endfun

command! -nargs=* -bang -complete=custom,local#laravel#complete Artisan call local#laravel#run(<bang>0,<q-args>)
