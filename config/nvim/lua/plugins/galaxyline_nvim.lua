local u = require('utils')
local gl = require('galaxyline')
local vcs = require('galaxyline.provider_vcs')
local fileinfo = require('galaxyline.provider_fileinfo')
local dap = require('dap')

local gls = gl.section
local fn = vim.fn
local g = vim.g
local api = vim.api
local b = vim.b
local i = g.icon
-- gl.short_line_list = {'NvimTree','vista','dbui'}
-- 
i.separator = {
  -- left = '',
  -- right = '',
  -- mid_right = '',
  -- left = '',
  -- right = '',
  left = '',
  right = '',
  mid_right = '',
  mid_left = '',
}

local colors = {
    base03  = '#002b36',
    base02  = '#073642',
    base01  = '#586e75',
    base00  = '#657b83',
    base0   = '#839496',
    base1   = '#93a1a1',
    base2   = '#eee8d5',
    base3   = '#fdf6e3',
    -- yellow  = '#b58900',
    orange  = '#cb4b16',
    red     = '#dc322f',
    magenta = '#d33682',
    violet  = '#6c71c4',
    blue = '#268bd2',
    cyan    = '#2aa198',
    -- green   = '#859900',
    -- base03  ='#1c1c1c',
    -- base02  ='#262626',
    -- base01  ='#4e4e4e',
    -- base00  ='#585858',
    -- base0   ='#808080',
    -- base1   ='#8a8a8a',
    -- base2   ='#d7d7af',
    -- base3   ='#ffffd7',
    yellow  = '#af8700',
    -- orange  ='#d75f00',
    -- red     ='#d70000',
    -- magenta ='#af005f',
    -- violet  ='#5f5faf',
    -- blue    ='#0087ff',
    -- cyan    ='#00afaf',
    green   = '#5f8700',
}

local left = {}
local right = {}
local short_left = {}
local short_right = {}

local width_gt_150 = function()
  local width = vim.fn.winwidth(0)
  if width > 150 then
    return true
  end
  return false
end

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
        -- n = {colors.base3, colors.base1},
        -- i = {colors.base3, colors.yellow},
        n = {colors.base3, colors.blue},
        i = {colors.base3, colors.green},
        v = {colors.base3, colors.magenta},
        s = {colors.base3, colors.magenta},
        r = {colors.base3, colors.red},
        c = {colors.base3, colors.violet},
      }
      local mode_text = {
        n      = 'NRM',
        i      = 'INS',
        v      = 'VIS',
        [''] = 'V-B',
        V      = 'V-L',
        c      = 'CMD',
        t      = 'TRM',
        no     = 'NO ',
        s      = 'SEL',
        S      = ' S ',
        [''] = '^S ',
        ic     = 'ic ',
        R      = ' R ',
        Rv     = 'Rv ',
        cv     = 'cv ',
        ce     = 'ce ',
        r      = ' r ',
        rm     = 'rm ',
        ['r?'] = 'r? ',
        ['!']  = ' ! ',
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
      return ' ' .. mode_text[vim.fn.mode()] .. ' '
    end,
    separator = i.separator.left,
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
    provider = function() return ' ' end,
    condition = function()
      return vcs.get_git_branch() == nil
    end,
    separator_highlight = {colors.base01,colors.base02},
    highlight = {colors.base01, colors.base02, 'NONE'},
  }
}
short_left[#short_left+1] = left[#left]

left[#left+1] = {
  MyDiffStats = {
    provider = function()
      if vim.fn.exists('*sy#repo#get_stats') == 1 then
        local diff_add = vim.fn['sy#repo#get_stats']()[1]
        local diff_mod = vim.fn['sy#repo#get_stats']()[2]
        local diff_rem = vim.fn['sy#repo#get_stats']()[3]
        if diff_add ~= -1 then
          local s = i.separator.mid_left
          return '+' .. diff_add .. s .. '~' .. diff_mod .. s .. '-' .. diff_rem .. s
        end
      end
    end,
    condition = function()
      return vcs.get_git_branch()
        and width_gt_150()
    end,
    highlight = {colors.base3,colors.base01},
    separator_highlight = {colors.base3,colors.base01},
  }
}

left[#left+1] = {
  GitBranch = {
    provider = function()
      local branch = vcs.get_git_branch() or ''
      return '  ' .. branch:gsub('%s*$', '') .. ' '
    end,
    condition = vcs.get_git_branch,
    separator_highlight = {colors.base01,colors.base02},
    highlight = {colors.base3, colors.base01, 'NONE'},
    separator = i.separator.left,
  }
}
short_left[#short_left+1] = left[#left]

left[#left+1] = {
  DapStart = {
    provider = function()
      if dap.status():len() > 0 then
        return i.separator.right
      end
    end,
    highlight = {colors.orange, colors.base02},
  },
  Dap = {
    provider = function()
      local status = dap.status()
      if status:len() > 0 then
        return '  (' .. status .. ')'
      else
        return ""
      end
    end,
    highlight = {colors.base2,colors.orange},
    separator_highlight = {colors.orange,colors.base02},
  },
  DapStop = {
    provider = function()
      if dap.status():len() > 0 then
        return i.separator.left .. ' '
      end
    end,
    highlight = {colors.orange, colors.base02},
  },
}

left[#left+1] = {
  FileName = {
    provider = function()
      local file = fileinfo.get_current_file_name()
      return ' ' .. file
    end,
    condition = buffer_not_empty,
    highlight = {colors.base3,colors.base02}
  }
}
short_left[#short_left+1] = left[#left]

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
    -- condition = function() return (b.lsp_current_function or '') ~= '' end,
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
short_right[#short_right+1] = right[#right]

right[#right+1] = {
  Fenc = {
    provider = function()
      local encode = vim.bo.fenc ~= '' and vim.bo.fenc or vim.o.enc
      local format = vim.bo.fileformat
      local filetype = vim.bo.filetype or ''
      local result = ''
      if width_gt_150() then
        result = result .. encode .. '[' .. format .. ']'
      end
      if filetype ~= '' then
        result = result .. '[' .. filetype .. ']'
      end
      if result ~= '' then
        return ' ' .. result .. ' '
      end
    end,
    separator = i.separator.right,
    highlight = {colors.base3, colors.base01, 'NONE'},
    separator_highlight = {colors.base01, colors.base02},
  }
}
short_right[#short_right+1] = right[#right]

right[#right+1] = {
  LineInformation = {
    provider = function()
      local current_line = fn.line('.')
      local total_line = fn.line('$')
      local line = fn.line('.')
      local column = fn.col('.')
      local percent = 0
      if current_line ~= 1 then
        percent, _ = math.modf((current_line/total_line)*100)
      end
      if width_gt_150() then
        return ' '.. percent .. '% :' .. line .. '/' .. total_line .. ' :' .. column .. ' '
      else
        return ' ' .. line .. '/' .. total_line .. ' ' .. column .. ' '
      end
    end,
    separator = i.separator.right,
    separator_highlight = {colors.base1, colors.base01},
    highlight = {colors.base3, colors.base1}
  }
}
short_right[#short_right+1] = right[#right]

right[#right+1] = {
  Diagnostics = { -- @todo @fixme @debug
    provider = function()
      local no_lsp = true
      local diagnostics = {
        hints = 0,
        info = 0,
        warnings = 0,
        errors = 0,
      }

      if #vim.lsp.buf_get_clients() > 0 then
        no_lsp = false
        diagnostics = {
          hints = vim.lsp.diagnostic.get_count(0, 'Hint'),
          info = vim.lsp.diagnostic.get_count(0, 'Information'),
          warnings = vim.lsp.diagnostic.get_count(0, 'Warning'),
          errors = vim.lsp.diagnostic.get_count(0, 'Error'),
        }
      end

      local parts = {}
      if diagnostics.hints > 0 then
        table.insert(parts, i.hint .. ' ' .. diagnostics.hints)
      end
      if diagnostics.info > 0 then
        table.insert(parts, i.info .. ' ' .. diagnostics.info)
      end
      if diagnostics.warnings > 0 then
        table.insert(parts, i.warning .. ' ' .. diagnostics.warnings)
      end
      local suffix = ''
      if #parts > 0 then
        suffix = ' '
      end

      local result = suffix .. fn.join(parts, ' ' .. i.separator.mid_right .. ' ') .. suffix
      if #parts > 0 and diagnostics.errors > 0 then
        result = result .. i.separator.mid_right
      end
      if  diagnostics.errors > 0 then
        result = result .. ' ' .. i.error .. ' ' .. diagnostics.errors .. ' '
      end

      local bg = colors.base01
      if diagnostics.errors > 0 then
        bg = colors.red
      elseif diagnostics.warnings > 0 then
        bg = colors.orange
      elseif #parts > 0 then
        bg = colors.yellow
      elseif no_lsp  then
        bg = colors.blue
        result = '  '
      else
        bg = colors.green
        result = '  '
      end

      u.highlights({
          GalaxyDiagnostics = {
            guifg = colors.base3,
            guibg = bg,
            gui = 'none'
          },
          DiagnosticsSeparator = {
            guifg = bg,
            guibg = colors.base1
          },
        })

      return result
    end,
    separator = i.separator.right,
    highlight = {colors.base3,colors.orange},
    separator_highlight = {colors.orange, colors.base01}
  }
}

gls.left = left
gls.right = right
gls.short_line_left = short_left
gls.short_line_right = short_right
