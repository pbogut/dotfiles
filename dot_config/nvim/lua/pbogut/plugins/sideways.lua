---@type LazyPluginSpec
return {
  'AndrewRadev/sideways.vim',
  keys = {
    { 'ga<', '<cmd>SidewaysLeft<cr>' },
    { 'ga>', '<cmd>SidewaysRight<cr>' },
    { 'aa', '<plug>SidewaysArgumentTextobjA', mode = { 'o', 'x' }, remap = true },
    { 'ia', '<plug>SidewaysArgumentTextobjI', mode = { 'o', 'x' }, remap = true },
  },
}
