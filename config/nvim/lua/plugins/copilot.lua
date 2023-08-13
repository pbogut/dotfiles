local copilot = require('copilot')
copilot.setup({
  suggestion = {
    auto_trigger = true,
    keymap = {
      accept_line = '<C-e>',
      accept_word = '<C-l>',
      accept = '<C-f>',
    },
  },
  panel = { enabled = false },
})

local augroup = vim.api.nvim_create_augroup('x_copilot', {})
vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'gitcommit',
  callback = function()
    vim.cmd('Copilot! attach')
  end,
})
