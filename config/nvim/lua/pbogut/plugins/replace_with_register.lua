---@type LazyPluginSpec
return {
  'vim-scripts/ReplaceWithRegister',
  keys = {
    { 'cp', '<plug>ReplaceWithRegisterOperator', remap = true },
    { 'cp', '<Plug>ReplaceWithRegisterVisual', mode = 'x', remap = true },
    { 'cpp', '<Plug>ReplaceWithRegisterLine', remap = true },
    { 'cP', 'cp$', remap = true },
    { 'cp=', 'cpp==', remap = true },
  },
}
