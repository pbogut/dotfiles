local config = require('pbogut.config')

local fmt_file = os.getenv('HOME') .. '/.config/clang-format/openscad-format'
local opts = {
  cmd = { 'openscad-lsp', '--stdio', '--fmt-style', 'file:' .. fmt_file },
  settings = {
    openscad = {},
  },
}
config.apply_to(opts.settings, 'openscad', 'lsp.openscad_lsp')

return opts
