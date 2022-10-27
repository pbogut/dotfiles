local notify = require('notify')

notify.setup({
  timeout = 3000,
  stages = 'static',
  top_down = false,
})

vim.notify = notify
