local i = require('pbogut.settings.icons')
local c = require('pbogut.settings.colors')

return function()
  local no_lsp = true
  local diagnostics = {
    hints = 0,
    info = 0,
    warnings = 0,
    errors = 0,
  }

  if #vim.lsp.get_active_clients() > 0 then
    no_lsp = false
    diagnostics = {
      hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT }),
      info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO }),
      warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN }),
      errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR }),
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
  if diagnostics.errors > 0 then
    table.insert(parts, i.error .. ' ' .. diagnostics.errors)
  end

  local result = vim.fn.join(parts, '  ')

  local bg = c.base01
  if diagnostics.errors > 0 then
    bg = c.red
  elseif diagnostics.warnings > 0 then
    bg = c.orange
  elseif #parts > 0 then
    bg = c.yellow
  elseif no_lsp then
    bg = c.blue
    result = ''
  else
    bg = c.green
    result = ''
  end

  vim.api.nvim_set_hl(0, 'sl_diagnostics', {
    fg = c.base3,
    bg = bg,
    bold = false,
  })
  vim.api.nvim_set_hl(0, 'lualine_transitional_sl_diagnostics_to_lualine_b_normal', {
    fg = bg,
    bg = c.base01,
  })

  return '%#sl_diagnostics#' .. result
end
