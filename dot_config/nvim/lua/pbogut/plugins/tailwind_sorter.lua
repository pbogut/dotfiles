---@type LazyPluginSpec
return {
  enabled = false,
  'laytan/tailwind-sorter.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-lua/plenary.nvim' },
  build = 'cd formatter && npm i && npm run build',
  ft = { 'blade', 'html', 'php', 'eelixir', 'elixir', 'handlebars', 'templ' },
  config = function()
    require('tailwind-sorter').setup({
      on_save_enabled = true,
      on_save_pattern = { '*.blade.php', '*.html', '*.phtml', '*.eex', '*.ex', '*.hbs', '*.templ' },
    })
  end,
}
