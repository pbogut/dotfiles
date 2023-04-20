local dapui = require("dapui")
local k = vim.keymap

dapui.setup()
k.set('n', '<space>dk', dapui.eval)
