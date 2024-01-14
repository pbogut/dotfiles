---@type LazyPluginSpec[]
return {
  {
    'rhysd/git-messenger.vim',
    keys = {
      { '<space>gm', '<plug>(git-messenger)', desc = 'Show git message' },
    },
  },
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      trouble = true,
      preview_config = {
        border = 'none',
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1,
      },
    },
    keys = {
      { '<space>hh', '<plug>(gitsigns-toggle-linehl)' },
      { '<space>hr', '<plug>(gitsigns-refresh)' },
      { '<space>hd', '<plug>(gitsigns-preview-hunk)' },
      { '<space>hR', '<plug>(gitsigns-reset-hunk)' },
      { '<space>hs', '<plug>(gitsigns-stage-hunk)' },
      { '<space>hu', '<plug>(gitsigns-undo-stage-hunk)' },
      { '<space>gd', '<plug>(gitsigns-diffthis)' },
      { '<space>hb', '<plug>(gitsigns-blame-line)' },
      { ']h', '<plug>(gitsigns-next-hunk)' },
      { '[h', '<plug>(gitsigns-prev-hunk)' },
    },
    event = 'BufReadPre',
    config = function(_, opts)
      local k = vim.keymap
      k.set('n', '<plug>(gitsigns-toggle-linehl)', '<cmd>Gitsigns toggle_linehl<cr>')
      k.set('n', '<plug>(gitsigns-refresh)', '<cmd>Gitsigns refresh<cr>')
      k.set('n', '<plug>(gitsigns-preview-hunk)', '<cmd>Gitsigns preview_hunk<cr>')
      k.set('n', '<plug>(gitsigns-reset-hunk)', '<cmd>Gitsigns reset_hunk<cr>')
      k.set('n', '<plug>(gitsigns-stage-hunk)', '<cmd>Gitsigns stage_hunk<cr>')
      k.set('n', '<plug>(gitsigns-undo-stage-hunk)', '<cmd>Gitsigns undo_stage_hunk<cr>')
      k.set('n', '<plug>(gitsigns-diffthis)', '<cmd>Gitsigns diffthis<cr>')
      k.set('n', '<plug>(gitsigns-blame-line)', '<cmd>Gitsigns blame_line<cr>')
      k.set('n', '<plug>(gitsigns-next-hunk)', '<cmd>Gitsigns next_hunk<cr>')
      k.set('n', '<plug>(gitsigns-prev-hunk)', '<cmd>Gitsigns prev_hunk<cr>')
      require('gitsigns').setup(opts)
    end,
  },
}
