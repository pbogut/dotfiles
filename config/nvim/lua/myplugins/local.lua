return {
  {
    'local/paranoic-backup',
    event = 'BufWritePre',
    config = function()
      require('paranoic-backup')
    end,
    dev = true,
  },
  {
    'local/actions',
    config = function()
      local actions = require('actions')
      vim.keymap.set('n', '<space>ra', function()
        vim.cmd('Lazy load telescope.nvim')
        actions.pick_action()
      end)
    end,
    dev = true,
  },
  {
    'local/remotesync',
    cmd = { 'RemoteSync', 'RemotePush' },
    config = function()
      require('remotesync')
    end,
    dev = true,
  },
  {
    'local/mdpdf',
    config = function()
      require('mdpdf').setup()
    end,
    ft = 'markdown',
    dev = true,
  },
  {
    'local/ripgrep',
    keys = {
      { '<space>gg', '<plug>(ripgrep-search)', desc = 'ripgrep search' },
      { 'gr', '<plug>(ripgrep-op)', desc = 'ripgrep motion' },
    },
    config = function()
      require('ripgrep')
    end,
    -- dependencies = 'telescope.nvim',
    dev = true,
  },
  {
    'local/echo_notify',
    opts = {
      suppress = {
        message = {
          '^nvim%-navic: Server .- does not support documentSymbols.$',
          '^warning: multiple different client offset_encodings detected for buffer, this is not supported yet$',
          '^%# Config Change Detected.*',
        },
      },
    },
    config = function(_, opts)
      require('echo_notify').setup(opts)
    end,
    dev = true,
  },
  {
    'local/openscad',
    config = function()
      require('openscad').config()
    end,
    ft = 'openscad',
    dev = true,
  },
  {
    'local/todoman',
    config = function()
      require('todoman').setup({
        default_due = '23:55',
        default_calendar = 'quicklist',
      })
    end,
    cmd = 'Todo',
    dev = true,
  },
}
