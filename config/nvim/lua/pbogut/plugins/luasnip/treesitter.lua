local ls = require('luasnip')
local get_node_text = vim.treesitter.get_node_text

local function to_t(list)
  local result = {}
  for _, text in pairs(list) do
    result[#result + 1] = ls.t(text)
  end

  return result
end

local function to_i(list)
  local result = {}
  for _, text in pairs(list) do
    result[#result + 1] = ls.i(nil, text)
  end

  return result
end

local function get_nodes(language, query)
  local nodes = vim.treesitter.query.parse(language, query)
  local parser = vim.treesitter.get_parser(0, language)
  local root = parser:parse()[1]:root()

  local results = {}
  for _, node, _ in nodes:iter_captures(root) do
    results[#results + 1] = node
  end

  return results
end

local function get_variables()
  local nodes = get_nodes(
    'php',
    [[
      ( variable_name ) @capture1
    ]]
  )

  local results = {}
  for _, node in ipairs(nodes) do
    results[get_node_text(node, 0)] = get_node_text(node, 0)
  end

  return to_i(results)
end

local function get_classes()
  local nodes = get_nodes(
    'php',
    [[
      (namespace_use_declaration
        (namespace_use_clause (name)) @capture6)
      (qualified_name ) @capture4
      (class_declaration name: (name) @capture9)
    ]]
  )

  local results = {}
  for _, node in ipairs(nodes) do
    if node:next_sibling() and node:next_sibling():type() == 'namespace_aliasing_clause' then
      results[get_node_text(node, 0)] = get_node_text(node:next_sibling():child(1), 0)
    elseif node:type() == 'namespace_use_clause' then
      results[get_node_text(node, 0)] = get_node_text(node, 0)
    elseif node:parent() and node:parent():type() == 'namespace_use_clause' then
      results[get_node_text(node, 0)] = get_node_text(node:child(1), 0)
    else
      results[get_node_text(node, 0)] = get_node_text(node, 0)
    end
  end

  return to_t(results)
end

return {
  php = {
    get_classes = get_classes,
    get_variables = get_variables,
  },
}
