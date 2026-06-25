---@type LazyPluginSpec
return {
  enabled = true,
  'nickjvandyke/opencode.nvim',
  version = '*', -- Latest stable release
  keys = {
    { '<space>oa', '<plug>(opencode-ask)', desc = 'Ask OpenCode…', mode = { 'n', 'x' } },
    { '<space>os', '<plug>(opencode-select)', desc = 'Select OpenCode…', mode = { 'n', 'x' } },
    { 'go', '<plug>(opencode-append-range)', desc = 'Append range to OpenCode', expr = true, mode = { 'n', 'x' } },
    { 'goo', '<plug>(opencode-append-line)', desc = 'Append line to OpenCode', expr = true, mode = 'n' },
    { '<S-C-u>', '<plug>(opencode-scroll-up)', desc = 'Scroll OpenCode up', mode = 'n' },
    { '<S-C-d>', '<plug>(opencode-scroll-down)', desc = 'Scroll OpenCode down', mode = 'n' },
  },
  config = function()
    start = function()
      vim.cmd('belowright 15split')
      vim.cmd.enew()
      vim.fn.termopen('opencode-launcher --port')
      vim.cmd.wincmd('k')
    end
    if os.getenv('TMUX') then
      start = function()
        vim.fn.jobstart({ 'tmux-select-window-or-new', '9' }, {
          on_stdout = function(_) end,
          on_stderr = function(_) end,
          on_exit = function(_, code) end,
        })
      end
    end
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- Your configuration, if any; goto definition on the type or field for details
      server = {
        start = start,
      },
    }

    vim.o.autoread = true -- Required for `vim.g.opencode_opts.events.reload`

    vim.keymap.set({ 'n', 'x' }, '<plug>(opencode-ask)', function()
      require('opencode').ask('@this: ')
    end, { desc = 'Ask OpenCode…' })
    vim.keymap.set({ 'n', 'x' }, '<plug>(opencode-select)', function()
      require('opencode').select()
    end, { desc = 'Select OpenCode…' })
    vim.keymap.set({ 'n', 'x' }, '<plug>(opencode-append-range)', function()
      return require('opencode').operator('@this ')
    end, { desc = 'Append range to OpenCode', expr = true })
    vim.keymap.set('n', '<plug>(opencode-append-line)', function()
      return require('opencode').operator('@this ') .. '_'
    end, { desc = 'Append line to OpenCode', expr = true })
    vim.keymap.set('n', '<plug>(opencode-scroll-up)', function()
      require('opencode').command('session.half.page.up')
    end, { desc = 'Scroll OpenCode up' })
    vim.keymap.set('n', '<plug>(opencode-scroll-down)', function()
      require('opencode').command('session.half.page.down')
    end, { desc = 'Scroll OpenCode down' })
  end,
}
