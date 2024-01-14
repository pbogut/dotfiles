-- disable builtin plugins
vim.g.loaded_python3_provider = true
vim.g.loaded_netrwPlugin = true

vim.loader.enable()
-- common helper
require('pbogut.helper')
-- config
prequire('pbogut.settings')
prequire('pbogut.autocmds')
prequire('pbogut.keys')
prequire('pbogut.commands')
prequire('pbogut.lazy')
