---@type LazyPluginSpec
return {
  'mattn/emmet-vim',
  keys = {
    { '<c-y>,', '<plug>(emmet-expand-abbr)', mode = { 'n', 'v', 'i' } },
  },
}
