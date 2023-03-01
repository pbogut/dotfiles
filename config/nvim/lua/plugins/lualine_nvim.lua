local lualine = require('lualine')
local c = vim.g.colors

-- custom sections
local s = {
  dapinfo = require('plugins.lualine.dapinfo'),
  harpoon = require('plugins.lualine.harpoon'),
  filename = require('plugins.lualine.filename'),
  gps = require('plugins.lualine.gps'),
  dadbod = require('plugins.lualine.dadbod'),
  fileinfo = require('plugins.lualine.fileinfo'),
  location = require('plugins.lualine.location'),
  diagnostics = require('plugins.lualine.diagnostics'),
  actions = require('plugins.lualine.actions'),
  mode_fmt = require('plugins.lualine.mode_fmt'),
  diff_change = require('plugins.lualine.diff').change,
  diff_mode = require('plugins.lualine.diff').mode_green,
  diff_mode_inactive = require('plugins.lualine.diff').mode,
}

local config = function()
  lualine.setup({
    options = {
      icons_enabled = true,
      theme = {
        normal = {
          a = { fg = c.base3, bg = c.blue, gui = 'bold' },
          b = { fg = c.base3, bg = c.base01 },
          c = { fg = c.base1, bg = c.base02 },
        },
        insert = { a = { fg = c.base3, bg = c.green, gui = 'bold' } },
        visual = { a = { fg = c.base3, bg = c.magenta, gui = 'bold' } },
        replace = { a = { fg = c.base3, bg = c.red, gui = 'bold' } },
        inactive = {
          a = { Fg = c.base3, bg = c.blue, gui = 'bold' },
          b = { fg = c.base3, bg = c.base01 },
          c = { fg = c.base1, bg = c.base02 },
        },
      },
      component_separators = { left = '', right = '' },
      section_separators = { left = '', right = '' },
      disabled_filetypes = {},
      always_divide_middle = true,
      globalstatus = true,
    },
    sections = {
      lualine_a = { { 'mode', fmt = s.mode_fmt } },
      lualine_b = { { s.diff_change, padding = 0 }, 'branch' },
      lualine_c = { s.dapinfo, s.harpoon, s.filename },
      lualine_x = {},
      lualine_y = { s.fileinfo, s.location },
      lualine_z = { s.actions, s.diagnostics },
    },
    winbar = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { s.gps },
      lualine_x = { s.dadbod },
      lualine_y = { s.diff_mode },
      lualine_z = { s.filename },
    },
    inactive_winbar = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {},
      lualine_x = { s.dadbod },
      lualine_y = { s.diff_mode_inactive, s.filename },
      lualine_z = {},
    },
    tabline = {
      lualine_a = { { 'tabs', mode = 2, max_length = vim.o.columns } },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = {},
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { 'filename' },
      lualine_x = { 'location' },
      lualine_y = {},
      lualine_z = {},
    },
    extensions = {},
  })
  -- override lualine setup, just show tabs when more than one is open
  vim.o.showtabline = 1
end

return { config = config }
