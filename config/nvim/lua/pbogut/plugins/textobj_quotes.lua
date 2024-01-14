---@type LazyPluginSpec
return {
  'beloglazov/vim-textobj-quotes',
  dependencies = 'kana/vim-textobj-user',
  keys = {
    { 'aq', '<plug>(textobj-quote-a)', mode = 'o' },
    { 'iq', '<plug>(textobj-quote-i)', mode = 'o' },
  },
}
