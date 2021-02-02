local has_lspstatus, lspstatus = pcall(require, 'lsp-status')

local g = vim.g
local b = vim.b
local fn = vim.fn

g.airline_powerline_fonts = 1
g['airline#extensions#tabline#enabled'] = 1

if has_lspstatus then
  g['airline#extensions#nvimlsp#enabled'] = 0
  fn['airline#parts#define_function']('lsp_status_function', 'v:lua.airline.status_function')
  fn['airline#parts#define_function']('lsp_status_warning', 'v:lua.airline.status_warning')
  fn['airline#parts#define_function']('lsp_status_error', 'v:lua.airline.status_error')
  fn['airline#parts#define_condition']('lsp_status_function', '!empty(get(b:, "lsp_current_function", 0))')
  fn['airline#parts#define_condition']('lsp_status_warning', 'luaeval("#vim.lsp.buf_get_clients() > 0")')
  fn['airline#parts#define_condition']('lsp_status_error', 'luaeval("#vim.lsp.buf_get_clients() > 0")')
  g.airline_section_y = fn['airline#section#create_right']({'lsp_status_function', 'ffenc'})
  g.airline_section_warning = fn['airline#section#create_right']({'lsp_status_warning'})
  g.airline_section_error = fn['airline#section#create_right']({'lsp_status_error'})

  _G.airline = _G.airline or {}

  function _G.airline.status_function()
    local current_func = b.lsp_current_function or ''
    if current_func ~= '' then
      return " (" .. current_func .. ")"
    end

    return ''
  end

  function _G.airline.status_warning()
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

    return fn.join(parts, ' ')
  end

  function _G.airline.status_error()
    local result = ''
    local diagnostics = lspstatus.diagnostics()

    if diagnostics.errors > 0 then
      result = " " .. diagnostics.errors
    end

    return result
  end
end
