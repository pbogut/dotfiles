-- how about use shortcut to find class / function / variable /property etc in fuction
-- and then put snippet above? like my var / doc_function snippets?
-- could youse treesitter for params as well
---@type LazyPluginSpec
return {
  'danymat/neogen',
  config = true,
  cmd = { 'Neogen' },
  keys = {
    { '<space>dk', '<cmd>Neogen<cr>' },
  },
  -- opts = {
  --   -- this snipets suck ballz, can I use something else?
  --   snippet_engine = 'luasnip',
  -- },
}
