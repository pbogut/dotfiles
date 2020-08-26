" templates

" {{{ - copied from projectionist to support its pattern matching
function! s:match(file, pattern) abort
  if a:pattern =~# '^r\!'
    " treat like regexp
    if a:file =~# substitute(a:pattern, '^r\!', '', '')
      return 'we have a match, and api of this functions suck balls'
    else
      return ''
    end
  end
  " not a regexp, lets try original

  if a:pattern =~# '^[^*{}]*\*[^*{}]*$'
    let pattern = s:slash(substitute(a:pattern, '\*', '**/*', ''))
  elseif a:pattern =~# '^[^*{}]*\*\*[^*{}]\+\*[^*{}]*$'
    let pattern = s:slash(a:pattern)
  else
    return ''
  endif
  let [prefix, infix, suffix] = split(pattern, '\*\*\=', 1)
  let file = s:slash(a:file)
  if !s:startswith(file, prefix) || !s:endswith(file, suffix)
    return ''
  endif
  let match = file[strlen(prefix) : -strlen(suffix)-1]
  if infix ==# '/'
    return match
  endif
  let clean = substitute('/'.match, '\V'.infix.'\ze\[^/]\*\$', '/', '')[1:-1]
  return clean ==# match ? '' : clean
endfunction

function! s:slash(str) abort
  return tr(a:str, projectionist#slash(), '/')
endfunction

function! s:startswith(str, prefix) abort
  return strpart(a:str, 0, len(a:prefix)) ==# a:prefix
endfunction

function! s:endswith(str, suffix) abort
  return strpart(a:str, len(a:str) - len(a:suffix)) ==# a:suffix
endfunction
" }}} - copied from projectionist to support its pattern matching
"
function! s:try_insert(skel)
  execute "normal! i_t_" . a:skel . "\<C-r>=UltiSnips#ExpandSnippet()\<CR>"

  if g:ulti_expand_res == 0
    silent! undo
  endif

  return g:ulti_expand_res
endfunction

" let s:priority = 0
function! s:add_with_priority(list, element)
  if empty(get(a:element, "priority"))
    let s:priority += 1
    let a:element.priority = s:priority
  endif

  call add(a:list, a:element)
endfunction

function! s:sort_by_priority(el1, el2)
  if (a:el1.priority == a:el2.priority)
    return 0
  endif

  if (a:el1.priority > a:el2.priority)
    return 1
  else
    return -1
  endif
endfunction

function! templates#InsertSkeleton(...) abort
  let filetype = get(a:, 1)
  if !empty(filetype)
    exec('set ft=' . l:filetype)
  endif

  let template = get(a:, 2)
  let filename = expand('%')

  " Abort on non-empty buffer or extant file
  if !(line('$') == 1 && getline('$') == '')
    echom "You can use skeleton only in empty file."
    return
  endif

  " try selected template
  if !empty(l:template) && s:try_insert(l:template)
    return
  endif

  if !empty(get(b:,'projectionist'))
    let template_candidates = []
    let s:priority = -1000

    " Loop through projections with 'skeleton' key and remember
    " each one candidate
    for root in keys(b:projectionist)
      for config in b:projectionist[root]
        for pattern in keys(config)
          if has_key(config[pattern], 'skeleton')
            if !empty(s:match(l:filename, l:pattern))
              call s:add_with_priority(l:template_candidates, config[l:pattern])
            endif
          endif
        endfor
      endfor
    endfor
    " now loop through sorted candidates and pick first that expands
    for element in sort(l:template_candidates, 's:sort_by_priority')
      let value = l:element.skeleton
      if !empty(a:000) | let value .= '_' . template | endif
      if s:try_insert(value)
        return
      endif
    endfor
  endif

  if s:try_insert(expand('%:t:r') . '_skel')
    return
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
