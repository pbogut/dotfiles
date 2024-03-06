---@type LazyPluginSpec
return {
  'pbogut/magento2-ls',
  branch = 'develop',
  ft = { 'xml', 'javascript' },
  build = 'cargo build --release',
  config = function()
    require('magento2_ls').setup()
  end,
  cond = function()
    return vim.fn.filereadable('bin/magento') == 1
  end,
}
