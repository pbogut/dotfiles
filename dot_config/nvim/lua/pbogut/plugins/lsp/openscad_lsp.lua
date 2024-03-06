local config = require('pbogut.config')
local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  local fmt_file = os.getenv('HOME') .. '/.config/clang-format/openscad-format'
  opts = vim.tbl_deep_extend('keep', opts, {
    cmd = { 'openscad-lsp', '--stdio', '--fmt-style', 'file:' .. fmt_file },
    settings = {
      openscad = {},
    },
  })
  config.apply_to(opts.settings, 'openscad', 'lsp.openscad_lsp')
  lspconfig.openscad_lsp.setup(opts)
end

return me
