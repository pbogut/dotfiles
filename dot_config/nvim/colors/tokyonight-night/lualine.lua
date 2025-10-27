return {
  diagnostics = {
    base = vim.c.base01,
    foreground = vim.c.base03,
    neutral = vim.c.blue,
    success = vim.c.green,
    hint = vim.c.yellow,
    warning = vim.c.base00,
    error = vim.c.red,
  },
  theme = {
    normal = {
      a = { fg = vim.c.base03, bg = vim.c.blue, gui = 'bold' },
      b = { fg = vim.c.base3, bg = vim.c.base01 },
      c = { fg = vim.c.base2, bg = vim.c.base02 },
    },
    insert = { a = { fg = vim.c.base03, bg = vim.c.green, gui = 'bold' } },
    visual = { a = { fg = vim.c.base03, bg = vim.c.magenta, gui = 'bold' } },
    replace = { a = { fg = vim.c.base03, bg = vim.c.red, gui = 'bold' } },
    inactive = {
      a = { fg = vim.c.base3, bg = vim.c.base01, gui = 'none' },
      b = { fg = vim.c.base3, bg = vim.c.base01 },
      c = { fg = vim.c.base0, bg = vim.c.base02 },
    },
  },
}
