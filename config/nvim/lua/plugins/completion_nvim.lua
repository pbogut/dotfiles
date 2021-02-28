local completion = require('completion')
local has_dadbod, _ = pcall(require, 'vim_dadbod_completion')
local u = require('utils')
local g = vim.g

g.completion_matching_strategy_list = {'exact', 'substring'}
g.completion_menu_length = 20
g.completion_abbr_length = 20

u.map('i', '<c-space>', '<plug>(completion_trigger)', {noremap = false})
u.map('i', '<c-j>', '<plug>(completion_next_source)', {noremap = false})
-- g.completion_auto_change_source = 1
g.completion_enable_snippet = 'UltiSnips'
g.completion_chain_complete_list = {
    {complete_items = {
        'lsp',
        'snippet',
        'path',
        'buffers',
        'ts',
        'tabnine',
        'vim-dadbod-completion',
    }},
    {mode = 'spell'},
}

g.completion_source_priority = {
  lsp = 10,
  ['vim-dadbod-completion'] = 9,
  snippet = 5,
  ts = 7,
  tabnine = 8,
  path = 3,
  buffers = 1,
}

g.completion_customize_lsp_label = {
  Path = '',
  Treesitter = 'ts',
  Buffers  = '',
  Function = '',
  f = '',
  Method = '',
  Constructor = '',
  Variables = 's',
  Variable = '',
  v = '',
  Value = '',
  Property = '',
  Field = '',
  Constant = '',
  UltiSnips = '烈',
  Keyword = '',
  Module = '',
  Class = '',
  Struct = '',
  DB = '',
  Reference = '',
  Folder = '',
  File = '',
  Snippet = '',
  Operator = '',
  Text = '',
  Interfaces = 's',
  Interface = '',
  [' '] = '?',
  [' '] = '!',
}
-- g.completion_items_priority = {
--   Method = 10,
--   Field = 9,
--   Property = 9,
--   Variables = 7,
--   v = 7,
--   Function = 7,
--   Interfaces = 6,
--   Constant = 6,
--   Class = 6,
--   Struct = 6,
--   DB  = 6,
--   Keyword = 5,
--   Value = 5,
--   Treesitter = 4,
--   File  = 2,
--   TabNine  = 1,
--   Buffers  = 0,
-- }

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
