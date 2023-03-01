local copilot = require('copilot')
copilot.setup({
  suggestion = {
    auto_trigger = true,
    keymap = {
      accept_line = '<C-e>',
      accept_word = '<C-f>',
      accept = '<C-g>',
    },
  },
  panel = { enabled = false },
})
