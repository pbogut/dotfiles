if vim.b.resized then
  return
end

local cols = vim.o.columns
local size = cols / 2
size = math.min(size, 80)
vim.cmd('silent! wincmd H')
vim.api.nvim_win_set_width(0, size)
vim.b.resized = true

local bufnr = vim.fn.bufnr()
vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('x_fugitive_autogroups_' .. bufnr, { clear = true }),
  buffer = bufnr,
  callback = function()
    if vim.b.resized then
      cols = vim.o.columns
      size = cols / 2
      size = math.min(size, 80)
      vim.cmd('silent! wincmd H')
      vim.api.nvim_win_set_width(0, size)
    end
  end,
})
