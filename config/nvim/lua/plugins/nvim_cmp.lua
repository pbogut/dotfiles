local cmp = require('cmp')
local u = require('utils')

cmp.setup {
  snippet = {
    expand = function(args)
      -- vim.fn["vsnip#anonymous"](args.body)
      require 'snippy'.expand_snippet(args.body)
    end,
  },
  mapping = {
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<cr>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    }),
    ['<C-e>'] = cmp.mapping.close(),
  },
  sources = {
    {name = 'nvim_lsp'},
    {name = 'nvim_lua'},
    {name = 'treesitter'},
    {name = 'vim-dadbod-completion'},
    {name = 'cmp_tabnine'},
    {name = 'snippy'},
    {name = 'ultisnips'},
    {name = 'path'},
    {name = 'tags'},
    {name = 'buffer'},
    {name = 'emoji'},
    {name = 'spell'},
  },
  sorting = {
    priority_weight = 2,
  },
  formatting = {
    format = function(entry, vim_item)
      -- fancy icons and a name of kind
      vim_item.kind = require("lspkind").presets.default[vim_item.kind] .. " " .. vim_item.kind

      -- set a name for each source
      vim_item.menu = ({
        buffer =      "[Buf]",
        nvim_lsp =    "[LSP]",
        nvim_lua =    "[Lua]",
        cmp_tabnine = "[TN]",
        treesitter =  "[TS]",
        snippy =      "[Snippy]",
        path =        "[Path]",
        emoji =       "[Emoji]",
        tags =        "[Tag]",
        spell =       "[Spell]",
        ['vim-dadbod-completion'] = "[DB]",
      })[entry.source.name]
      return vim_item
    end,
  },
}
