" denite
if !has('nvim')
  finish
end

call denite#custom#map('insert', '<M-j>', '<denite:assign_next_matched_text>')
call denite#custom#map('insert', '<M-k>', '<denite:assign_previous_matched_text>')
call denite#custom#map('insert', '<C-n>', '<denite:move_to_next_line>')
call denite#custom#map('insert', '<C-p>', '<denite:move_to_previous_line>')

call denite#custom#alias('source', 'file_rec/git', 'file_rec')
call denite#custom#var('file_rec/git', 'command',
      \ ['git', 'ls-files', '-co', '--exclude-standard'])
call denite#custom#alias('source', 'file_rec/ag', 'file_rec')
call denite#custom#var('file_rec/ag', 'command',
      \ ['ag', '-g', ''])
