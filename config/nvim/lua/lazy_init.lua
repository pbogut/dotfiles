local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if vim.fn.empty(vim.fn.glob(lazypath)) > 0 then
  vim.api.nvim_command('!git clone https://github.com/folke/lazy.nvim ' .. lazypath)
end

-- vim.cmd.packadd('lazy.nvim')
vim.opt.runtimepath:prepend(lazypath)

require('lazy').setup('myplugins', {
  dev = {
    path = vim.fn.stdpath('config') .. '/local',
  },
  install = {
    colorscheme = { 'solarized' },
  },
})

vim.opt.runtimepath:prepend(os.getenv('HOME') .. '/.vim')
vim.cmd.source(os.getenv('HOME') .. '/.vim/plugin/local.vim')
