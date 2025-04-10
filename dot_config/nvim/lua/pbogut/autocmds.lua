local u = require('pbogut.utils')
local bo = vim.bo
local wo = vim.wo
local cmd = vim.cmd

local augroup = vim.api.nvim_create_augroup('x_autogroups', { clear = true })
vim.api.nvim_create_autocmd('TermOpen', {
  group = augroup,
  callback = function()
    wo.number = false
    wo.relativenumber = false
    wo.signcolumn = 'no'
    wo.cursorline = false
    wo.cursorcolumn = false
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'html,css,scss,xml,java,elixir,eelixir,c,php,php.phtml,sql,blade,elm',
  callback = function()
    u.set_indent(4)
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'sh,vue,javascript,vim,lua,yaml,yaml.docker-compose,ruby',
  callback = function()
    u.set_indent(2)
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'make',
  callback = function()
    u.set_indent(4, true)
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'go',
  callback = function()
    u.set_indent(2, true)
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'gdscript',
  callback = function()
    u.set_indent(4, true)
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'javascript',
  callback = function()
    bo.iskeyword = '@,48-57,_,192-255' -- remove $ from keyword list, whiy tist there in js anyway?
  end,
})
vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup,
  pattern = '*',
  callback = function()
    require('vim.hl').on_yank({ timeout = 50, higroup = 'Search' })
  end,
})
vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  group = augroup,
  callback = function()
    local buf = vim.fn.expand('%')
    if buf ~= '' and vim.fn.isdirectory(buf) == 1 then
      if vim.fn.exists(':Dirvish') == 2 then
        cmd('Dirvish')
      elseif vim.fn.exists(':Oil') == 2 then
        cmd('Oil')
      end
    end

    local pid, WINCH = vim.fn.getpid(), vim.loop.constants.SIGWINCH
    vim.defer_fn(function()
      vim.loop.kill(pid, WINCH)
    end, 20)
  end,
})
vim.api.nvim_create_autocmd('InsertEnter', {
  group = augroup,
  callback = function()
    vim.wo.wrap = vim.wo.wrap
  end,
})
vim.api.nvim_create_autocmd('InsertLeave', {
  group = augroup,
  callback = function()
    vim.wo.wrap = vim.wo.wrap
  end,
})
