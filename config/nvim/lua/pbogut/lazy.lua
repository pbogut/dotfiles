local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if vim.fn.empty(vim.fn.glob(lazypath)) > 0 then
  vim.api.nvim_command('!git clone https://github.com/folke/lazy.nvim ' .. lazypath)
end

vim.opt.runtimepath:prepend(lazypath)

_G.lazy_loaded = {}

vim.keymap.set('n', '<space>lazy', '<cmd>Lazy<cr>')

require('lazy').setup('pbogut.plugins', {
  lockfile = vim.fn.stdpath('config') .. '/lazy-lock.json',
  dev = {
    path = vim.fn.stdpath('config') .. '/local',
  },
  install = {
    colorscheme = { 'solarized' },
  },
})
