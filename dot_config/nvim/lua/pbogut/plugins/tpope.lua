---@type LazyPluginSpec[]
return {
  {
    enabled = true,
    'tpope/vim-abolish',
    keys = {
      { 'cr', '<plug>(abolish-coerce-word)', desc = 'Coerce word' },
    },
    cmd = { 'S', 'Abolish', 'Subvert' },
    init = function()
      vim.g.abolish_no_mappings = true
    end,
  },
  { 'tpope/vim-fugitive', cmd = { 'Git', 'Gclog', 'Gllog' } },
  { 'tpope/vim-repeat' },
  {
    enabled = true,
    'tpope/vim-sleuth',
    init = function()
      vim.g.sleuth_no_filetype_indent_on = 1
    end,
  },
  { 'tpope/vim-rails', ft = { 'ruby' } },
}
