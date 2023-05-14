-- disable builtin plugins
vim.g.loaded_python3_provider = true
vim.g.loaded_netrwPlugin = true

vim.loader.enable()
-- common helper
require('helper')
-- config
prequire('settings')
prequire('autogroups')
prequire('keymappings')
prequire('commands')
prequire('lazy_init')
