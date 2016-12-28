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

  if type(a:1) == type("")
    let trans_args = split(a:1, '|')
  endif

  if type(a:1) == type([])
    let trans_args = a:1
  endif

  if len(a:000) > 1
    let trans_args = a:000
  endif

  for trans in trans_args
    let result = g:projectionist_transformations[trans](result, '')
  endfor

  return result
endfunction

function! templates#subs(subject, ...) abort
  let subs_args = a:000

  if type(a:1) == type([])
    let subs_args = a:1
  endif

let g:subject = a:subject
let g:a1 = a:1
let g:subs_args = subs_args

  let exc_expr = get(subs_args, 0, '')
  let sub = get(subs_args, 1, '')
  let flags = get(subs_args, 2, '')

  return substitute(a:subject, exc_expr, sub, flags)
endfunction

function! templates#tfile(trans) abort
  return templates#trans(templates#file(), a:trans)
endfunction

function! templates#sfile(...) abort
  return templates#subs(templates#file(), a:000)
endfunction

function! templates#tsfile(trans, subs) abort
  let result = templates#trans(templates#file(), a:trans)
  return templates#subs(result, a:subs)
endfunction

function! templates#stfile(subs, trans) abort
  let result = templates#subs(templates#file(), a:subs)
  return templates#trans(result, a:trans)
endfunction

function! templates#file() abort
  let dir = projectionist#path()
  let file = expand('%:p:r')
  return substitute(file, dir . '/', '', '')
endfunction
