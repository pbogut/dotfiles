local ls = require('luasnip')

local function get_classes()
  local uses = vim.treesitter.parse_query(
    'php',
    [[
      (namespace_use_declaration
        (namespace_use_clause (name)) @capture6)
      (qualified_name ) @capture4
      (class_declaration name: (name) @capture9)
    ]]
  )

  local parser = vim.treesitter.get_parser(0, 'php')

  local root = parser:parse()[1]:root()

  local get_text = function(node)
    local start_line, start_col = node:start()
    local end_line, end_col = node:end_()

    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)

    if #lines then
      lines[1] = lines[1]:sub(start_col + 1, end_col)
    else
      lines[1] = lines[1]:sub(start_col + 1)
      lines[#lines] = lines[#lines]:sub(0, end_col)
    end
    return lines[1]
  end

  local results = { ls.t('') }
  for _, node, _ in uses:iter_captures(root) do
    if node:next_sibling() and node:next_sibling():type() == 'namespace_aliasing_clause' then
      results[get_text(node)] = ls.t(get_text(node:next_sibling():child(1)))
    elseif node:type() == 'namespace_use_clause' then
      results[get_text(node)] = ls.t(get_text(node))
    elseif node:parent() and node:parent():type() == 'namespace_use_clause' then
      results[get_text(node)] = ls.t(get_text(node:child(1)))
    else
      results[get_text(node)] = ls.t(get_text(node))
    end
  end
  local res = {}
  for _, snip in pairs(results) do
    res[#res + 1] = snip
  end

  return res
end

return {
  php = {
    get_classes = get_classes,
  },
}
