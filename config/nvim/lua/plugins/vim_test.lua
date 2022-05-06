local u = require('utils')
local k = vim.keymap
local g = vim.g

local function setup()
  k.set('n', '<space>tn', ':TestNearest<CR>')
  k.set('n', '<space>tf', ':TestFile<CR>')
  k.set('n', '<space>ts', ':TestSuite<CR>')
  k.set('n', '<space>tl', ':TestLast<CR>')
  k.set('n', '<space>tt', ':TestLast<CR>')
  k.set('n', '<space>tv', ':TestVisit<CR>')
end

local function config()
  u.augroup('x_test', {
    FileType = {
      {
        '*', function()
          g['test#filename_modifier'] = ''
        end
      },
      {
        'elixir', function()
          g['test#filename_modifier'] = ':p'
        end
      }
    }
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
