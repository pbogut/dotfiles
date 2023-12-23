local has_ripgrep, ripgrep = pcall(require, 'ripgrep')
return function()
  if not has_ripgrep then
    return ''
  end

  return ripgrep.statusline()
end
