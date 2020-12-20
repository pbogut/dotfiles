augroup per_project_type
  autocmd User ProjectionistActivate call s:per_project_type_execute()
augroup END

let s:per_project_type = {}

function! s:per_project_type_execute()
  for [_root, value] in projectionist#query('project')
    if (!empty(s:per_project_type[value]))
          execute(s:per_project_type[value])
    endif
  endfor
endfunction

function! s:project_type(ptype, ...)
      let s:per_project_type[a:ptype] = join(a:000)
endfunction

command! -nargs=* ProjectType call s:project_type(<f-args>)
