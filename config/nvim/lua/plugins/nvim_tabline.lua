local function config()
  local tabline = require('tabline')
  local u = require('utils')
  local c = vim.g.colors

  tabline.setup({
    no_name = '[No Name]',    -- Name for buffers with no name
    modified_icon = '',      -- Icon for showing modified buffer
    close_icon = '',         -- Icon for closing tab with mouse
    separator = "",          -- Separator icon on the left side
    padding = 1,              -- Prefix and suffix space
    color_all_icons = false,  -- Color devicons in active and inactive tabs
    always_show_tabs = true, -- Always show tabline
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

    TabLineEnd                       = {gui = 'none', guibg = c.base02, guifg = c.base01},
    TabLineStart                     = {gui = 'none', guibg = c.base01, guifg = c.base02},
  })

  local cfg = require('tabline.config')
  local utils = require('tabline.utils')
      local sep = function(active, modified, separator)
        separator = separator or cfg.get('separator')
        if modified == 1 then
            return utils.get_item('TabLineModifiedSeparator', separator, active)
        end
        return utils.get_item('TabLineSeparator', separator, active)
      end

      local myline = function()
        local icons = require('tabline.icons')

        local s = ''
        for index = 1, vim.fn.tabpagenr('$') do
            local winnr = vim.fn.tabpagewinnr(index)
            local bufnr = vim.fn.tabpagebuflist(index)[winnr]
            local bufname = vim.fn.bufname(bufnr)
            local bufmodified = vim.fn.getbufvar(bufnr, '&mod')
            local tabname = utils.get_tabname(bufname, index)
            local extension = vim.fn.fnamemodify(bufname, ':e')
            s = s .. '%' .. index .. 'T'

            local active = index == vim.fn.tabpagenr()

            -- stylua: ignore
            local tl = {}
            if index == 1 then
              tl[#tl+1] = sep(active, bufmodified, '█')
            else
              tl[#tl+1] = sep(active, bufmodified)
            end
            -- tl[#tl+1] = icons.get_left_separator(active, bufmodified)                   -- Left separator
            tl[#tl+1] = utils.get_item('TabLinePadding', ' ', active)               -- Padding
            tl[#tl+1] = icons.get_devicon(active, bufname, extension)                  -- DevIcon
            tl[#tl+1] = utils.get_item('TabLine', tabname, active, true)               -- Filename
            tl[#tl+1] = utils.get_item('TabLinePadding', '', active)               -- Padding
            tl[#tl+1] = icons.get_modified_icon('TabLineModified', active, bufmodified) -- Modified icon
            tl[#tl+1] = icons.get_close_icon('TabLineClose', index, bufmodified)        -- Closing icon
            s = s .. table.concat(tl)
        end
        return s
    end

    function _G.my_tabline()
      -- return '%#TabLineStart#%*' .. _G.nvim_tabline() .. '%#TabLineEnd#%*'
      -- return '%#TabLineStart#█%*' .. myline() .. '%#TabLineEnd#%*'
      return myline() .. '%#TabLineEnd#%*'
    end

    vim.opt.tabline = '%!v:lua.my_tabline()'
end

return {
  config = config
}
