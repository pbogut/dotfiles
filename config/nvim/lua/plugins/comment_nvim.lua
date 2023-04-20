local k = vim.keymap

local function config()
  k.set('n', '<c-_>', 'gcc<down>', { remap = true })
  k.set('n', '<c-/>', 'gcc<down>', { remap = true })
  k.set('v', '<c-_>', 'gc<down>', { remap = true })
  k.set('v', '<c-/>', 'gc<down>', { remap = true })

  require('Comment').setup({
    ignore = '^$',
    pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
  })
end

return {
  config = config,
}
