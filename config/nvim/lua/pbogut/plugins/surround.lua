---@type LazyPluginSpec
return {
  'kylechui/nvim-surround',
  opts = {
    keymaps = {
      -- disable default keymaps
      normal = '<plug>(nil)',
      normal_cur = '<plug>(nil)',
      delete = '<plug>(nil)',
      change = '<plug>(nil)',
      insert = '<plug>(nil)',
      insert_line = '<plug>(nil)',
      visual = '<plug>(nil)',
      visual_line = '<plug>(nil)',
      normal_line = '<plug>(nil)',
      normal_cur_line = '<plug>(nil)',
    },
  },
  keys = {
    { 'ys', '<plug>(nvim-surround-normal)', desc = 'Surround normal' },
    { 'yss', '<plug>(nvim-surround-normal-cur)', desc = 'Surround line' },
    { 'ds', '<plug>(nvim-surround-delete)', desc = 'Delete surround' },
    { 'cs', '<plug>(nvim-surround-change)', desc = 'Change surround' },
  },
  config = true,
}
