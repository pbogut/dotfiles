local completion = require('completion')
local has_dadbod, _ = pcall(require, 'vim_dadbod_completion')
local u = require('utils')
local g = vim.g

g.completion_matching_strategy_list = {'exact', 'substring'}

-- g.completion_auto_change_source = 1
g.completion_enable_snippet = 'UltiSnips'
g.completion_chain_complete_list = {
  {complete_items = {'lsp', 'snippet','buffers', 'vim-dadbod-completion'}},
  -- {complete_items = {'buffers'}},
  {mode = '<c-p>'},
  {mode = '<c-n>'},
}

g.completion_items_priority = {
  Method = 10,
  Field = 9,
  Property = 9,
  Variables = 7,
  Function = 7,
  Interfaces = 6,
  Constant = 6,
  Class = 6,
  Struct = 6,
  DB  = 6,
  Keyword = 5,
  Value = 5,
  Treesitter = 4,
  File  = 2,
  TabNine  = 1,
  Buffers  = 0,
}

if has_dadbod then
  u.augroup("x_competion_nvim", {
    FileType = {"sql", function()
      completion.on_attach()
      vim.api.nvim_buf_set_option(0, 'omnifunc', 'vim_dadbod_completion#omni')
      g.completion_trigger_character = {'.', '"', '`', '['}
    end}
  })
end

-- u.map('i', '<m-tab>', '<Plug>(completion_next_source)', { noremap = false })
-- u.map('i', '<c-tab>', '<Plug>(completion_next_source)', { noremap = false })
-- u.map('i', '<s-tab>', '<Plug>(completion_prev_source)', { noremap = false })
