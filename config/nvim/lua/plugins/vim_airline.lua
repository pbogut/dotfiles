local has_lspstatus, lspstatus = pcall(require, 'lsp-status')

local g = vim.g
local b = vim.b
local api = vim.api
local fn = vim.fn
local section_y = {}
local section_warning = {}
local section_error = {}

_G.airline = _G.airline or {}

g.airline_powerline_fonts = 1
g['airline#extensions#tabline#enabled'] = 1

-- dadbod info
fn['airline#parts#define_function']('db_selected', 'v:lua.airline.db_selected')
fn['airline#parts#define_condition']('db_selected', '!empty(get(b:, "db"))')
fn['airline#parts#define_function']('db_prod_selected', 'v:lua.airline.db_prod_selected')
fn['airline#parts#define_condition']('db_prod_selected', '!empty(get(b:, "db_selected")) && b:db_selected =~ "_prod$"')

if has_lspstatus then
  g['airline#extensions#nvimlsp#enabled'] = 0
  fn['airline#parts#define_function']('lsp_status_function', 'v:lua.airline.status_function')
  fn['airline#parts#define_condition']('lsp_status_function', '!empty(get(b:, "lsp_current_function", 0))')
  fn['airline#parts#define_function']('lsp_status_warning', 'v:lua.airline.status_warning')
  fn['airline#parts#define_condition']('lsp_status_warning', 'luaeval("#vim.lsp.buf_get_clients() > 0")')
  fn['airline#parts#define_function']('lsp_status_error', 'v:lua.airline.status_error')
  fn['airline#parts#define_condition']('lsp_status_error', 'luaeval("#vim.lsp.buf_get_clients() > 0")')
end

table.insert(section_y, 'db_selected')
table.insert(section_warning, 'db_prod_selected')
if has_lspstatus then
  table.insert(section_y, 'lsp_status_function')
  table.insert(section_warning, 'lsp_status_warning')
  table.insert(section_error, 'lsp_status_error')
end
table.insert(section_y, 'ffenc')

local function get_selected_db()
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

function _G.airline.db_selected()
  return " " .. get_selected_db()
end

function _G.airline.db_prod_selected()
  return " prod"
end

if has_lspstatus then
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

g.airline_section_y = fn['airline#section#create_right'](section_y)
g.airline_section_warning = fn['airline#section#create_right'](section_warning)
g.airline_section_error = fn['airline#section#create_right'](section_error)
