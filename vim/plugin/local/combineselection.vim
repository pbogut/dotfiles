function! local#combineselection#init()
endfunction

" modify selected text using combining diacritics
command! -range -nargs=0 Overline        call s:combine_selection(<line1>, <line2>, '0305')
command! -range -nargs=0 Underline       call s:combine_selection(<line1>, <line2>, '0332')
command! -range -nargs=0 DoubleUnderline call s:combine_selection(<line1>, <line2>, '0333')
command! -range -nargs=0 Strikethrough   call s:combine_selection(<line1>, <line2>, '0336')

function! s:combine_selection(line1, line2, cp)
  execute 'let char = "\u'.a:cp.'"'
  execute a:line1.','.a:line2.'s/\%V[^[:cntrl:]]/&'.char.'/ge'
endfunction
