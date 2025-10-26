local c = require('pbogut.settings.themes.tokyonight-night.colors')
return {
  diagnostics = {
    base = c.base01,
    foreground = c.base03,
    neutral = c.blue,
    success = c.green,
    hint = c.yellow,
    warning = c.base00,
    error = c.red,
  },
  theme = {
    normal = {
      a = { fg = c.base03, bg = c.blue, gui = 'bold' },
      b = { fg = c.base3, bg = c.base01 },
      c = { fg = c.base2, bg = c.base02 },
    },
    insert = { a = { fg = c.base03, bg = c.green, gui = 'bold' } },
    visual = { a = { fg = c.base03, bg = c.magenta, gui = 'bold' } },
    replace = { a = { fg = c.base03, bg = c.red, gui = 'bold' } },
    inactive = {
      a = { fg = c.base3, bg = c.base01, gui = 'none' },
      b = { fg = c.base3, bg = c.base01 },
      c = { fg = c.base0, bg = c.base02 },
    },
  },
}
