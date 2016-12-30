" prepare params
function! s:params(params)
  let preview = get(g:,'fzf_preview', '')
  let params = join(a:params, ' ')
  if (len(params) && params[0] != '-')
    let params = '-q ' . shellescape(params)
  endif

  return preview . ' ' . params
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

function! s:fzf_ag_params(raw, params) abort
  if empty(a:params)
    return get(s:, 'last_ag_params', '')
  endif

  let dir = a:params[-1]
  if dir=~ '/$' && isdirectory(dir)
    let params = s:fzf_ag_process(join(a:params[0:-2], ' '), !a:raw) . ' ' . dir
  else
    let params = s:fzf_ag_process(join(a:params, ' '), !a:raw)
  endif
  let s:last_ag_params = l:params
  return l:params
endfunction

function! local#fzf#ag(raw, ...) abort
  let params = s:fzf_ag_params(a:raw, a:000)
  echo "!ag " . params
  call fzf#vim#ag_raw(params)
endfunction

function! local#fzf#agg(raw, ...) abort
  let params = s:fzf_ag_params(a:raw, a:000)
  silent! execute ":silent! grep " . params
  echo ":grep " . params
endfunction

command! -nargs=* -bang -complete=dir Ag call local#fzf#ag(<bang>0,<f-args>)
command! -nargs=* -bang -complete=dir Agg call local#fzf#agg(<bang>0,<f-args>)
