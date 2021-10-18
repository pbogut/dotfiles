local function config()
  local tabline = require('tabline')
  local u = require('utils')
  local c = vim.g.colors

  tabline.setup({
    no_name = '[No Name]',    -- Name for buffers with no name
    modified_icon = '',      -- Icon for showing modified buffer
    close_icon = '',         -- Icon for closing tab with mouse
    separator = "▌",          -- Separator icon on the left side
    padding = 1,              -- Prefix and suffix space
    color_all_icons = false,  -- Color devicons in active and inactive tabs
    always_show_tabs = false, -- Always show tabline
    right_separator = false,  -- Show right separator on the last tab
  })

  u.highlights({
    TabLine                          = {gui = 'none', guibg = c.base01, guifg = c.base3},
    TabLineSel                       = {gui = 'bold', guibg = c.base01, guifg = c.base3},
    TabLineFill                      = {gui = 'none', guibg = c.base02},
    TabLineSeparatorActive           = {gui = 'none', guibg = c.base01, guifg = c.green},
    TabLineSeparatorInactive         = {gui = 'none', guibg = c.base01, guifg = c.base1},
    TabLineModifiedSeparatorActive   = {gui = 'none', guibg = c.base01, guifg = c.blue},
    TabLineModifiedSeparatorInactive = {gui = 'none', guibg = c.base01, guifg = c.violet},
    TabLinePaddingActive             = {gui = 'none', guibg = c.base01, guifg = c.base0},
    TabLinePaddingInactive           = {gui = 'none', guibg = c.base01, guifg = c.base0},
    TabLineModifiedActive            = {gui = 'none', guibg = c.base01, guifg = c.base3},
    TabLineModifiedInactive          = {gui = 'none', guibg = c.base01, guifg = c.base0},
    TabLineCloseActive               = {gui = 'none', guibg = c.base01, guifg = c.base3},
    TabLineCloseInactive             = {gui = 'none', guibg = c.base01, guifg = c.base0},
  })
end

return {
  config = config
}
