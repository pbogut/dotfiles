---@type LazyPluginSpec
return {
  enabled = true,
  'folke/trouble.nvim',
  keys = {
    { '<space>ee', '<plug>(trouble-diagnostic)' },
    { ']q', '<plug>(trouble-next-quickfix)' },
    { '[q', '<plug>(trouble-prev-quickfix)' },
    { ']l', '<plug>(trouble-next-loclist)' },
    { '[l', '<plug>(trouble-prev-loclist)' },
  },
  cmd = { 'Trouble', 'TroubleToggle', 'TroubleClose', 'TroubleRefresh' },
  config = function()
    local trouble = require('trouble')
    local k = vim.keymap

    trouble.setup()

    k.set('n', '<plug>(trouble-diagnostic)', '<cmd>TroubleToggle document<cr>')
    k.set('n', '<plug>(trouble-quickfix)', '<cmd>TroubleToggle quickfix<cr>')
    k.set('n', '<plug>(trouble-loclist)', '<cmd>TroubleToggle loclist<cr>')

    k.set('n', '<plug>(trouble-next-quickfix)', function()
      if trouble.is_open() then
        trouble.next({ skip_groups = true, jump = true })
      else
        pcall(vim.cmd.cnext)
      end
    end)

    k.set('n', '<plug>(trouble-prev-quickfix)', function()
      if trouble.is_open() then
        trouble.prev({ skip_groups = true, jump = true })
      else
        pcall(vim.cmd.cprevious)
      end
    end)

    k.set('n', '<plug>(trouble-next-loclist)', function()
      if trouble.is_open() then
        trouble.next({ skip_groups = true, jump = true })
      else
        pcall(vim.cmd.lnext)
      end
    end)

    k.set('n', '<plug>(trouble-prev-loclist)', function()
      if trouble.is_open() then
        trouble.prev({ skip_groups = true, jump = true })
      else
        pcall(vim.cmd.lprevious)
      end
    end)
  end,
}
