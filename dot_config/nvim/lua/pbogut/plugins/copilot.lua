return {
  'zbirenbaum/copilot.lua',
  event = 'InsertEnter',
  cmd = { 'Copilot' },
  config = function()
    local copilot = require('copilot')
    copilot.setup({
      suggestion = { enabled = false },
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
  end,
}
