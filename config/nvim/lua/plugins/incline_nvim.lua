local u = require('utils')
local g = vim.g

local has_icons, devicons = pcall(require, 'nvim-web-devicons')

local filename = function(props)
  local bufname = vim.api.nvim_buf_get_name(props.buf)
  local name = bufname ~= '' and vim.fn.fnamemodify(bufname, ':t') or '[No Name]'
  local icon = ''
  local modified = ''
  if has_icons then
    local f_name, f_extension = vim.fn.expand('%:t'), vim.fn.expand('%:e')
    f_extension = f_extension ~= '' and f_extension or vim.bo.filetype
    local f_icon, _ = devicons.get_icon(f_name, f_extension)
    icon = f_icon .. ' '
  end

  if vim.o.modified then
    modified = ' '
  end

  return ' ' .. icon .. name .. modified .. ' '
end

require('incline').setup {
  debounce_threshold = {
    falling = 50,
    rising = 10
  },
  hide = {
    cursorline = false,
    focused_win = false,
    only_win = false
  },
  ignore = {
    buftypes = "special",
    filetypes = {},
    floating_wins = true,
    unlisted_buffers = true,
    wintypes = "special"
  },
  render = function(props)
    local sep_fg = vim.g.colors.base01
    local sep_bg = vim.g.colors.base03
    local fn_fg = vim.g.colors.base3
    local fn_bg = vim.g.colors.base01
    local gui = 'none'

    if props.focused == true then
      sep_fg = vim.g.colors.blue
      sep_bg = vim.g.colors.base03
      fn_fg = vim.g.colors.base2
      fn_bg = vim.g.colors.blue
      gui = 'bold'
    end

    -- if props.focused == true and vim.bo.ft ~= 'lua' then
    --   fg = vim.g.colors.red
    --   bg = vim.g.colors.orange
    -- end

    return {
      { '', guifg = sep_fg, guibg = sep_bg },
      { filename(props), guifg = fn_fg, guibg = fn_bg, gui = gui },
    }
  end,
  window = {
    margin = {
      horizontal = 0,
      vertical = 0
    },
    options = {
      signcolumn = "no",
      wrap = false
    },
    padding = 0,
    padding_char = " ",
    placement = {
      horizontal = "right",
      vertical = "top"
    },
    width = "fit",
    winhighlight = {
      active = {
        EndOfBuffer = "None",
        Normal = "None",
        Search = "None"
      },
      inactive = {
        EndOfBuffer = "None",
        Normal = "None",
        Search = "None"
      }
    },
    zindex = 50
  }
}
