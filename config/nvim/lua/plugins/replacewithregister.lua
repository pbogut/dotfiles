local u = require('utils')

u.map('n', 'cp', '<Plug>ReplaceWithRegisterOperator', {noremap = false})
u.map('n', 'cP', 'cp$', {noremap = false})
u.map('n', 'cp=', 'cpp==', {noremap = false})
u.map('n', 'cpp', '<Plug>ReplaceWithRegisterLine', {noremap = false})
u.map('x', 'cp', '<Plug>ReplaceWithRegisterVisual', {noremap = false})
