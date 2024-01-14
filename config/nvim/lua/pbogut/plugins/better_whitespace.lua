---@type LazyPluginSpec
return {
  'ntpeters/vim-better-whitespace',
  event = { 'InsertEnter', 'BufReadPre' },
  config = function()
    vim.g.strip_whitespace_on_save = 0

    local augroup = vim.api.nvim_create_augroup('x_whitespace', { clear = true })
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = augroup,
      pattern = '*',
      callback = function()
        if not vim.b.whitespace_trim_disabled then
          vim.cmd([[silent! StripWhitespace]])
        end
      end,
    })
    vim.api.nvim_create_autocmd('FileType', {
      group = augroup,
      pattern = 'markdown,diff,mail',
      callback = function()
        vim.b.whitespace_trim_disabled = true
      end,
    })
    vim.api.nvim_create_autocmd('TermOpen', {
      group = augroup,
      callback = function()
        vim.cmd.DisableWhitespace()
      end,
    })
    vim.api.nvim_create_autocmd('BufEnter', {
      group = augroup,
      pattern = '.i3blocks.conf',
      callback = function()
        vim.b.whitespace_trim_disabled = true
      end,
    })
  end,
}
