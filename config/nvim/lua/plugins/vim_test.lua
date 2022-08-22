local k = vim.keymap
local g = vim.g

local function setup()
  k.set('n', '<space>tn', '<cmd>TestNearest<cr>')
  k.set('n', '<space>tf', '<cmd>TestFile<cr>')
  k.set('n', '<space>ts', '<cmd>TestSuite<cr>')
  k.set('n', '<space>tl', '<cmd>TestLast<cr>')
  k.set('n', '<space>tt', '<cmd>TestLast<cr>')
  k.set('n', '<space>tv', '<cmd>TestVisit<cr>')
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

  vim.g['test#strategy'] = {
    nearest = 'neovim',
    file = 'neovim',
    suite = 'neovim',
  }
  vim.g['test#elixir#exunit#options'] = '--trace'
end

return {
  config = config,
  setup = setup,
}
