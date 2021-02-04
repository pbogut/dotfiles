local u = require('utils')
local b = vim.b
local fn = vim.fn
local cmd = vim.cmd
local l = {}

u.map('v', '<space>d', ':lua require"plugins.vim_dadbod".db_with_warning()<cr>')
u.map('v', '<space>D', ':lua require"plugins.vim_dadbod".db_with_warning(true)<cr>')
u.map('n', '<space>d', ':lua require"plugins.vim_dadbod".db_with_warning()<cr>')
u.map('n', '<space>D', ':lua require"plugins.vim_dadbod".db_with_warning(true)<cr>')

function l.db_with_warning(bang)
  local db = b.db or ''
  local db_selected = b.db_selected or ''
  local firstline = fn.line("'<")
  local lastline = fn.line("'>")

  if firstline == 0 then
    cmd([[echo "No query selected"]])
  end

  if db == '' then
    cmd([[echo "No DB selected"]])
    return
  elseif db_selected == '' then
    cmd([[echo "Unknown DB selected, be careful what you are doing."]])
  elseif db_selected:match("_prod$") then
    cmd([[echo "Production DB selected, be careful what you are doing."]])
  end

  local has_change = false
  for _, line in ipairs(fn.getline(firstline, lastline)) do
    local checks = {
      " insert ", "^insert ", " insert$",
      " update ", "^update ", " update$",
      " delete ", "^delete ", " delete$",
      " upsert ", "^upsert ", " upsert$",
      " truncate ", "^truncate ", " truncate$",
      " alter ", "^alter ", " alter$",
      " drop ", "^drop ", " drop$",
    }
    if not line:match("^%s*%-%-") then  -- skip if comment
      for _, pattern in ipairs(checks) do
        if line:match(pattern) then
          has_change = true
        end
      end
    end
  end

  local halt = false -- perform query
  if has_change then
    halt = 1 ~= fn.confirm('You are about to do some changes, are you sure you know what you are doing?',
                           "Yes\nNo", 'No')
    if not halt and db_selected:match("_prod$") then
      halt = 1 ~= fn.confirm('You know this is Production DB right? Are you sure you want to continue?',
                             "Yes\nNo", 'No')
    end
  end

  if not halt then
    fn['db#execute_command']('', bang, firstline, lastline, '')
  end
end

u.augroup('x_dadbod', {
  BufEnter = {
    {'*.dbout', function()
        -- alternate file override for dbout && sql file
        u.buf_map(0, 'n', '<space>ta', function()
          local dbout = vim.fn.expand('%')
          local db = vim.b.db
          vim.cmd('e ' .. vim.b.db_input)
          vim.defer_fn(function()
            u.buf_map(0, 'n', '<space>ta', function()
              vim.cmd('e ' .. dbout)
            end)
            u.buf_map(0, 'n', 'q', '<c-w>q')
            vim.b.db = db
          end, 100)
        end)
      end
    }
  }
})

return l
