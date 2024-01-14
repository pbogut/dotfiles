local map = {
  ['NORMAL'] = 'NRM',
  ['INSERT'] = 'INS',
  ['VISUAL'] = 'VIS',
  ['V-BLOCK'] = 'V-B',
  ['V-LINE'] = 'V-L',
  ['SELECT'] = 'SEL',
  ['COMMAND'] = 'CMD',
  ['TERMINAL'] = 'TRM',
}

return function(str)
  if map[str] then
    return map[str]
  else
    return str
  end
end
