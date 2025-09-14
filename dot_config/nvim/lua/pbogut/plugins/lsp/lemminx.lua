local config = require('pbogut.config')

local opts = {
  settings = {
    xml = {
      server = {
        workDir = os.getenv('HOME') .. '/.cache/lemminx',
      },
      catalogs = {
        '.lemminx.xml',
      },
    },
  },
}
config.apply_to(opts.settings, 'xml', 'lsp.lemminx')

return opts
