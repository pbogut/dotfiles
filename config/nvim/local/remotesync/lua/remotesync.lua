local u = require('utils')
local fn = vim.fn
local config = require('config')

local remotes = {}
for _, remote in pairs(config.get('sync.remotes', {})) do
  remotes[remote.name] = remote.uri
end

local function sync(remote)
  if remote and remotes and remotes[remote] then
    local cmd = {'scp', fn.expand('%:.'), remotes[remote] .. '/' .. fn.expand('%:.')}
    fn.jobstart(cmd, {
      on_exit = function()
        print('File synced to ' .. remote .. ' (' .. fn.expand('%:.') .. ')')
      end
    })
  end
end

if config.get('sync.autosync.enabled', false) then
  local remote = config.get('sync.autosync.remote', '')
  local filters = config.get('sync.autosync.filters', {})

  vim.api.nvim_create_autocmd('BufEnter',{
    pattern = filters,
    callback = function()
      vim.cmd('RemoteSync ' .. remote)
    end,
  })
end

local config_group = {
  BufWritePost = {
    {
      '*',
      function()
        local remote = vim.b.sync_remote or ""
        if remote == "" then
          remote = vim.g.sync_remote or ""
        end
        sync(remote)
      end
    },
  },
}

function _G.remotesync_complete()
  local keys = {}
  for k in pairs(remotes) do keys[#keys+1] = k end
  return keys
end

u.augroup('x_remotesync', config_group)
u.command('RemoteSync', function(bang, name)
  if bang then
    vim.g.sync_remote = name
  else
    vim.b.sync_remote = name
  end
end, {complete = 'customlist,v:lua.remotesync_complete', nargs = '?', bang = true, qargs = true})

u.command('RemotePush', function(name)
  local halt = false
  if name:match('prod') then
    halt = 1 ~= fn.confirm('You are about to do some changes, are you sure you know what you are doing?', "Yes\nNo", 'No')
  end
  if not halt then
    vim.defer_fn(function()
      print('Syncing...')
      sync(name)
    end, 1)
  else
    vim.defer_fn(function() print('File push aborted!') end, 1)
    vim.defer_fn(function() print(' ') end, 1000)
  end
end, {complete = 'customlist,v:lua.remotesync_complete', nargs = '?', bang = false, qargs = true})

-- -complete=custom
