return {
  {
    'pbogut/fzf-mru.vim',
    keys = {
      { '<space>fm', '<cmd>FZFMruTelescope<cr>', desc = 'MRU files' },
    },
    event = { 'BufReadPre' },
    config = function()
      vim.api.nvim_create_user_command('FZFMruTelescope', function(_)
        vim.fn['fzf_mru#mrufiles#refresh']()
        vim.cmd.Telescope('fzf_mru', 'current_path')
      end, { nargs = 0 })
    end,
    init = function()
      vim.g.fzf_mru_relative = 1
      vim.g.fzf_mru_exclude_current_file = 1
      vim.g.fzf_mru_no_sort = 1
    end,
  },
}
