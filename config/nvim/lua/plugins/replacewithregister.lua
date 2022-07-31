local k = vim.keymap

k.set('n', 'cp', '<plug>ReplaceWithRegisterOperator', { remap = true })
k.set('n', 'cP', 'cp$', { remap = true })
k.set('n', 'cp=', 'cpp==', { remap = true })
k.set('n', 'cpp', '<plug>ReplaceWithRegisterLine', { remap = true })
k.set('x', 'cp', '<plug>ReplaceWithRegisterVisual', { remap = true })
