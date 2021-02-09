local u = require('utils')
local lspstatus = require('lsp-status')
local gl = require('galaxyline')
local gls = gl.section
local fn = vim.fn
local api = vim.api
local b = vim.b
-- gl.short_line_list = {'NvimTree','vista','dbui'}

local colors = {
    base03 = '#002b36',
    base02 = '#073642',
    base01 = '#586e75',
    base00 = '#657b83',
    base0 = '#839496',
    base1 = '#93a1a1',
    base2 = '#eee8d5',
    base3 = '#fdf6e3',
    yellow = '#b58900',
    orange = '#cb4b16',
    red = '#dc322f',
    magenta = '#d33682',
    violet = '#6c71c4',
    blue = '#268bd2',
    cyan = '#2aa198',
    green = '#859900',
}

local left = {}
local right = {}


local function get_selected_db()
  if not b.db then
    return ''
  end
  local db_selected = (b.db_selected or '')
  if db_selected ~= '' then
    return db_selected
  end

  local candidates = fn['db#url_complete']('g:')
  local valid_url, parts = pcall(fn['db#url#parse'], b.db)
  local pattern = b.db
  if valid_url and parts.scheme ~= 'ssh' then
    pattern = fn.join({
        parts.scheme, parts.user, parts.password, parts.path
      }, '.*') .. '$'
  end

  for _, candidate in ipairs(candidates) do
    local url = api.nvim_eval(candidate)
    if url == b.db or url:match(pattern) then
      if (db_selected == '') then
        db_selected = candidate
      else
        db_selected = '!AMBIGUOUS!'
      end
    end
  end

  b.db_selected = db_selected
  return db_selected
end

left[#left+1] = {
  ViMode = {
    provider = function()
      -- auto change color according the vim mode
      local mode_colors = {
        n = {colors.base3, colors.base1},
        i = {colors.base3, colors.yellow},
        v = {colors.base3, colors.magenta},
        s = {colors.base3, colors.magenta},
        r = {colors.base3, colors.red},
        c = {colors.base3, colors.violet},
      }
      local mode_text = {
        n      = 'NORMAL ',
        i      = 'INSERT ',
        v      = 'VISUAL ',
        [''] = 'V-BLOCK',
        V      = 'V-LINE ',
        c      = 'COMMAND',
        t      = ' TERM  ',
        no     = 'NO',
        s      = 'SELECT ',
        S      = 'S',
        [''] = '^S',
        ic     = 'ic',
        R      = 'R',
        Rv     = 'Rv',
        cv     = 'cv',
        ce     = 'ce',
        r      = 'r',
        rm     = 'rm',
        ['r?'] = 'r?',
        ['!']  = '!',
      }
      local mode_color = {
        n = mode_colors.n,
        i = mode_colors.i,
        v= mode_colors.v,
        [''] = mode_colors.v,
        V = mode_colors.v,
        c = mode_colors.c,
        no = mode_colors.n,
        s = mode_colors.s,
        S = mode_colors.s,
        [''] = mode_colors.s,
        ic = mode_colors.i,
        R = mode_colors.r,
        Rv = mode_colors.r,
        cv = mode_colors.c,
        ce = mode_colors.c,
        r = mode_colors.r,
        rm = mode_colors.r,
        ['r?'] = mode_colors.r,
        ['!']  = mode_colors.c,
        t = mode_colors.c,
      }
      u.highlights({
        GalaxyViMode = {
          guifg = mode_color[vim.fn.mode()][1],
          guibg = mode_color[vim.fn.mode()][2],
          gui = 'bold'
        },
        ViModeSeparator = {
          guifg = mode_color[vim.fn.mode()][2],
          guibg = colors.base01
        },
      })
      return ' ' .. mode_text[vim.fn.mode()]
    end,
    separator = ' ',
  },
}


local buffer_not_empty = function()
  if vim.fn.empty(vim.fn.expand('%:t')) ~= 1 then
    return true
  end
  return false
end

left[#left+1] = {
  ClearIfNoGit = {
    provider = function() return '' end,
    condition = function()
      return  require('galaxyline.provider_vcs').check_git_workspace() == false
    end,
    separator_highlight = {colors.base01,colors.base02},
    highlight = {colors.base3, colors.base01, 'NONE'},
    separator = ' ',
  }
}


left[#left+1] = {
  MyDiffStats = {
    provider = function()
      if vim.fn.exists('*sy#repo#get_stats') == 1 then
        local diff_add = vim.fn['sy#repo#get_stats']()[1]
        local diff_mod = vim.fn['sy#repo#get_stats']()[2]
        local diff_rem = vim.fn['sy#repo#get_stats']()[3]
        return '+' .. diff_add .. ' ~' .. diff_mod .. ' -' .. diff_rem
      end
    end,
    condition = require('galaxyline.provider_vcs').check_git_workspace,
    separator = '  ',
    highlight = {colors.base3,colors.base01},
    separator_highlight = {colors.base3,colors.base01},
  }
}

left[#left+1] = {
  GitBranch = {
    provider = 'GitBranch',
    condition = require('galaxyline.provider_vcs').check_git_workspace,
    separator_highlight = {colors.base01,colors.base02},
    highlight = {colors.base3, colors.base01, 'NONE'},
    separator = ' ',
  }
}


left[#left+1] = {
  FileName = {
    provider = 'FileName',
    condition = buffer_not_empty,
    highlight = {colors.base3,colors.base02}
  }
}

right[#right+1] = {
  LspSymbol = {
    provider = function()
      local current_func = b.lsp_current_function or ''
      local result = ''
      if current_func ~= '' then
        result =  " (" .. current_func .. ") "
      end

      return result
    end,
    highlight = {colors.base3,colors.base02},
    separator_highlight = {colors.base01,colors.base02}
  }
}

right[#right+1] = {
  DadbodDb = {
    provider = function()
      local db = get_selected_db()
      local result = ''
      if db ~= '' then
        result = '  (' .. db .. ') '
      end

      local fg = colors.base3
      local gui = 'none'
      if db:match('_prod$') then
        fg = colors.orange
        gui = 'bold'
      end

      u.highlights({
        GalaxyDadbodDb = {
          guifg = fg,
          guibg = colors.base02,
          gui = gui
        },
      })

      return result
    end,
    highlight = {colors.base3,colors.base02},
    separator_highlight = {colors.base01,colors.base02}
  }
}

right[#right+1] = {
  Fenc = {
    provider = function()
      local encode = vim.bo.fenc ~= '' and vim.bo.fenc or vim.o.enc
      local format = vim.bo.fileformat
      local filetype = vim.bo.filetype or ''
      local result = ' ' .. encode .. '[' .. format .. ']'
      if filetype ~= '' then
        result = result .. '[' .. filetype .. ']'
      end
      return result .. ' '
    end,
    separator = '',
    highlight = {colors.base3, colors.base01, 'NONE'},
    separator_highlight = {colors.base01, colors.base02},
  }
}

right[#right+1] = {
  LineInformation = {
    provider = function()
      local current_line = fn.line('.')
      local total_line = fn.line('$')
      local line = fn.line('.')
      local column = fn.col('.')
      local percent = 0
      if current_line ~= 1 then
        percent,_ = math.modf((current_line/total_line)*100)
      end
      return ' '.. percent .. '% :' .. line .. '/' .. total_line .. ' :' .. column .. ' '
    end,
    separator = '',
    separator_highlight = {colors.base1, colors.base01},
    highlight = {colors.base3, colors.base1}
  }
}

right[#right+1] = {
  LspDiag = {
    provider = function()
      local diagnostics = lspstatus.diagnostics()
      local parts = {}
      if diagnostics.hints > 0 then
        table.insert(parts, " " .. diagnostics.hints)
      end
      if diagnostics.info > 0 then
        table.insert(parts, " " .. diagnostics.info)
      end
      if diagnostics.warnings > 0 then
        table.insert(parts, " " .. diagnostics.warnings)
      end
      local suffix = ''
      if #parts > 0 then
        suffix = ' '
      end

      local result = suffix .. fn.join(parts, ' ') .. suffix
      if #parts > 0 and diagnostics.errors > 0 then
        result = result .. ''
      end
      if  diagnostics.errors > 0 then
        result = result .. "  " .. diagnostics.errors .. ' '
      end

      local bg = colors.base01
      if diagnostics.errors > 0 then
        bg = colors.red
      elseif diagnostics.warnings > 0 then
        bg = colors.orange
      elseif #parts > 0 then
        bg = colors.yellow
      else
        bg = colors.green
        result = '  '
      end

      u.highlights({
          GalaxyLspDiag = {
            guifg = colors.base3,
            guibg = bg,
            gui = 'none'
          },
          LspDiagSeparator = {
            guifg = bg,
            guibg = colors.base1
          },
        })

      return result
    end,
    separator = '',
    -- condition = has_warnings,
    highlight = {colors.base3,colors.orange},
    separator_highlight = {colors.orange, colors.base01}
  }
}

gls.left = left
gls.right = right
