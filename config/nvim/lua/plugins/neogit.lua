local u = require('utils')
local k = vim.keymap

local function config()
  local neogit = require('neogit')
  local cmd = vim.cmd
  local fn = vim.fn
  local my = {}
  neogit.setup({
    signs = {
      -- { CLOSED, OPENED }
      section = { '+', '-' },
      item = { ' ', ' ' },
      hunk = { '', '' },
    },
    mappings = {
      status = {},
    },
  })

  u.augroup('x_neogit', {
    FileType = {
      'NeogitStatus',
      function()
        my.neogit_syntax()
        my.neogit_mappings()
      end,
    },
  })

  u.command('Gst', function()
    cmd.Neogit('kind=vsplit')
    cmd.wincmd('H')
  end)

  function my.neogit_syntax()
    local sections = {
      MyNeogitModified = { pattern = '^Modified', color = 'DiffChange' },
      MyNeogitAdded = { pattern = '^Added', color = 'DiffAdd' },
      MyNeogitDeleted = { pattern = '^Deleted', color = 'DiffDelete' },
    }

    for id, section in pairs(sections) do
      cmd('syn match ' .. id .. ' /' .. section.pattern .. '/ contained')
      cmd('syn region ' .. id .. 'Region start=/' .. section.pattern .. [[\ze.*/ end=/$/ contains=]] .. id)
      cmd('hi def link ' .. id .. ' ' .. section.color)
    end

    local section_names = table.concat(u.table_keys(sections), ',')
    local regions = {
      MyNeogitUnstaged = { pattern = '^Unstaged changes', color = 'vimCommand', title_color = 'Function' },
      MyNeogitStaged = { pattern = '^Staged changes', color = 'gitcommitSelectedType ', title_color = 'Function' },
      MyNeogitUntracked = { pattern = '^Untracked files', color = 'gitcommitDiscardedType ', title_color = 'Function' },
    }

    for id, region in pairs(regions) do
      cmd('syn match ' .. id .. ' /' .. region.pattern .. '/ contained')
      cmd(
        'syn region '
          .. id
          .. 'Region start=/'
          .. region.pattern
          .. [[\ze.*/ end=/\n\n/ contains=]]
          .. id
          .. ','
          .. section_names
      )
      cmd('hi def link ' .. id .. ' ' .. region.title_color)
      cmd('hi def link ' .. id .. 'Region ' .. region.color)
    end
  end

  function my.neogit_mappings()
    local file_name = function()
      local name = fn.getline('.')
      name = name:gsub('^Added ', '')
      name = name:gsub('^Modified ', '')
      name = name:gsub('^Deleted ', '')
      return fn.shellescape(name)
    end
    k.set('n', 'R', function()
      cmd('silent !git reset ' .. file_name())
      neogit.dispatch_refresh()
    end, { buffer = true })
    k.set('n', 'au', function()
      cmd('silent !git update-index --assume-unchanged ' .. file_name())
    end, { buffer = true })
    k.set('n', 'an', function()
      cmd('silent !git add -N ' .. file_name())
      neogit.dispatch_refresh()
    end, { buffer = true })
    k.set('n', 'ap', function()
      local name = file_name() -- get file name before tab open
      cmd.tabnew()
      cmd('silent !git add -N ' .. name)
      fn.termopen('git add -p ' .. name, {
        on_exit = function()
          cmd.wincmd('q')
          vim.defer_fn(neogit.dispatch_refresh, 250)
        end,
      })
      cmd.startinsert()
    end, { buffer = true })
  end
end

return {
  config = config,
}
