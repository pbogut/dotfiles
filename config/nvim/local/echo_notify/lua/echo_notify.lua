local echo = {}

local HlError = 'EchoNotifyERROR'
local HlWarn = 'EchoNotifyWARN'
local HlInfo = 'EchoNotifyINFO'
local HlDebug = 'EchoNotifyDEBUG'
local HlTrace = 'EchoNotifyTRACE'

local options = {text = {}, hls = {}, icons = {}, level = 0}

echo.setup = function(opts)
  opts = vim.tbl_extend('keep', opts, {
    icons = {
      DEBUG = '',
      ERROR = '',
      INFO = '',
      TRACE = '✎',
      WARN = '',
    },
    level = 2,
  })

  options.icons[vim.log.levels.ERROR] = opts.icons.ERROR
  options.icons[vim.log.levels.DEBUG] = opts.icons.DEBUG
  options.icons[vim.log.levels.INFO] = opts.icons.INFO
  options.icons[vim.log.levels.WARN] = opts.icons.WARN
  options.icons[vim.log.levels.TRACE] = opts.icons.TRACE

  options.hls[vim.log.levels.ERROR] = HlError
  options.hls[vim.log.levels.DEBUG] = HlDebug
  options.hls[vim.log.levels.INFO] = HlInfo
  options.hls[vim.log.levels.WARN] = HlWarn
  options.hls[vim.log.levels.TRACE] = HlTrace

  options.text[vim.log.levels.ERROR] = 'Error'
  options.text[vim.log.levels.DEBUG] = 'Debug'
  options.text[vim.log.levels.INFO] = 'Info'
  options.text[vim.log.levels.WARN] = 'Warn'
  options.text[vim.log.levels.TRACE] = 'Trace'

  options.level = opts.level

  vim.api.nvim_set_hl(0, HlError, { fg = '#f70067' })
  vim.api.nvim_set_hl(0, HlWarn, { fg = '#f79000' })
  vim.api.nvim_set_hl(0, HlInfo, { fg = '#a9ff68' })
  vim.api.nvim_set_hl(0, HlTrace, { fg = '#8b8b8b' })
  vim.api.nvim_set_hl(0, HlDebug, { fg = '#d484ff' })
end

echo.notify = function(message, level, opts)
  level = level or vim.log.levels.INFO
  opts = opts or {}
  if level < options.level then
    return
  end
  local icon = options.icons[level]
  if icon then
    icon = ' ' .. icon
  else
    icon = ''
  end
  local title = opts.title or options.text[level] or 'Msg'
  local group = options.hls[level] or HlInfo

  vim.api.nvim_echo({ { '[' .. title .. ']' .. icon, group }, { ' ' .. tostring(message), nil } }, true, {})
end

vim.notify = echo.notify
return echo
