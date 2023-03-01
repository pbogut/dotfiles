require('nvim-surround').setup({
  keymaps = {
    insert = '<plug>(nil)', -- disable this shit
    insert_line = '<plug>(nil)', -- disable this shit
    normal = 'ys',
    normal_cur = 'yss',
    normal_line = 'yS',
    normal_cur_line = 'ySS',
    visual = 'S',
    visual_line = 'gS',
    delete = 'ds',
    change = 'cs',
  },
})
