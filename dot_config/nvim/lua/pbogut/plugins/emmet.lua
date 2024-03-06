---@type LazyPluginSpec
return {
  'mattn/emmet-vim',
  keys = {
    { '<c-e>,', '<plug>(emmet-expand-abbr)', mode = { 'n', 'v', 'i' } },
  },
  init = function()
    vim.g.user_emmet_leader_key = '<c-e>'
  end,
}
