---@type LazyPluginSpec
return {
  'folke/trouble.nvim',
  keys = {
    { '<space>ed', '<plug>(trouble-diagnostic-document)' },
    { '<space>ew', '<plug>(trouble-diagnostic-workspace)' },
    { '<space>lq', '<plug>(trouble-quickfix)' },
    { '<space>ll', '<plug>(trouble-loclist)' },
    { ']q', '<plug>(trouble-next-quickfix)' },
    { '[q', '<plug>(trouble-prev-quickfix)' },
    { ']l', '<plug>(trouble-next-loclist)' },
    { '[l', '<plug>(trouble-prev-loclist)' },
  },
  cmd = { 'Trouble', 'TroubleToggle', 'TroubleClose', 'TroubleRefresh' },
  config = function()
    local trouble = require('trouble')
    local k = vim.keymap

    k.set('n', '<plug>(trouble-diagnostic-document)', '<cmd>TroubleToggle document_diagnostics<cr>')
    k.set('n', '<plug>(trouble-diagnostic-workspace)', '<cmd>TroubleToggle workspace_diagnostics<cr>')
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
        trouble.previous({ skip_groups = true, jump = true })
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
        trouble.previous({ skip_groups = true, jump = true })
      else
        pcall(vim.cmd.lprevious)
      end
    end)
  end,
}
