local notify = require('notify')

notify.setup({
  timeout = 3000,
  stages = 'static'
})

vim.notify = notify
