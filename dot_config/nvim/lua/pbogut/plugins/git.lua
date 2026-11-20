---@type LazyPluginSpec[]
return {
  {
    enabled = true,
    'rhysd/git-messenger.vim',
    keys = {
      { '<space>gm', '<plug>(git-messenger)', desc = 'Show git message' },
    },
  },
  {
    enabled = true,
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
      { '<space>hi', '<plug>(gitsigns-hunk-inline)' },
      { '<space>hr', '<plug>(gitsigns-refresh)' },
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
      k.set('n', '<plug>(gitsigns-hunk-inline)', '<cmd>Gitsigns preview_hunk_inline<cr>')
      k.set('n', '<plug>(gitsigns-refresh)', '<cmd>Gitsigns refresh<cr>')
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
  {
    'janbuchar/difftsigns.nvim',
    dependencies = { 'lewis6991/gitsigns.nvim' },
    event = 'BufReadPre',
    opts = {
      difft_versions = { '0.70.0', '0.71.0', '0.72.0' },
    },
    keys = {
      { '<space>hd', '<cmd>DifftSigns preview<cr>', desc = 'Preview hunk with formatting changes dimmed' },
    },
    config = function(_, opts)
      require('difftsigns').setup(opts)
      local group = vim.api.nvim_create_augroup('DifftSignsConfig', { clear = true })
      local function set_noise_color()
        vim.api.nvim_set_hl(0, 'DifftSignsNoise', { fg = '#808080', ctermfg = 244 })
      end
      set_noise_color()
      vim.api.nvim_create_autocmd('ColorScheme', { group = group, callback = set_noise_color })
      -- Editing an argument inside an existing hunk may not fire GitSignsUpdate.
      vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'TextChangedP' }, {
        group = group,
        callback = function(ev)
          require('difftsigns.attach').schedule(ev.buf)
        end,
      })
    end,
  },
}
