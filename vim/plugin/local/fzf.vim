" prepare params
function! s:params(params)
  let params = join(a:params, ' ')
  if (len(params) && params[0] != '-')
    let params = '-q ' . shellescape(params)
  endif

  return params
endfunction

" fzf git ls
function! s:fzf_git_ls_sink(line)
  let result = substitute(a:line, '^...', '', '')
  execute('e ' . result)
endfunction

function! local#fzf#all_files(...) abort
  let options = {
        \   'options': '--prompt "All files> " ' . s:params(a:000),
        \ }
  let extra = extend(copy(get(g:, 'fzf_layout', {'down': '~40%'})), options)
  call fzf#run(fzf#wrap('name', extra, 0))
endfunction

function! local#fzf#files(...) abort
  let options = {
        \   'source': 'ag -l -g ""',
        \   'options': '--prompt "Files> " ' . s:params(a:000),
        \ }
  let extra = extend(copy(get(g:, 'fzf_layout', {'down': '~40%'})), options)
  call fzf#run(fzf#wrap('name', extra, 0))
endfunction

function! local#fzf#git_ls(...) abort
  let options = {
        \   'source': '{git -c color.status=always status --short; git ls-files | while read l; do echo -e "\033[0;34mG\033[0m  $l";done }',
        \   'sink': function('s:fzf_git_ls_sink'),
        \   'options': '--ansi --prompt "Git> " ' . s:params(a:000),
        \ }
  let extra = extend(copy(get(g:, 'fzf_layout', {'down': '~40%'})), options)
  call fzf#run(fzf#wrap('name', extra, 0))
endfunction

" Better Ag search (with optional dir specified)
function! s:fzf_ag_process(string, escape) abort
  if a:escape
    return shellescape(a:string)
  else
    return a:string
  endif
endfunction

function! local#fzf#ag(raw, ...) abort
  let dir = a:000[-1]
  if dir=~ '/$' && isdirectory(dir)
    let params = s:fzf_ag_process(join(a:000[0:-2], ' '), !a:raw) . ' ' . dir
  else
    let params = s:fzf_ag_process(join(a:000, ' '), !a:raw)
  endif
  echo "!ag " . params
  call fzf#vim#ag_raw(params)
endfunction

command! -nargs=* -bang Ag call local#fzf#ag(<bang>0,<f-args>)
