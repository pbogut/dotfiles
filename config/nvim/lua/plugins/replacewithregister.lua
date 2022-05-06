local k = vim.keymap

k.set('n', 'cp', '<Plug>ReplaceWithRegisterOperator', { remap = true })
k.set('n', 'cP', 'cp$', { remap = true })
k.set('n', 'cp=', 'cpp==', { remap = true })
k.set('n', 'cpp', '<Plug>ReplaceWithRegisterLine', { remap = true })
k.set('x', 'cp', '<Plug>ReplaceWithRegisterVisual', { remap = true })
