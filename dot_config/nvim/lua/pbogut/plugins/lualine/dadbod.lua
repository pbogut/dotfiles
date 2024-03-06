local c = require('pbogut.settings.colors')

local function get_selected_db()
  local b = vim.b
  if not b.db then
    return ''
  end
  local db_selected = (b.db_selected or '')
  if db_selected ~= '' then
    return db_selected
  end

  local candidates = vim.fn['db#url_complete']('g:')
  local valid_url, parts = pcall(vim.fn['db#url#parse'], b.db)
  local pattern = b.db
  if valid_url and parts.scheme ~= 'ssh' then
    pattern = vim.fn.join({
      parts.scheme,
      parts.user,
      parts.password,
      parts.path,
    }, '.*') .. '$'
  end

  for _, candidate in ipairs(candidates) do
    local url = vim.api.nvim_eval(candidate)
    if url == b.db or url:match(pattern) then
      if db_selected == '' then
        db_selected = candidate
      else
        db_selected = '!AMBIGUOUS!'
      end
    end
  end

  b.db_selected = db_selected
  return db_selected
end

return function()
  local db = get_selected_db()
  local result = ''
  if db ~= '' then
    result = '%#sl_dadbod# (' .. db .. ')'
  end

  local fg = c.base3
  local bold = false

  if db:match('_prod$') then
    fg = c.orange
    bold = true
  end

  vim.api.nvim_set_hl(0, 'sl_dadbod', {
    fg = fg,
    bg = c.base02,
    bold = bold,
  })

  return result
end
