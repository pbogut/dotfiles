local cmp = require('cmp')

local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
    return false
  end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

cmp.setup {
  snippet = {
    expand = function(args)
      require 'snippy'.expand_snippet(args.body)
    end,
  },
  mapping = {
    ['<c-space>'] = cmp.mapping.complete(),
    ['<c-y>S'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    }),
    ['<tab>'] = cmp.mapping(function(fallback)

      if vim.fn.pumvisible() == 1 and vim.v.completed_item.word then
        feedkey("<C-y>S", "i")
      elseif require'snippy'.can_expand_or_advance() then
        require'snippy'.expand_or_advance()
      elseif has_words_before() then
        feedkey("<C-y>,", "i")
      else
        fallback()
      end
    end, { "i", "s" }),
  },
  sources = {
    {name = 'nvim_lsp'},
    {name = 'nvim_lua'},
    {name = 'treesitter'},
    {name = 'vim-dadbod-completion'},
    {name = 'cmp_tabnine'},
    {name = 'snippy', keyword_length = 2},
    {name = 'path'},
    {name = 'tags', max_item_count = 15},
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
