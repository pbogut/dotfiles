local function local_dir(name)
  return vim.fn.stdpath('config') .. '/local/' .. name
end

---@type LazyPluginSpec[]
return {
  {
    'paranoic-backup',
    dir = local_dir('paranoic-backup'),
    event = 'BufWritePre',
    config = function()
      require('paranoic-backup')
    end,
  },
  {
    'actions',
    dir = local_dir('actions'),
    config = function()
      local actions = require('actions')
      vim.keymap.set('n', '<space>ra', function()
        vim.cmd('Lazy load telescope.nvim')
        actions.pick_action()
      end)
    end,
  },
  {
    'chezmoi',
    dir = local_dir('chezmoi'),
    keys = {
      { '<space>fc', '<plug>(ts-chezmoi-files)', desc = 'Open chezmoi file' },
    },
    event = 'BufEnter',
    config = function()
      require('chezmoi')
    end,
  },
  {
    'remotesync',
    dir = local_dir('remotesync'),
    cmd = { 'RemoteSync', 'RemotePush' },
    config = function()
      require('remotesync')
    end,
  },
  {
    'markdown',
    dir = local_dir('markdown'),
    keys = {
      { '<space>fn', '<cmd>Notes<cr>', desc = 'List notes' }
    },
    config = function()
      require('markdown').setup()
    end,
    ft = 'markdown',
  },
  {
    'mdpdf',
    dir = local_dir('mdpdf'),
    config = function()
      require('mdpdf').setup()
    end,
    ft = 'markdown',
  },
  {
    'ripgrep',
    dir = local_dir('ripgrep'),
    keys = {
      { '<space>gg', '<plug>(ripgrep-search)', desc = 'ripgrep search' },
      { 'gr', '<plug>(ripgrep-op)', desc = 'ripgrep motion' },
    },
    config = function()
      require('ripgrep')
    end,
    -- dependencies = 'telescope.nvim',
  },
  {
    'echo_notify',
    dir = local_dir('echo_notify'),
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
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.notify = function(...) -- lazy load vim.notify when used
        vim.notify = require('echo_notify').notify
        vim.notify(...)
      end
    end,
    lazy = true,
  },
  {
    'openscad',
    dir = local_dir('openscad'),
    config = function()
      require('openscad').config()
    end,
    ft = 'openscad',
  },
  {
    'todoman',
    dir = local_dir('todoman'),
    config = function()
      require('todoman').setup({
        default_due = '23:55',
        default_calendar = 'quicklist',
      })
    end,
    cmd = 'Todo',
  },
}
