local cfg = require('config')
local k = vim.keymap
local g = vim.g
local has_dap, dap = pcall(require, 'dap')

local function setup()
  local strategy = function()
    if has_dap and dap.status() and dap.status():len() > 0 then
      vim.notify('DAP is running, test will be run in background', 'info')
      return 'dispatch_background'
    else
      return 'neovim'
    end
  end

  local function run(command)
    return function()
      vim.cmd(command .. ' -strategy=' .. strategy())
    end
  end

  k.set('n', '<space>tn', run('TestNearest'))
  k.set('n', '<space>tf', run('TestFile'))
  k.set('n', '<space>ts', run('TestSuite'))
  k.set('n', '<space>tl', run('TestLast'))
  k.set('n', '<space>tt', run('TestLast'))
  k.set('n', '<space>tv', run('TestVisit'))
end

local function config()
  local ag_x_test = vim.api.nvim_create_augroup('x_test', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = ag_x_test,
    pattern = '*',
    callback = function()
      g['test#filename_modifier'] = ''
    end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    group = ag_x_test,
    pattern = 'elixir',
    callback = function()
      g['test#filename_modifier'] = ':p'
    end,
  })

  vim.g['test#neovim#term_position'] = 'botright 20'
  vim.g['test#strategy'] = 'neovim'
  if cfg.get('test.phpunit.executable') then
    vim.g['test#php#phpunit#executable'] = cfg.get('test.phpunit.executable')
  end
end

return {
  config = config,
  setup = setup,
}
