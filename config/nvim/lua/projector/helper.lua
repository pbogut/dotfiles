local M = {}

function M.camelcase(text)
  return text:gsub('_(%l)', function(match)
    return match:upper()
  end)
end

function M.capitalize(text)
  text = text:gsub('([^%l%u])(%l)', function(sign, letter)
    return sign .. letter:upper()
  end)
  return text:gsub('^(%l)', function(letter)
    return letter:upper()
  end)
end

function M.snakecase(text)
  return text:gsub('([a-z])([A-Z])', '%1_%2'):lower()
end

return M
