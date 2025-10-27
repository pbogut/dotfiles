return {
  diagnostics = {
    base = vim.c.base01,
    foreground = vim.c.base3,
    neutral = vim.c.blue,
    success = vim.c.green,
    hint = vim.c.yellow,
    warning = vim.c.orange,
    error = vim.c.red,
  },
  theme = {
    normal = {
      a = { fg = vim.c.base3, bg = c.blue, gui = 'bold' },
      b = { fg = vim.c.base3, bg = c.base01 },
      c = { fg = vim.c.base1, bg = c.base02 },
    },
    insert = { a = { fg = vim.c.base3, bg = c.green, gui = 'bold' } },
    visual = { a = { fg = vim.c.base3, bg = c.magenta, gui = 'bold' } },
    replace = { a = { fg = vim.c.base3, bg = c.red, gui = 'bold' } },
    inactive = {
      a = { fg = vim.c.base3, bg = c.base01, gui = 'none' },
      b = { fg = vim.c.base3, bg = c.base01 },
      c = { fg = vim.c.base1, bg = c.base02 },
    },
  },
}

