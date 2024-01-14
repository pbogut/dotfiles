---@type LazyPluginSpec
return {
  'laytan/tailwind-sorter.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-lua/plenary.nvim' },
  build = 'cd formatter && npm i && npm run build',
  ft = { 'blade', 'html', 'php', 'eelixir', 'elixir', 'handlebars' },
  config = function()
    require('tailwind-sorter').setup({
      on_save_enabled = true,
      on_save_pattern = { '*.blade.php', '*.html', '*.phtml', '*.eex', '*.ex', '*.hbs' },
    })
  end,
}
