local config = require('pbogut.config')

local opts = {
  filetypes = { 'sh', 'zsh' },
}
config.apply_to(opts.settings, 'bashls', 'lsp.bashls')

return opts
