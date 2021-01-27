" vim-dadbod over SSH {{{

let s:url_pattern = '\%([abgltvw]:\w\+\|\a[[:alnum:].+-]\+:\S*\|\$[[:alpha:]_]\S*\|[.~]\=/\S*\|[.~]\|\%(type\|profile\)=\S\+\)\S\@!'
let s:tunnels = {}
let s:wait = v:false

function! GetDBs(...) abort
  let scope = 'g'
  if a:0 == 1 && len(a:1) == 1
    let scope = a:1
  endif
  return s:db_command_complete(scope . ':', 'DB ' . scope . ':', 5)
endfunction

function! s:cmd_split(cmd) abort
  let url = matchstr(a:cmd, '^'.s:url_pattern)
  let cmd = substitute(a:cmd, '^'.s:url_pattern.'\s*', '', '')
  return [url, cmd]
endfunction

function! s:on_event(job_id, data, event) dict
  if a:event == 'stdout'
    let str = self.tunnel_id . ' stdout: '.join(a:data)
    if str =~ 'ssh_connected'
      let s:wait = v:false
      if !empty(self.params)
        return call('db#execute_command', self.params)
      else
        " if no params do nothing
        return
      endif
    endif
  elseif a:event == 'stderr'
    let str = self.tunnel_id . ' stderr: '.join(a:data)
    if str =~ 'Address already in use' || str =~ 'Pseudo-terminal will not be allocated'
      return
    endif
  else
    let s:wait = v:false
    if (!empty(get(s:tunnels, self.tunnel_id)))
      call remove(s:tunnels, self.tunnel_id)
    endif
    let str = self.tunnel_id . ' exited'
    echom str
  endif
  if len(get(l:, 'str')) > len(self.tunnel_id . ' stdout: ')
    echom str
  endif
endfunction

function! s:prepare_url(url) abort
  " let [url, cmd] = s:cmd_split(a:cmd)
  let url = a:url

  if url =~# '^\%([abgltwv]:\|\$\)\w\+$'
    let url = eval(url)
  endif

  let ssh = substitute(l:url, '^ssh:\(.\{-}\):.*', '\1', '')
  let clean_url = substitute(l:url, '^ssh:.\{-}:\(.*\)', '\1', '')

  if clean_url == url
    return url
  endif

  let result = db#url#parse(clean_url)

  let scheme = get(result, 'scheme')
  let port = get(result, 'port', get(s:default_ports, scheme))
  let host = get(result, 'host', '127.0.0.1')
  let tunnel_id = ssh . ':' . host . ':' . port

  let result['host'] = '127.0.0.1'

  let current_port = get(s:tunnels, tunnel_id)
  if (!empty(current_port))
    let redirect_port = current_port
  else
    let redirect_port = system('get-free-port.php ' . s:first_port)
  endif


  let ssh_redirect = redirect_port . ':' . host . ':' .port
  let result['port'] = redirect_port

  if empty(current_port)
    let s:tunnels[tunnel_id] = redirect_port
    let s:wait = v:true
    let job = jobstart(['ssh', '-L', ssh_redirect, ssh, '-t', 'echo ssh_connected; read'], extend({
          \   'tunnel_id': tunnel_id,
          \   'params': []
          \ }, s:callbacks))

    "max wait 100 * 100ms = 10s
    let max_wait = 100
    while s:wait && l:max_wait > 0
      " wait for ssh connectiont
      sleep 100m
      let max_wait -= 1
    endwhile
  endif

  let new_url = db#url#format(result)
  return l:new_url
endfunction


let s:callbacks = {
      \ 'on_stdout': function('s:on_event'),
      \ 'on_stderr': function('s:on_event'),
      \ 'on_exit': function('s:on_event')
      \ }

let s:first_port = 7000
let s:default_ports = {
      \   'mysql': 3306,
      \   'postgresql': 5432
      \ }

" for connection completion
let g:db_adapters = {'ssh': 'ssh'}

function! s:db_command_complete(A, L, P) abort
  let arg = substitute(strpart(a:L, 0, a:P), '^.\{-\}DB\(Report\=\)\=!\=\s*', '', '')
  if arg =~# '^\%(\w:\|\$\)\h\w*\s*=\s*\S*$'
    return join(db#url_complete(a:A), "\n")
  endif
  let [url, cmd] = s:cmd_split(arg)
  if cmd =~# '^<'
    return join(s:glob(a:A, 0), "\n")
  elseif a:A !=# arg
    let clean_url = s:prepare_url(url)
    let conn = db#connect(clean_url)
    return join(db#adapter#call(conn, 'tables', [conn], []), "\n")
  elseif a:A =~# '^[[:alpha:]]:[\/]\|^[.\/~$]'
    return join(s:glob(a:A, 0), "\n")
  elseif a:A =~# '^[[:alnum:].+-]\+\%(:\|$\)' || empty(a:A)
    return join(db#url_complete(a:A), "\n")
  endif
  return ""
endfunction

function! s:db_execute_command(mods, bang, line1, line2, cmd) abort
  " it creates ssh port tunnel and then changes url to use tunnel port
  " this way adapters works nativly with no issues
  let [url, cmd] = s:cmd_split(a:cmd)

  if cmd =~# '^=' && a:line2 <= 0
    let target = substitute(cmd, '^=\s*', '', '')
    if empty(url)
      let url = 'w:db'
    elseif url =~ '^\w:$'
      let url .= 'db'
    endif
    if url =~# '^\%([abgltwv]:\|\$\)\w\+$'
      return 'let ' . url . ' = '.string(target)
    endif
    throw 'DB: invalid variable: '.url
  endif

  if url =~# '^\%([abgltwv]:\|\$\)\w\+$'
    let url = eval(url)
    let clean_url = substitute(l:url, '^ssh:.\{-}:\(.*\)', '\1', '')
  endif


  let ssh = substitute(l:url, '^ssh:\(.\{-}\):.*', '\1', '')
  let clean_url = substitute(l:url, '^ssh:.\{-}:\(.*\)', '\1', '')

  if clean_url == url
    call db#execute_command(a:mods, a:bang, a:line1, a:line2, a:cmd)
    return
  endif

  let result = db#url#parse(clean_url)

  let scheme = get(result, 'scheme')
  let port = get(result, 'port', get(s:default_ports, scheme))
  let host = get(result, 'host', '127.0.0.1')
  let tunnel_id = ssh . ':' . host . ':' . port

  let result['host'] = '127.0.0.1'

  let current_port = get(s:tunnels, tunnel_id)
  if (!empty(current_port))
    let redirect_port = current_port
  else
    let redirect_port = system('get-free-port.php ' . s:first_port)
  endif


  let ssh_redirect = redirect_port . ':' . host . ':' .port
  let result['port'] = redirect_port

  let new_cmd = db#url#format(result) . ' ' . l:cmd

  if empty(current_port)
    let s:tunnels[tunnel_id] = redirect_port
    let job = jobstart(['ssh', '-L', ssh_redirect, ssh, '-t', 'echo ssh_connected; read'], extend({
          \   'tunnel_id': tunnel_id,
          \   'params': [a:mods, a:bang, a:line1, a:line2, l:new_cmd]
          \ }, s:callbacks))
  else
    call db#execute_command(a:mods, a:bang, a:line1, a:line2, l:new_cmd)
  endif
endfunction


"Remote DB command
command! -bang -nargs=? -range=-1 -complete=custom,s:db_command_complete DB
      \ exe s:db_execute_command('<mods>', <bang>0, <line1>, <count>, substitute(<q-args>,
      \ '^[al]:\w\+\>\ze\s*\%($\|[^[:space:]=]\)', '\=eval(submatch(0))', ''))

" }}} vim-dadbod over SSH


function! s:db_export(file, ...) abort
  let dir = trim(system('mktemp -d'))
  exec ('!~/.scripts/db-output-conv/conv.php ' . shellescape(expand('%')) . ' ' . shellescape(l:dir . '/db.csv') . ' | unoconv -d spreadsheet -o ' . shellescape(a:file) . ' ' . shellescape(l:dir . '/db.csv'))
endfunction

"Export result window
command! -bang -nargs=? -range=-1 -complete=file DBExport
      \ exe s:db_export(<q-args>, <bang>0)


function! s:db_report(cmd, bang, line1, line2) abort
  let content = nvim_buf_get_lines(0, a:line1 - 1, a:line2, v:true)

  let sqlfile = trim(system('mktemp'))
  let result = system('~/.scripts/db-output-conv/report-form.php ' . shellescape(sqlfile), l:content)
  if v:shell_error == 15
    echom "Report canceled by user"
  endif
  if v:shell_error == 0
    if (!empty(a:bang))
      exec('DB! ' . a:cmd . ' < ' . sqlfile)
    else
      exec('DB ' . a:cmd . ' < ' . sqlfile)
    endif
  endif
endfunction

"Ask for placeholder data with yad
command! -bang -nargs=? -range=% -complete=custom,s:db_command_complete DBReport
      \ exe s:db_report(<q-args>, <bang>0, <line1>, <count>)


" Example:
" DB g:my_db = ssh:myremote.host:mysql://username:password@db.ip/db_name

if filereadable($HOME . '/.config/nvim/config/dadbod.secret.vimrc')
  source ~/.config/nvim/config/dadbod.secret.vimrc
endif
