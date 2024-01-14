return function()
  if not lazy_loaded.ripgrep then
    return ''
  end

  local has_ripgrep, ripgrep = pcall(require, 'ripgrep')
  if not has_ripgrep then
    return ''
  end

  return ripgrep.statusline()
end
