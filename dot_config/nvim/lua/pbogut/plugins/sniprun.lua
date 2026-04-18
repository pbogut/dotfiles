---@type LazyPluginSpec
return {
  enabled = true,
  'michaelb/sniprun',
  build = 'sh install.sh',
  keys = {
    { '<space>rr', '<cmd>SnipRunBlock<cr>' },
  },
  config = function()
    local api = require('sniprun.api')
    local command = vim.api.nvim_create_user_command
    command('SnipRunBlock', function(opt)
      local current = vim.fn.getline('.')

      if current:match('^```lua$') then
        vim.cmd.SnipRun()
        return
      end

      local current_pos = vim.fn.line('.')
      local start_pos = vim.fn.searchpos('^```lua$', 'bn')
      local end_pos = vim.fn.searchpos('^```$', 'n')
      if (start_pos[1] < end_pos[1] and start_pos[1] <= current_pos and end_pos[1] >= current_pos) then
        api.run_range(start_pos[1], end_pos[1])
      end
    end, { bang = true })
  end
}
