local k = vim.keymap

local function config()
  require('Comment').setup({
    ignore = '^$',
    pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
  })

  local ft = require('Comment.ft')
  ft.asm = '//%s'
  ft.heex = { '<%# %s #%>', '<%# %s #%>' }
end

return {
  config = config,
}
