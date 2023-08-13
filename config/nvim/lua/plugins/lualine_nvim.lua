local lualine = require('lualine')
local c = vim.g.colors

---@type string|nil
local starship_cache = ''
-- custom sections
local s = {
  navic = require('plugins.lualine.navic'),
  dapinfo = require('plugins.lualine.dapinfo'),
  harpoon = require('plugins.lualine.harpoon'),
  filename = require('plugins.lualine.filename'),
  dadbod = require('plugins.lualine.dadbod'),
  fileinfo = require('plugins.lualine.fileinfo'),
  location = require('plugins.lualine.location'),
  diagnostics = require('plugins.lualine.diagnostics'),
  actions = require('plugins.lualine.actions'),
  mode_fmt = require('plugins.lualine.mode_fmt'),
  diff_change = require('plugins.lualine.diff').change,
  diff_mode = require('plugins.lualine.diff').mode_green,
  diff_mode_inactive = require('plugins.lualine.diff').mode,
  fugitive = require('plugins.lualine.fugitive').filename_green,
  fugitive_inactive = require('plugins.lualine.fugitive').filename,
  starship = function()
    if starship_cache ~= nil then
      return starship_cache
    end
    starship_cache = vim.fn
      .system([[
      STARSHIP_SHELL="sh" starship prompt |
        head -n1 |
        sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g'
    ]])
      :gsub('%s*\n$', '')
      :gsub('^%[.-%] ', '')
    return starship_cache
  end,
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
          a = { fg = c.base3, bg = c.base01, gui = 'none' },
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
      lualine_x = { s.starship },
      lualine_y = { s.fileinfo, s.location },
      lualine_z = { s.actions, s.diagnostics },
    },
    winbar = {
      lualine_a = { s.fugitive },
      lualine_c = { s.navic },
      lualine_x = { s.dadbod },
      lualine_y = { s.diff_mode },
      lualine_z = {},
    },
    inactive_winbar = {
      lualine_a = { s.fugitive_inactive },
      lualine_b = {},
      lualine_c = {},
      lualine_x = { s.dadbod },
      lualine_y = { s.diff_mode_inactive },
      lualine_z = {},
    },
    tabline = {
      lualine_a = { { 'tabs', max_length = vim.o.columns } },
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

local augroup = vim.api.nvim_create_augroup('x_lualine', { clear = true })
vim.api.nvim_create_autocmd('BufLeave', {
  group = augroup,
  callback = function()
    starship_cache = nil
  end,
})

return { config = config }
