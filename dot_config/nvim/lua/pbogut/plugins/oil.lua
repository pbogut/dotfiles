local yank_file_name = function(mode)
  return function()
    local fullpath = vim.fn.expand('%:p'):gsub('%/$', '')
    fullpath = fullpath:gsub('^oil%:%/%/', '')
    local cwd = vim.fn.getcwd()
    local path = fullpath
    if mode == 'basename' then
      path = fullpath:gsub('.*%/', '')
    end
    if mode == 'relative' and fullpath:sub(1, #cwd) == cwd then
      path = fullpath:sub(#cwd + 2)
    end
    vim.fn.setreg('+', path)
    print('Yanked: ' .. path)
  end
end

---@type LazyPluginSpec[]
return {
  {
    'stevearc/oil.nvim',
    keys = {
      { '<bs>', '<cmd>Oil<cr>', desc = 'Oil' },
      { 'yrf', yank_file_name('absolute') },
      { 'yif', yank_file_name('basename') },
      { 'yaf', yank_file_name('relative') },
    },
    opts = {
      win_options = {
        signcolumn = 'yes:2',
      },
      view_options = {
        show_hidden = true,
      },
    },
    config = true,
  },
  {
    'refractalize/oil-git-status.nvim',
    dependencies = { 'stevearc/oil.nvim' },
    config = true,
  },
}
