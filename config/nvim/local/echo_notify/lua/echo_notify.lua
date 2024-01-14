local echo = {}

local HlError = 'EchoNotifyERROR'
local HlWarn = 'EchoNotifyWARN'
local HlInfo = 'EchoNotifyINFO'
local HlDebug = 'EchoNotifyDEBUG'
local HlTrace = 'EchoNotifyTRACE'

local options = { text = {}, hls = {}, icons = {}, level = 0 }

local suppressed_messages = {}

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
    suppress = {
      message = {},
      title = {},
    },
  })

  options.suppress = opts.suppress

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

local function show_message(message, title, icon, group)
  local msg = title .. ': ' .. message
  local suppress = false

  for _, pattern in ipairs(options.suppress.title or {}) do
    if title:match(pattern) then
      suppress = true
    end
  end
  for _, pattern in ipairs(options.suppress.message or {}) do
    if message:match(pattern) then
      suppress = true
    end
  end

  if suppress then
    if suppressed_messages[msg] then
      suppressed_messages[msg] = suppressed_messages[msg] + 1
    else
      suppressed_messages[msg] = 1
    end
    return
  end

  vim.api.nvim_echo({ { '[' .. title .. ']' .. icon, group }, { ' ' .. tostring(message), nil } }, true, {})
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

  if opts.trim then
    local width = vim.api.nvim_win_get_width(0)
    message = message:sub(1, width - title:len() - icon:len() - 15)
  end

  show_message(message, title, icon, group)
end

vim.api.nvim_create_user_command('NotifySuppressed', function(_)
  vim.print(suppressed_messages)
end, { nargs = 0 })

vim.notify = echo.notify
return echo
