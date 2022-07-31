vim.cmd([[
  " imap <expr> <tab> snippy#can_expand() ? '<plug>(snippy-expand)' : '<tab>'
  imap <expr> <C-j> snippy#can_jump(1) ? '<plug>(snippy-next)' : '<c-j>'
  imap <expr> <C-k> snippy#can_jump(-1) ? '<plug>(snippy-previous)' : '<c-k>'
  smap <expr> <C-j> snippy#can_jump(1) ? '<plug>(snippy-next)' : '<c-j>'
  smap <expr> <C-k> snippy#can_jump(-1) ? '<plug>(snippy-previous)' : '<c-k>'
  xmap <tab> <plug>(snippy-cut-text)
]])

local function scope_fn(myscopes)
  return function(scopes)
    local has_global = false
    local result = {}
    for _, scope in ipairs(myscopes) do
      result[#result + 1] = scope
    end
    for _, scope in ipairs(scopes) do
      if scope ~= '_' then
        result[#result + 1] = scope
      else
        has_global = true
      end
    end
    if has_global then
      result[#result + 1] = '_'
    end

    return result
  end
end

local function config()
  local snippy = require('snippy')
  local projector = require('projector')

  local scopes = projector.get_config('snippy.scopes', {})
  local fn_scopes = {}

  for lang, scopes_ in pairs(scopes) do
    fn_scopes[lang] = scope_fn(scopes_)
  end

  snippy.setup({
    scopes = fn_scopes,
  })
end

return {
  config = config,
}
