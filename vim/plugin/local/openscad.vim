function! local#openscad#init()
  autocmd FileType openscad call local#openscad#register_commands()
endfunction


function! local#openscad#register_commands()
  command! OpenScad silent! !openscad % > /dev/null 2>&1 &
  command! -bang -nargs=? -complete=file ExportStl call s:export_stl(expand('%'), <q-args>, <bang>0)
  command! -bang -nargs=? -complete=file SliceStl call s:slice_stl(expand('%'), <q-args>, <bang>0)
endfunction

function! s:get_dst_file(src_file, dst_file)
  if !empty(a:dst_file)
    let dst_file = a:dst_file
    if a:dst_file !~? '\.stl$'
      let dst_file .= '.stl'
    endif
  else
    let dst_file = substitute(a:src_file, '\.[^\.]*$', '.stl', '')
    if dst_file == a:src_file
      echom 'Something is wrong...'
      return
    endif
  endif

  return l:dst_file
endfunction

function! s:export_stl(src_file, dst_file, verbose)
  let dst_file = s:get_dst_file(a:src_file, a:dst_file)
  echon('Exporting stl... ')
  let cmd = '!openscad ' . fnameescape(a:src_file) . ' -o ' . fnameescape(l:dst_file)
  if (a:verbose)
    exec(l:cmd)
  else
    silent exec(l:cmd)
  endif
  echon('File exported: ' . l:dst_file)
endfunction


function! s:slice_stl(src_file, dst_file, verbose)
  if !empty(a:dst_file)
    let dst_file = a:dst_file
  else
    let dst_file = $TMPDIR . "/" . substitute(a:src_file, '.*/\(.*\)$', '\1', '') . '.stl'
  endif
  call s:export_stl(a:src_file, l:dst_file, a:verbose)
  let cmd = '!i3-open ' . fnameescape(l:dst_file)
  if (a:verbose)
    exec(l:cmd)
  else
    silent exec(l:cmd)
  endif
endfunction
