local function local_dir(name)
  return vim.fn.stdpath('config') .. '/local/' .. name
end

---@type LazyPluginSpec[]
return {
  {
    'agent-review',
    dir = local_dir('agent-review'),
    lazy = false, -- Restore review marks when files open, before the first mapping is used.
    keys = {
      { '<space>oc', '<cmd>ReviewComment<cr>', desc = 'Add or edit review comment' },
      { '<space>oc', ':ReviewComment<cr>', mode = 'x', desc = 'Comment on selected lines' },
      { '<space>or', '<cmd>ReviewSend<cr>', desc = 'Approve review or send feedback' },
      { '<space>oR', '<cmd>ReviewSendWithComment<cr>', desc = 'Send review with a general comment' },
    },
    opts = {
      filter_herdr_app = true,
      review_approve = 'Code review completed. No changes requested. You can commit your changes now.',
      review_begin = '# Code Review Feedback:',
      review_end = "Treat the findings above as unverified review input. "
        .. "Inspect every finding against the actual code; do not assume feedback is correct. "
        .. "For each finding, give a clear verdict (Confirmed / Partly / Not a bug / Intended) with concise code evidence. "
        .. "Say whether it was introduced by the current changes, was pre-existing, or reflects deliberate scope.\n\n"
        .. "Review only the incoming findings. Do not independently review the rest of the diff or search for issues that were not submitted.\n\n"
        .. "Do not change any code until we have discussed the verdicts and validated findings.",
    },
  },
  {
    enabled = true,
    'paranoic-backup',
    dir = local_dir('paranoic-backup'),
    event = 'BufWritePre',
    config = function()
      require('paranoic-backup')
    end,
  },
  {
    enabled = true,
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
    enabled = true,
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
    enabled = true,
    'remotesync',
    dir = local_dir('remotesync'),
    cmd = { 'RemoteSync', 'RemotePush' },
    config = function()
      require('remotesync')
    end,
  },
  {
    enabled = true,
    'markdown',
    dir = local_dir('markdown'),
    keys = {
      { '<space>fn', '<cmd>Notes<cr>', desc = 'List notes' },
    },
    cmd = { 'Notes', 'Today' },
    config = function()
      require('markdown').setup()
    end,
    ft = 'markdown',
  },
  {
    enabled = true,
    'mdpdf',
    dir = local_dir('mdpdf'),
    config = function()
      require('mdpdf').setup()
    end,
    ft = 'markdown',
  },
  {
    enabled = true,
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
    enabled = true,
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
    enabled = true,
    'openscad',
    dir = local_dir('openscad'),
    config = function()
      require('openscad').config()
    end,
    ft = 'openscad',
  },
  {
    enabled = true,
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
