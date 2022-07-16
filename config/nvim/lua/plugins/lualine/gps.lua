local has_gps, gps = pcall(require, 'nvim-gps')
return function()
  if has_gps and gps.is_available() then
    return gps.get_location()
  end

  return ''
  -- return fn['nvim_treesitter#statusline']()
end
