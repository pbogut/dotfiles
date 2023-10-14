local cfg = require('config')
local k = vim.keymap
local g = vim.g
local has_dap, dap = pcall(require, 'dap')

local strategy = function()
  if has_dap and dap.status() and dap.status():len() > 0 then
    vim.notify('DAP is running, test will be run in background', vim.log.levels.INFO, { title = 'vim-test' })
    if os.getenv('TMUX') then
      return 'tmuxctl_hidden'
    end

    return 'dispatch_background'
  else
    if os.getenv('TMUX') then
      return 'tmuxctl'
    end

    return 'neovim'
  end
end

local function init() end

local function config()
  vim.g['test#custom_strategies'] = {
    tmuxctl = function(cmd)
      require('tmuxctl').send_to_pane('vim_test', cmd, { open = true, focus = false })
    end,
    tmuxctl_hidden = function(cmd)
      require('tmuxctl').send_to_pane('vim_test', cmd, { open = false, focus = false })
    end,
  }
  vim.g['test#strategy'] = 'tmuxctl'

  local ag_x_test = vim.api.nvim_create_augroup('x_test', { clear = true })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = ag_x_test,
    pattern = '*.ex,*.exs',
    callback = function()
      g['test#filename_modifier'] = ':p'
    end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    group = ag_x_test,
    pattern = '*.rs',
    callback = function()
      g['test#filename_modifier'] = ':.'
    end,
  })

  vim.g['test#neovim#term_position'] = 'botright 20'
  vim.g['test#strategy'] = 'neovim'
  if cfg.get('test.phpunit.executable') then
    vim.g['test#php#phpunit#executable'] = cfg.get('test.phpunit.executable')
  end

  local function run(command)
    return function()
      vim.cmd(command .. ' -strategy=' .. strategy())
    end
  end

  k.set('n', '<plug>(test-nearest)', run('TestNearest'))
  k.set('n', '<plug>(test-file)', run('TestFile'))
  k.set('n', '<plug>(test-suite)', run('TestSuite'))
  k.set('n', '<plug>(test-last)', run('TestLast'))
  k.set('n', '<plug>(test-visit)', run('TestVisit'))
end

return {
  config = config,
  init = init,
}
