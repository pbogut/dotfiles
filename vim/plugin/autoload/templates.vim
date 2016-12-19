" templates

function! s:try_insert(skel)
  execute "normal! i_t_" . a:skel . "\<C-r>=UltiSnips#ExpandSnippet()\<CR>"

  if g:ulti_expand_res == 0
    silent! undo
  endif

  return g:ulti_expand_res
endfunction

function! templates#InsertSkeleton(...) abort
  let template = get(a:, 1)
  let filename = expand('%')

  " Abort on non-empty buffer or extant file
  if !(line('$') == 1 && getline('$') == '')
    echom "You can use skeleton only in empty file."
    return
  endif

  " try selected template
  if !empty(a:000) && s:try_insert(template)
    return
  endif

  if !empty(get(b:,'projectionist'))
    " Loop through projections with 'skeleton' key and try each one until the
    " snippet expands
    for [root, value] in projectionist#query('skeleton')
      " try varian if provided
      if !empty(a:000) | let value .= '_' . template | endif
      if s:try_insert(value)
        return
      endif
    endfor
  endif

  call s:try_insert('skel')
endfunction

function! templates#trans(subject, ...) abort
  let result = a:subject
  for trans in a:000
    let result = g:projectionist_transformations[trans](result, '')
  endfor
  return result
endfunction

function! templates#tfile(...) abort
  let result =
  return call('templates#trans', [templates#file()] + a:000)
endfunction

function! templates#sfile(...) abort
  let exc_expr = get(a:, 1, '')
  let sub = get(a:, 2, '')
  let flags = get(a:, 3, '')
  let file = templates#file()
  if empty(exc_expr)
    return file
  endif
  return substitute(file, exc_expr, sub, flags)
endfunction

function! templates#stfile(subs, trans) abort
  let subs_args = a:subs
  if type(a:subs) == type("")
    let subs_args = [a:subs, '', '']
  endif

  let trans_args = a:trans
  if type(a:trans) == type("")
    let trans_args = split(a:trans, '|')
  endif

  let result = call('templates#sfile', subs_args)
  return call('templates#trans', [result] + trans_args)
endfunction

function! templates#file() abort
  let dir = projectionist#path()
  let file = expand('%:p:r')
  return substitute(file, dir . '/', '', '')
endfunction
