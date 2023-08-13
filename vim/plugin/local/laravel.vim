" Simple Laravel integration

function! local#laravel#complete(A,L,P)
  return system("php artisan --no-ansi | sed \"1,/Available commands/d\" | awk '/^ +[a-z]+/ { print $1 }'")
endfun

function! s:sink(cmd, winnr, c, lines, stream)
  let filename = ''
  let fullname = ''

  if (a:cmd == 'make:migration')
    let filename = substitute(a:lines[0], '.* \(\d\{4}_\d\{2}_\d\{2}_[a-zA-Z0-9_]*\).*', '\1', '')
    let fullname = 'database/migrations/' . l:filename . '.php'
  endif
  if (a:cmd == 'make:job')
    echom(a:lines[0])
    " let filename = substitute(a:lines[0], '.* \(\d\{4}_\d\{2}_\d\{2}_[a-zA-Z0-9_]*\).*', '\1', '')
    " let fullname = 'database/migrations/' . l:filename . '.php'
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
  let root = getcwd()
  let artisan = get(b:, 'laravel_artisan_command', 'php {}/artisan')

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


function! local#laravel#find_template_usage(...)
  let bang = get(a:000, 0, 0)
  if !empty(get(a:000, 1, 1))
    let temp_file = a:1
  else
    let temp_file = expand('%')
  endif
  let template = substitute(l:temp_file, '.blade.php$', '', '')
  let template = substitute(l:template, '^resources/views/', '', '')
  let template = substitute(l:template, '/', '\.', 'g')

  if (temp_file =~ '.blade.php$')
    exec('Rg ' . template)
  else
    echom('Not a blade template file')
  endif


endfunction

command! -nargs=* -bang -complete=custom,local#laravel#complete Artisan call local#laravel#run(<bang>0,<q-args>)
command! -nargs=* -bang FindTemplateUsage call local#laravel#find_template_usage(<bang>0,<q-args>)

map <space>gu :FindTemplateUsage<cr>
