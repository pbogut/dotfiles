local u = require('utils')
local g = vim.g

local c = {}

function c.setup()
  u.map('n', '<space>tn', ':TestNearest<CR>')
  u.map('n', '<space>tf', ':TestFile<CR>')
  u.map('n', '<space>ts', ':TestSuite<CR>')
  u.map('n', '<space>tl', ':TestLast<CR>')
  u.map('n', '<space>tt', ':TestLast<CR>')
  u.map('n', '<space>tv', ':TestVisit<CR>')
end

function c.config()
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
end

vim.g['test#strategy'] = {
  nearest = 'neovim',
  file = 'neovim',
  suite = 'neovim',
}
vim.g['test#elixir#exunit#options'] = '--trace'

return c
