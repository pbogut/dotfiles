---@type LazyPluginSpec[]
return {
  {
    enabled = true,
    'CopilotC-Nvim/CopilotChat.nvim',
    branch = 'main',
    dependencies = {
      { 'zbirenbaum/copilot.lua' },
      { 'nvim-lua/plenary.nvim' }, -- for curl, log wrapper
    },
    build = 'make tiktoken', -- Only on MacOS or Linux
    opts = {
      -- See Configuration section for options
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
  {
    enabled = true,
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
  },
}
