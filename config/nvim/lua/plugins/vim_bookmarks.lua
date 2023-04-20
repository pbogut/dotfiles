vim.g.bookmark_save_per_working_dir = 1
vim.g.bookmark_sign = '📌'
vim.g.bookmark_annotation_sign = '📔'


vim.cmd([[
  function! BookmarkClearForMissingFiles()
    let files = bm#all_files()
    for file in files
      if !filereadable(file)
        let lines = bm#all_lines(file)
        for line_nr in lines
          " call s:bookmark_remove(file, line_nr)
          call bm#del_bookmark_at_line(file, line_nr)
        endfor
      endif
    endfor
    echo "Bookmarks for missing files removed"
  endfunction
  command! BookmarkClearForMissingFiles call BookmarkClearForMissingFiles()
]]);
