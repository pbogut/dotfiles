local u = require('utils')

local function setup()
  u.map('n', '<space>lg', ':Neogit<cr>')
end

local function config()
  local neogit = require('neogit')
  local cmd = vim.cmd
  local fn = vim.fn
  local my = {}
  neogit.setup({
    signs = {
      -- { CLOSED, OPENED }
      section = { "+", "-" },
      item = { " ", " " },
      hunk = { "", "" },
    },
    mappings = {
      status = {
      }
    }
  })

  u.augroup('x_neogit', {
    BufEnter = {'NeogitStatus', function()
      neogit.dispatch_refresh()
    end},
    FileType = {'NeogitStatus', function()
      my.neogit_syntax()
      my.neogit_mappings()
    end}
  })

  u.command('Gst', function()
    cmd('Neogit kind=vsplit')
    cmd('wincmd H')
  end)

  u.command('Grevert', function()
      cmd('Gread')
      cmd('noautocmd w')
      if fn.exists(':SignifyRefresh') then
          cmd('SignifyRefresh')
      end
  end)

  function my.neogit_syntax()
    local sections = {
      MyNeogitModified = {pattern = "^Modified", color = "DiffChange"},
      MyNeogitAdded = {pattern = "^Added", color = "DiffAdd"},
      MyNeogitDeleted = {pattern = "^Deleted", color = "DiffDelete"},
    }

    for id, section in pairs(sections) do
      vim.cmd('syn match ' .. id .. ' /' .. section.pattern .. '/ contained')
      vim.cmd('syn region ' .. id .. 'Region start=/' .. section.pattern .. [[\ze.*/ end=/$/ contains=]] .. id)
      vim.cmd('hi def link ' .. id .. ' ' .. section.color)
    end

    local section_names = table.concat(u.table_keys(sections), ',')
    local regions = {
      MyNeogitUnstaged = {pattern = "^Unstaged changes", color = "vimCommand", title_color = "Function"},
      MyNeogitStaged = {pattern = "^Staged changes", color = "gitcommitSelectedType ", title_color = "Function"},
      MyNeogitUntracked = {pattern = "^Untracked files", color = "gitcommitDiscardedType ", title_color = "Function"},
    }

    for id, region in pairs(regions) do
      vim.cmd('syn match ' .. id .. ' /' .. region.pattern .. '/ contained')
      vim.cmd('syn region ' .. id .. 'Region start=/' .. region.pattern .. [[\ze.*/ end=/\n\n/ contains=]] .. id .. ',' .. section_names)
      vim.cmd('hi def link ' .. id .. ' ' .. region.title_color)
      vim.cmd('hi def link ' .. id .. 'Region ' .. region.color)
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
    u.buf_map(0, 'n', 'R', function()
      cmd('silent !git reset ' .. file_name())
      neogit.dispatch_refresh()
    end)
    u.buf_map(0, 'n', 'au', function()
      cmd('silent !git update-index --assume-unchanged ' .. file_name())
    end)
    u.buf_map(0, 'n', 'an', function()
      cmd('silent !git add -N ' .. file_name())
      neogit.dispatch_refresh()
    end)
    u.buf_map(0, 'n', 'ap', function()
      local name = file_name() -- get file name before tab open
      cmd('tabnew')
      cmd('silent !git add -N ' .. name)
      fn.termopen('git add -p ' .. name)
      cmd('startinsert')
    end)
  end
end

return {
  config = config,
  setup = setup,
}
