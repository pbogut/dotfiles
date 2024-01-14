---@type LazyPluginSpec
return {
  'theprimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { 'ŋ', '<plug>(harpoon-toggle-menu)', desc = 'Harpoon toggle menu' },
    { '„', '<plug>(harpoon-add-file)', desc = 'Harpoon add file' },
    { 'æ', '<plug>(harpoon-nav-1)', desc = 'Harpoon nave file 1' },
    { 'ð', '<plug>(harpoon-nav-2)', desc = 'Harpoon nave file 2' },
    { 'ś', '<plug>(harpoon-nav-3)', desc = 'Harpoon nave file 3' },
    { 'ą', '<plug>(harpoon-nav-4)', desc = 'Harpoon nave file 4' },
  },
  config = function()
    local k = vim.keymap
    ---@type Harpoon
    local harpoon = require('harpoon')

    ---@diagnostic disable-next-line: missing-parameter
    harpoon.setup()

    k.set('n', '<plug>(harpoon-toggle-menu)', function()
      harpoon.ui:toggle_quick_menu(harpoon:list(), {
        border = 'rounded',
        title_pos = 'center',
      })
    end)
    k.set('n', '<plug>(harpoon-add-file)', function()
      harpoon:list():append()
    end)
    k.set('n', '<plug>(harpoon-nav-1)', function()
      harpoon:list():select(1)
    end)
    k.set('n', '<plug>(harpoon-nav-2)', function()
      harpoon:list():select(2)
    end)
    k.set('n', '<plug>(harpoon-nav-3)', function()
      harpoon:list():select(3)
    end)
    k.set('n', '<plug>(harpoon-nav-4)', function()
      harpoon:list():select(4)
    end)

    local augroup = vim.api.nvim_create_augroup('x_harpoon', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
      group = augroup,
      pattern = 'harpoon',
      callback = function()
        vim.wo.number = false
      end,
    })
  end,
}
