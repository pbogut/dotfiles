return {
  'MattesGroeger/vim-bookmarks',
  event = 'BufReadPre',
  keys = {
    { 'mm', '<cmd>BookmarToggle<cr>' },
    { 'mi', '<cmd>BookmarAnnotate<cr>' },
    { '<space>fM', '<plug>(bookmarks-list)' },
  },
  init = function()
    vim.g.bookmark_save_per_working_dir = 1
    vim.g.bookmark_sign = '📌'
    vim.g.bookmark_annotation_sign = '📔'
  end,
  config = function()
    local k = vim.keymap

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
    ]])

    k.set('n', '<plug>(bookmarks-list)', function()
      local finders = require('telescope.finders')
      local make_entry = require('telescope.make_entry')
      local pickers = require('telescope.pickers')
      local result = {}
      local files = vim.fn['bm#all_files']()
      local conf = require('telescope.config').values
      for _, file in ipairs(files) do
        local line_nrs = vim.fn['bm#all_lines'](file)
        for _, line_nr in ipairs(line_nrs) do
          local bookmark = vim.fn['bm#get_bookmark_by_line'](file, line_nr)
          local content = ''
          if bookmark.annotation:len() > 0 then
            content = 'Annotation: ' .. bookmark.annotation
          elseif bookmark.content:len() > 0 then
            content = bookmark.content
          else
            content = 'empty line'
          end
          result[#result + 1] = file .. ':' .. line_nr .. ':0:' .. content
        end
      end

      pickers
        .new({
          prompt_title = 'BookMarks',

          finder = finders.new_table({
            results = result,
            entry_maker = make_entry.gen_from_vimgrep({}),
          }),
          previewer = conf.grep_previewer({}),
          sorter = conf.generic_sorter({}),
        }, {})
        :find()
    end)
  end,
}
